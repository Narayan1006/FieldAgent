import '../services/database_service.dart';

/// Tool: log_visit_entry
/// Saves a single field to a visit row in SQLite.
/// Called incrementally as the worker fills each field — ensures no data loss.
///
/// Supported field names (map to SQLite columns):
///   bp_systolic, bp_diastolic, weight, symptoms, notes,
///   danger_flags, referral_note, approved

Future<void> logVisitEntry({
  required String visitId,
  required String field,
  required dynamic value,
}) async {
  // Validate field name to prevent SQL injection
  const allowedFields = {
    'bp_systolic',
    'bp_diastolic',
    'weight',
    'symptoms',
    'notes',
    'danger_flags',
    'referral_note',
    'approved',
  };

  if (!allowedFields.contains(field)) {
    throw ArgumentError('Invalid field name: $field');
  }

  // Convert list values to their storage format
  dynamic storedValue = value;
  if (value is List<String>) {
    if (field == 'danger_flags') {
      storedValue = value.join('|');
    } else {
      storedValue = value.join(',');
    }
  } else if (value is bool) {
    storedValue = value ? 1 : 0;
  }

  await DatabaseService.instance.updateVisitField(visitId, field, storedValue);
}
