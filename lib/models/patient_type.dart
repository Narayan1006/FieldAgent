/// Defines all patient categories in FieldAgent.
/// Each type drives: form fields, danger flag logic, Gemma prompts, and UI color.
enum PatientType {
  maternal,
  child,
  tb,
  malaria,
  familyPlanning,
  newborn,
  general,
}

extension PatientTypeX on PatientType {
  String get key {
    switch (this) {
      case PatientType.maternal:       return 'maternal';
      case PatientType.child:          return 'child';
      case PatientType.tb:             return 'tb';
      case PatientType.malaria:        return 'malaria';
      case PatientType.familyPlanning: return 'family_planning';
      case PatientType.newborn:        return 'newborn';
      case PatientType.general:        return 'general';
    }
  }

  String get label {
    switch (this) {
      case PatientType.maternal:       return 'Maternal Health';
      case PatientType.child:          return 'Child Immunization';
      case PatientType.tb:             return 'TB Follow-up';
      case PatientType.malaria:        return 'Malaria/Dengue';
      case PatientType.familyPlanning: return 'Family Planning';
      case PatientType.newborn:        return 'Newborn Care';
      case PatientType.general:        return 'General Sick';
    }
  }

  String get shortLabel {
    switch (this) {
      case PatientType.maternal:       return 'Maternal';
      case PatientType.child:          return 'Child';
      case PatientType.tb:             return 'TB';
      case PatientType.malaria:        return 'Malaria';
      case PatientType.familyPlanning: return 'Family Plan';
      case PatientType.newborn:        return 'Newborn';
      case PatientType.general:        return 'General';
    }
  }

  String get emoji {
    switch (this) {
      case PatientType.maternal:       return '🤰';
      case PatientType.child:          return '👶';
      case PatientType.tb:             return '💊';
      case PatientType.malaria:        return '🦟';
      case PatientType.familyPlanning: return '🌸';
      case PatientType.newborn:        return '🍼';
      case PatientType.general:        return '🩺';
    }
  }

  /// Primary color for UI (hex ARGB)
  int get colorValue {
    switch (this) {
      case PatientType.maternal:       return 0xFF7C4DFF; // Purple
      case PatientType.child:          return 0xFF00BCD4; // Cyan
      case PatientType.tb:             return 0xFFFF6D00; // Deep Orange
      case PatientType.malaria:        return 0xFFE53935; // Red
      case PatientType.familyPlanning: return 0xFFE91E63; // Pink
      case PatientType.newborn:        return 0xFF43A047; // Green
      case PatientType.general:        return 0xFF1E88E5; // Blue
    }
  }

  static PatientType fromKey(String key) {
    return PatientType.values.firstWhere(
      (t) => t.key == key,
      orElse: () => PatientType.maternal,
    );
  }
}
