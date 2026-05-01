import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'patient_type.dart';

class Patient {
  final String id;
  final String name;
  final int age;
  final String village;
  final PatientType patientType;

  // Maternal-specific (kept as named fields for backward compat)
  final String ancNumber;
  final String lmpDate;
  final String edd;

  // Flexible extra fields for all types (JSON map)
  final Map<String, dynamic> extraData;

  final String createdAt;
  final String syncStatus; // 'pending' | 'synced'

  Patient({
    String? id,
    required this.name,
    required this.age,
    required this.village,
    this.patientType = PatientType.maternal,
    this.ancNumber = '',
    this.lmpDate = '',
    this.edd = '',
    Map<String, dynamic>? extraData,
    String? createdAt,
    this.syncStatus = 'pending',
  })  : id = id ?? const Uuid().v4(),
        extraData = extraData ?? {},
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  // ── SQLite ────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'age': age,
        'village': village,
        'patient_type': patientType.key,
        'anc_number': ancNumber,
        'lmp_date': lmpDate,
        'edd': edd,
        'extra_data': jsonEncode(extraData),
        'created_at': createdAt,
        'sync_status': syncStatus,
      };

  factory Patient.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> extra = {};
    try {
      final raw = map['extra_data'] as String?;
      if (raw != null && raw.isNotEmpty) extra = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {}
    return Patient(
      id: map['id'] as String,
      name: map['name'] as String,
      age: map['age'] as int,
      village: map['village'] as String,
      patientType: PatientTypeX.fromKey(map['patient_type'] as String? ?? 'maternal'),
      ancNumber: map['anc_number'] as String? ?? '',
      lmpDate: map['lmp_date'] as String? ?? '',
      edd: map['edd'] as String? ?? '',
      extraData: extra,
      createdAt: map['created_at'] as String,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }

  // ── Firestore ─────────────────────────────────────────────────
  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'age': age,
        'village': village,
        'patient_type': patientType.key,
        'anc_number': ancNumber,
        'lmp_date': lmpDate,
        'edd': edd,
        'extra_data': extraData,
        'created_at': createdAt,
      };

  factory Patient.fromFirestore(Map<String, dynamic> map) {
    Map<String, dynamic> extra = {};
    try {
      final raw = map['extra_data'];
      if (raw is Map) extra = Map<String, dynamic>.from(raw);
    } catch (_) {}
    return Patient(
      id: map['id'] as String,
      name: map['name'] as String,
      age: (map['age'] as num).toInt(),
      village: map['village'] as String,
      patientType: PatientTypeX.fromKey(map['patient_type'] as String? ?? 'maternal'),
      ancNumber: map['anc_number'] as String? ?? '',
      lmpDate: map['lmp_date'] as String? ?? '',
      edd: map['edd'] as String? ?? '',
      extraData: extra,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      syncStatus: 'synced',
    );
  }

  Patient copyWith({
    String? name,
    int? age,
    String? village,
    PatientType? patientType,
    String? ancNumber,
    String? lmpDate,
    String? edd,
    Map<String, dynamic>? extraData,
    String? syncStatus,
  }) =>
      Patient(
        id: id,
        name: name ?? this.name,
        age: age ?? this.age,
        village: village ?? this.village,
        patientType: patientType ?? this.patientType,
        ancNumber: ancNumber ?? this.ancNumber,
        lmpDate: lmpDate ?? this.lmpDate,
        edd: edd ?? this.edd,
        extraData: extraData ?? this.extraData,
        createdAt: createdAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
}
