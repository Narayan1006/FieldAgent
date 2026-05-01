import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'patient_type.dart';

class Visit {
  final String id;
  final String patientId;
  final String visitDate;
  final PatientType visitType;

  // Maternal / vitals
  int? bpSystolic;
  int? bpDiastolic;
  double? weight;
  double? temperature;

  // Universal
  List<String> symptoms;
  String notes;
  List<String> dangerFlags;
  String referralNote;
  bool approved;

  // Type-specific readings (JSON blob)
  Map<String, dynamic> visitData;

  final String createdAt;
  String syncStatus;

  Visit({
    String? id,
    required this.patientId,
    String? visitDate,
    this.visitType = PatientType.maternal,
    this.bpSystolic,
    this.bpDiastolic,
    this.weight,
    this.temperature,
    List<String>? symptoms,
    this.notes = '',
    List<String>? dangerFlags,
    this.referralNote = '',
    this.approved = false,
    Map<String, dynamic>? visitData,
    String? createdAt,
    this.syncStatus = 'pending',
  })  : id = id ?? const Uuid().v4(),
        visitDate = visitDate ?? DateTime.now().toIso8601String().split('T').first,
        symptoms = symptoms ?? [],
        dangerFlags = dangerFlags ?? [],
        visitData = visitData ?? {},
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  // ── SQLite ────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'id': id,
        'patient_id': patientId,
        'visit_date': visitDate,
        'visit_type': visitType.key,
        'bp_systolic': bpSystolic,
        'bp_diastolic': bpDiastolic,
        'weight': weight,
        'temperature': temperature,
        'symptoms': symptoms.join(','),
        'notes': notes,
        'danger_flags': dangerFlags.join('|'),
        'referral_note': referralNote,
        'approved': approved ? 1 : 0,
        'visit_data': jsonEncode(visitData),
        'created_at': createdAt,
        'sync_status': syncStatus,
      };

  factory Visit.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> vd = {};
    try {
      final raw = map['visit_data'] as String?;
      if (raw != null && raw.isNotEmpty) vd = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {}
    return Visit(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      visitDate: map['visit_date'] as String,
      visitType: PatientTypeX.fromKey(map['visit_type'] as String? ?? 'maternal'),
      bpSystolic: map['bp_systolic'] as int?,
      bpDiastolic: map['bp_diastolic'] as int?,
      weight: map['weight'] as double?,
      temperature: map['temperature'] as double?,
      symptoms: (map['symptoms'] as String? ?? '').isEmpty
          ? []
          : (map['symptoms'] as String).split(','),
      notes: map['notes'] as String? ?? '',
      dangerFlags: (map['danger_flags'] as String? ?? '').isEmpty
          ? []
          : (map['danger_flags'] as String).split('|'),
      referralNote: map['referral_note'] as String? ?? '',
      approved: (map['approved'] as int? ?? 0) == 1,
      visitData: vd,
      createdAt: map['created_at'] as String,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }

  // ── Firestore ─────────────────────────────────────────────────
  Map<String, dynamic> toFirestore() => {
        'id': id,
        'patient_id': patientId,
        'visit_date': visitDate,
        'visit_type': visitType.key,
        'bp_systolic': bpSystolic,
        'bp_diastolic': bpDiastolic,
        'weight': weight,
        'temperature': temperature,
        'symptoms': symptoms,
        'notes': notes,
        'danger_flags': dangerFlags,
        'referral_note': referralNote,
        'approved': approved,
        'visit_data': visitData,
        'created_at': createdAt,
      };

  Visit copyWith({
    PatientType? visitType,
    int? bpSystolic,
    int? bpDiastolic,
    double? weight,
    double? temperature,
    List<String>? symptoms,
    String? notes,
    List<String>? dangerFlags,
    String? referralNote,
    bool? approved,
    Map<String, dynamic>? visitData,
    String? syncStatus,
  }) =>
      Visit(
        id: id,
        patientId: patientId,
        visitDate: visitDate,
        visitType: visitType ?? this.visitType,
        bpSystolic: bpSystolic ?? this.bpSystolic,
        bpDiastolic: bpDiastolic ?? this.bpDiastolic,
        weight: weight ?? this.weight,
        temperature: temperature ?? this.temperature,
        symptoms: symptoms ?? this.symptoms,
        notes: notes ?? this.notes,
        dangerFlags: dangerFlags ?? this.dangerFlags,
        referralNote: referralNote ?? this.referralNote,
        approved: approved ?? this.approved,
        visitData: visitData ?? this.visitData,
        createdAt: createdAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
}
