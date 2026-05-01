import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import 'database_service.dart';

/// SyncService — manages all Firestore ↔ SQLite synchronization.
/// SQLite is ALWAYS the source of truth.
/// Firestore is the cloud backup / multi-device sync target.
class SyncService {
  static SyncService? _instance;
  static SyncService get instance {
    _instance ??= SyncService._();
    return _instance!;
  }

  SyncService._();

  final _firestore = FirebaseFirestore.instance;
  final _db = DatabaseService.instance;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // Stream controller so UI can react to sync events
  final _syncStream = StreamController<SyncEvent>.broadcast();
  Stream<SyncEvent> get syncEvents => _syncStream.stream;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  // ── INIT ──────────────────────────────────────────────────────

  /// Call once at app start. Starts connectivity monitoring.
  Future<void> initialize() async {
    final results = await Connectivity().checkConnectivity();
    _isOnline = _hasConnection(results);
    debugPrint('[SyncService] 🚀 Initialized. Online: $_isOnline');

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = _hasConnection(results);
      debugPrint('[SyncService] 📡 Connectivity changed. Online: $_isOnline');

      if (!wasOnline && _isOnline) {
        debugPrint('[SyncService] 🔄 Back online — flushing pending queue');
        _syncStream.add(SyncEvent(type: SyncEventType.reconnected));
        pushPendingQueue();
      }
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
    _syncStream.close();
  }

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  // ── VILLAGE / PATIENT PULL ────────────────────────────────────

  /// Pull all patients for a village from Firestore, upsert to SQLite.
  /// Called on village selection and on pull-to-refresh.
  Future<List<Patient>> pullPatientsForVillage(String village) async {
    debugPrint('[SyncService] ⬇️  Pulling patients for village: $village');
    try {
      final snapshot = await _firestore
          .collection('patients')
          .where('village', isEqualTo: village)
          .get();

      final patients = <Patient>[];
      for (final doc in snapshot.docs) {
        final patient = Patient.fromFirestore(doc.data());
        await _db.insertPatient(patient);
        patients.add(patient);
        debugPrint('[SyncService]   ✅ Patient cached: ${patient.name}');
      }

      debugPrint('[SyncService] ⬇️  Pull complete: ${patients.length} patients for $village');
      _syncStream.add(SyncEvent(
        type: SyncEventType.patientsPulled,
        message: 'Pulled ${patients.length} patients for $village',
      ));
      return patients;
    } catch (e) {
      debugPrint('[SyncService] ❌ Pull failed: $e');
      _syncStream.add(SyncEvent(
        type: SyncEventType.error,
        message: 'Failed to pull patients: $e',
      ));
      return await _db.getPatientsByVillage(village);
    }
  }

  /// Push a patient to Firestore (creates/updates doc)
  Future<void> pushPatient(Patient patient) async {
    if (!_isOnline) return;
    try {
      await _firestore
          .collection('patients')
          .doc(patient.id)
          .set(patient.toFirestore(), SetOptions(merge: true));
      await _db.updatePatientSyncStatus(patient.id, 'synced');
    } catch (_) {
      // Will retry later
    }
  }

  // ── VISIT PUSH ────────────────────────────────────────────────

  /// Push a single approved visit to Firestore.
  /// If offline, marks visit as pending — auto-syncs on reconnect.
  Future<SyncResult> pushVisit(Visit visit, Patient patient) async {
    if (!_isOnline) {
      debugPrint('[SyncService] 📴 Offline — queuing visit: ${visit.id}');
      await _db.updateVisitSyncStatus(visit.id, 'pending');
      return SyncResult.queued;
    }

    debugPrint('[SyncService] ⬆️  Pushing visit: ${visit.id} for ${patient.name}');
    try {
      await _firestore
          .collection('visits')
          .doc(visit.id)
          .set(visit.toFirestore(), SetOptions(merge: true));

      await _db.updateVisitSyncStatus(visit.id, 'synced');
      await pushPatient(patient);

      debugPrint('[SyncService] ✅ Visit synced to Firestore: ${visit.id}');
      _syncStream.add(SyncEvent(
        type: SyncEventType.visitSynced,
        message: 'Visit ${visit.id} synced',
      ));
      return SyncResult.synced;
    } catch (e) {
      debugPrint('[SyncService] ❌ Push failed: $e');
      await _db.updateVisitSyncStatus(visit.id, 'pending');
      _syncStream.add(SyncEvent(
        type: SyncEventType.error,
        message: 'Sync failed: $e',
      ));
      return SyncResult.failed;
    }
  }

  /// Retry all pending approved visits — called on reconnect and manually.
  Future<void> pushPendingQueue() async {
    if (!_isOnline) return;
    debugPrint('[SyncService] 🔄 Flushing pending queue...');
    try {
      final pendingVisits = await _db.getPendingVisits();
      debugPrint('[SyncService]   Found ${pendingVisits.length} pending visit(s)');
      for (final visit in pendingVisits) {
        final patient = await _db.getPatient(visit.patientId);
        if (patient == null) continue;
        await pushVisit(visit, patient);
      }
      if (pendingVisits.isNotEmpty) {
        debugPrint('[SyncService] ✅ Queue flushed: ${pendingVisits.length} visits synced');
        _syncStream.add(SyncEvent(
          type: SyncEventType.queueFlushed,
          message: 'Flushed ${pendingVisits.length} pending visits',
        ));
      } else {
        debugPrint('[SyncService]   No pending visits to sync');
      }
    } catch (e) {
      debugPrint('[SyncService] ❌ Queue flush error: $e');
    }
  }

  // ── VILLAGES LIST ─────────────────────────────────────────────

  /// Fetch list of available villages from Firestore.
  /// Falls back to a hardcoded list if offline/empty.
  Future<List<String>> fetchVillages() async {
    try {
      final snapshot = await _firestore
          .collection('villages')
          .get()
          .timeout(const Duration(seconds: 5));
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((d) => d.data()['name'] as String? ?? d.id)
            .toList()
          ..sort();
      }
    } catch (e) {
      debugPrint('[SyncService] fetchVillages fallback: $e');
    }
    return ['Govindpur', 'Krishnanagar', 'Rampura', 'Sitapur'];
  }
}

enum SyncResult { synced, queued, failed }

enum SyncEventType {
  patientsPulled,
  visitSynced,
  queueFlushed,
  reconnected,
  error,
}

class SyncEvent {
  final SyncEventType type;
  final String message;
  SyncEvent({required this.type, this.message = ''});
}
