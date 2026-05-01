import '../services/database_service.dart';
import '../services/gemma_service.dart';
import '../tools/get_patient_history.dart';

/// Tool: draft_referral_note
/// Fetches visit + patient from SQLite, builds context, calls Gemma on-device.
/// Returns plain-text referral note. Worker must approve before it is saved.
Future<String> draftReferralNote(String visitId) async {
  final db = DatabaseService.instance;

  // 1. Load visit
  final visit = await db.getVisit(visitId);
  if (visit == null) throw Exception('Visit not found: $visitId');

  // 2. Load patient
  final patient = await db.getPatient(visit.patientId);
  if (patient == null) throw Exception('Patient not found: ${visit.patientId}');

  // 3. Get patient history (last 3 visits as text)
  final history = await getPatientHistory(patient.id);

  // 4. Call Gemma on-device via GemmaService
  final note = await GemmaService.generateReferralNote(
    patientName: patient.name,
    bpSystolic: visit.bpSystolic,
    bpDiastolic: visit.bpDiastolic,
    weight: visit.weight,
    symptoms: visit.symptoms,
    notes: visit.notes,
    dangerFlags: visit.dangerFlags,
    visitDate: visit.visitDate,
    patientHistory: history,
  );

  return note;
}
