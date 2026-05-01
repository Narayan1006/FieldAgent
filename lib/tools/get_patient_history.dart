import '../services/database_service.dart';
import '../models/visit.dart';

/// Tool: get_patient_history
/// Returns a summary of the last 3 visits for a patient.
/// This is used to prime Gemma's context.
Future<String> getPatientHistory(String patientId) async {
  final visits = await DatabaseService.instance.getVisitsForPatient(
    patientId,
    limit: 3,
  );

  if (visits.isEmpty) {
    return 'No previous visits recorded for this patient.';
  }

  final buffer = StringBuffer();
  buffer.writeln('Previous visits (most recent first):');

  for (int i = 0; i < visits.length; i++) {
    final v = visits[i];
    final bp = (v.bpSystolic != null && v.bpDiastolic != null)
        ? '${v.bpSystolic}/${v.bpDiastolic} mmHg'
        : 'not recorded';
    final weight = v.weight != null ? '${v.weight!.toStringAsFixed(1)} kg' : 'not recorded';
    final symptoms = v.symptoms.isEmpty ? 'none' : v.symptoms.join(', ');
    final flags = v.dangerFlags.isEmpty ? 'none' : v.dangerFlags.join('; ');

    buffer.writeln('Visit ${i + 1} (${v.visitDate}):');
    buffer.writeln('  BP: $bp | Weight: $weight');
    buffer.writeln('  Symptoms: $symptoms');
    if (v.dangerFlags.isNotEmpty) {
      buffer.writeln('  ⚠ Danger flags: $flags');
    }
    if (v.notes.isNotEmpty) {
      buffer.writeln('  Notes: ${v.notes}');
    }
  }

  return buffer.toString();
}

/// Convenience: get patient history as list of visits for UI display
Future<List<Visit>> getPatientVisitHistory(String patientId, {int limit = 3}) {
  return DatabaseService.instance.getVisitsForPatient(patientId, limit: limit);
}
