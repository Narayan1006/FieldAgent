import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patient.dart';
import '../models/patient_type.dart';
import '../models/visit.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'field_agent.db');
    return await openDatabase(
      path,
      version: 3, // v3: added patient_type, extra_data, visit_type, visit_data, temperature
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ── Schema creation ───────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        village TEXT NOT NULL,
        patient_type TEXT NOT NULL DEFAULT 'maternal',
        anc_number TEXT NOT NULL DEFAULT '',
        lmp_date TEXT NOT NULL DEFAULT '',
        edd TEXT NOT NULL DEFAULT '',
        extra_data TEXT NOT NULL DEFAULT '{}',
        created_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE visits (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        visit_date TEXT NOT NULL,
        visit_type TEXT NOT NULL DEFAULT 'maternal',
        bp_systolic INTEGER,
        bp_diastolic INTEGER,
        weight REAL,
        temperature REAL,
        symptoms TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        danger_flags TEXT DEFAULT '',
        referral_note TEXT DEFAULT '',
        approved INTEGER DEFAULT 0,
        visit_data TEXT NOT NULL DEFAULT '{}',
        created_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (patient_id) REFERENCES patients(id)
      )
    ''');

    await _seedPatients(db);
  }

  // ── Migrations ────────────────────────────────────────────────

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE patients ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pending'");
      await db.execute("ALTER TABLE visits ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pending'");
    }
    if (oldVersion < 3) {
      // Add patient_type support
      await db.execute("ALTER TABLE patients ADD COLUMN patient_type TEXT NOT NULL DEFAULT 'maternal'");
      await db.execute("ALTER TABLE patients ADD COLUMN extra_data TEXT NOT NULL DEFAULT '{}'");
      // Add visit_type and visit_data
      await db.execute("ALTER TABLE visits ADD COLUMN visit_type TEXT NOT NULL DEFAULT 'maternal'");
      await db.execute("ALTER TABLE visits ADD COLUMN visit_data TEXT NOT NULL DEFAULT '{}'");
      await db.execute("ALTER TABLE visits ADD COLUMN temperature REAL");
    }
  }

  // ── Seed data ─────────────────────────────────────────────────

  Future<void> _seedPatients(Database db) async {
    final now = DateTime.now().toIso8601String();

    // ── Maternal patients ──────────────────────────────────────
    final maternalPatients = [
      {'id': 'p001', 'name': 'Sunita Devi',  'age': 24, 'village': 'Rampura',      'patient_type': 'maternal', 'anc_number': 'ANC-2024-001', 'lmp_date': '2024-09-15', 'edd': '2025-06-22'},
      {'id': 'p002', 'name': 'Meena Kumari', 'age': 28, 'village': 'Sitapur',      'patient_type': 'maternal', 'anc_number': 'ANC-2024-002', 'lmp_date': '2024-10-01', 'edd': '2025-07-08'},
      {'id': 'p003', 'name': 'Priya Sharma', 'age': 22, 'village': 'Govindpur',    'patient_type': 'maternal', 'anc_number': 'ANC-2024-003', 'lmp_date': '2024-08-20', 'edd': '2025-05-27'},
      {'id': 'p004', 'name': 'Radha Yadav',  'age': 31, 'village': 'Rampura',      'patient_type': 'maternal', 'anc_number': 'ANC-2024-004', 'lmp_date': '2024-11-10', 'edd': '2025-08-17'},
      {'id': 'p005', 'name': 'Anita Patel',  'age': 26, 'village': 'Krishnanagar', 'patient_type': 'maternal', 'anc_number': 'ANC-2024-005', 'lmp_date': '2024-09-28', 'edd': '2025-07-05'},
    ];

    // ── Child patients ─────────────────────────────────────────
    final childPatients = [
      {'id': 'c001', 'name': 'Ravi Kumar (Child)', 'age': 0, 'village': 'Rampura',   'patient_type': 'child', 'extra_data': '{"dob":"2025-02-01","gender":"Male","guardian":"Sunita Devi","vaccines_given":["BCG","OPV0"],"next_vaccine":"OPV1","next_due":"2025-03-01"}'},
      {'id': 'c002', 'name': 'Sita Devi (Child)',  'age': 1, 'village': 'Sitapur',   'patient_type': 'child', 'extra_data': '{"dob":"2024-04-10","gender":"Female","guardian":"Meena Bai","vaccines_given":["BCG","OPV0","OPV1","DPT1"],"next_vaccine":"DPT2","next_due":"2025-02-10"}'},
    ];

    // ── TB patients ────────────────────────────────────────────
    final tbPatients = [
      {'id': 't001', 'name': 'Ramesh Gupta',  'age': 45, 'village': 'Govindpur',    'patient_type': 'tb', 'extra_data': '{"tb_id":"TB-2024-001","regimen":"Category 1","start_date":"2024-12-01","end_date":"2025-05-31","dots_supporter":"Sunita"}'},
      {'id': 't002', 'name': 'Lakshmi Bai',   'age': 38, 'village': 'Krishnanagar', 'patient_type': 'tb', 'extra_data': '{"tb_id":"TB-2024-002","regimen":"Category 2","start_date":"2025-01-15","end_date":"2025-09-14","dots_supporter":"Anita"}'},
    ];

    // ── Malaria patients ───────────────────────────────────────
    final malariaPatients = [
      {'id': 'm001', 'name': 'Suresh Yadav',  'age': 32, 'village': 'Rampura',      'patient_type': 'malaria', 'extra_data': '{"disease":"Malaria","onset_date":"2025-04-28","rdt_result":"Positive (P.vivax)","treatment":"Chloroquine"}'},
    ];

    // ── Family Planning patients ───────────────────────────────
    final fpPatients = [
      {'id': 'f001', 'name': 'Kavita Singh',  'age': 27, 'village': 'Sitapur',      'patient_type': 'family_planning', 'extra_data': '{"method":"OCP","start_date":"2025-01-01","next_followup":"2025-07-01"}'},
    ];

    // ── Newborn patients ───────────────────────────────────────
    final newbornPatients = [
      {'id': 'n001', 'name': 'Baby of Radha', 'age': 0, 'village': 'Rampura',       'patient_type': 'newborn', 'extra_data': '{"dob":"2025-04-20","birth_weight_kg":2.8,"gender":"Male","mother_name":"Radha Yadav","delivery_type":"Normal"}'},
    ];

    // ── General sick ───────────────────────────────────────────
    final generalPatients = [
      {'id': 'g001', 'name': 'Mohan Lal',     'age': 55, 'village': 'Govindpur',    'patient_type': 'general', 'extra_data': '{"chief_complaint":"Fever and body ache"}'},
    ];

    final allPatients = [
      ...maternalPatients,
      ...childPatients,
      ...tbPatients,
      ...malariaPatients,
      ...fpPatients,
      ...newbornPatients,
      ...generalPatients,
    ];

    for (final p in allPatients) {
      await db.insert('patients', {
        ...p,
        'anc_number': p['anc_number'] ?? '',
        'lmp_date':   p['lmp_date']   ?? '',
        'edd':        p['edd']         ?? '',
        'extra_data': p['extra_data']  ?? '{}',
        'created_at': now,
        'sync_status': 'synced',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Seed one visit for existing maternal patient
    await db.insert('visits', {
      'id': 'v001',
      'patient_id': 'p001',
      'visit_date': '2025-03-15',
      'visit_type': 'maternal',
      'bp_systolic': 120,
      'bp_diastolic': 78,
      'weight': 62.5,
      'temperature': null,
      'symptoms': 'Fatigue,Swelling',
      'notes': 'Patient reports mild ankle swelling since 2 days.',
      'danger_flags': '',
      'referral_note': '',
      'approved': 1,
      'visit_data': '{}',
      'created_at': '2025-03-15T10:30:00',
      'sync_status': 'synced',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // ── PATIENT CRUD ──────────────────────────────────────────────

  Future<List<Patient>> getAllPatients() async {
    final db = await database;
    final maps = await db.query('patients', orderBy: 'name ASC');
    return maps.map(Patient.fromMap).toList();
  }

  Future<List<Patient>> getPatientsByVillage(String village) async {
    final db = await database;
    final maps = await db.query(
      'patients',
      where: 'village = ?',
      whereArgs: [village],
      orderBy: 'name ASC',
    );
    return maps.map(Patient.fromMap).toList();
  }

  Future<List<Patient>> getPatientsByType(PatientType type, {String? village}) async {
    final db = await database;
    String where = 'patient_type = ?';
    List<dynamic> args = [type.key];
    if (village != null && village.isNotEmpty) {
      where += ' AND village = ?';
      args.add(village);
    }
    final maps = await db.query('patients', where: where, whereArgs: args, orderBy: 'name ASC');
    return maps.map(Patient.fromMap).toList();
  }

  Future<List<Patient>> searchPatients(String query, {String? village}) async {
    final db = await database;
    String where = 'name LIKE ? OR village LIKE ?';
    List<dynamic> args = ['%$query%', '%$query%'];
    if (village != null && village.isNotEmpty) {
      where += ' AND village = ?';
      args.add(village);
    }
    final maps = await db.query('patients', where: where, whereArgs: args, orderBy: 'name ASC');
    return maps.map(Patient.fromMap).toList();
  }

  Future<Patient?> getPatient(String id) async {
    final db = await database;
    final maps = await db.query('patients', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Patient.fromMap(maps.first);
  }

  Future<void> insertPatient(Patient patient) async {
    final db = await database;
    await db.insert('patients', patient.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePatientSyncStatus(String patientId, String status) async {
    final db = await database;
    await db.update('patients', {'sync_status': status}, where: 'id = ?', whereArgs: [patientId]);
  }

  // ── VISIT CRUD ────────────────────────────────────────────────

  Future<Visit> createVisit(String patientId, {PatientType type = PatientType.maternal}) async {
    final db = await database;
    final visit = Visit(patientId: patientId, visitType: type);
    await db.insert('visits', visit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return visit;
  }

  Future<List<Visit>> getVisitsForPatient(String patientId, {int limit = 10}) async {
    final db = await database;
    final maps = await db.query(
      'visits',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map(Visit.fromMap).toList();
  }

  Future<Visit?> getVisit(String visitId) async {
    final db = await database;
    final maps = await db.query('visits', where: 'id = ?', whereArgs: [visitId]);
    if (maps.isEmpty) return null;
    return Visit.fromMap(maps.first);
  }

  Future<void> updateVisitField(String visitId, String field, dynamic value) async {
    final db = await database;
    await db.update('visits', {field: value}, where: 'id = ?', whereArgs: [visitId]);
  }

  Future<void> updateVisit(Visit visit) async {
    final db = await database;
    await db.update('visits', visit.toMap(), where: 'id = ?', whereArgs: [visit.id]);
  }

  Future<void> updateVisitSyncStatus(String visitId, String status) async {
    final db = await database;
    await db.update('visits', {'sync_status': status}, where: 'id = ?', whereArgs: [visitId]);
  }

  Future<List<Visit>> getPendingVisits() async {
    final db = await database;
    final maps = await db.query(
      'visits',
      where: "sync_status = 'pending' AND approved = 1",
      orderBy: 'created_at ASC',
    );
    return maps.map(Visit.fromMap).toList();
  }

  Future<Visit?> getLatestVisit(String patientId) async {
    final visits = await getVisitsForPatient(patientId, limit: 1);
    return visits.isEmpty ? null : visits.first;
  }
}
