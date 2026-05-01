/// Tool: flag_danger_signs
/// PURE DART — deterministic threshold check. NO AI involved.
///
/// Based on WHO/MOHFW ANC guidelines for danger sign detection.
/// Returns a list of danger flag strings. Empty = no danger signs.

enum DangerLevel { critical, warning, normal }

class DangerFlag {
  final String message;
  final DangerLevel level;
  final String emoji;

  const DangerFlag({
    required this.message,
    required this.level,
    required this.emoji,
  });
}

class DangerSignResult {
  final List<DangerFlag> flags;
  final DangerLevel overallLevel;

  const DangerSignResult({required this.flags, required this.overallLevel});

  bool get hasFlags => flags.isNotEmpty;
  bool get isCritical => overallLevel == DangerLevel.critical;
  bool get isWarning => overallLevel == DangerLevel.warning;

  List<String> get flagMessages => flags.map((f) => f.message).toList();
}

/// Main tool function
/// [bpSystolic] — systolic BP in mmHg
/// [bpDiastolic] — diastolic BP in mmHg
DangerSignResult flagDangerSigns(int bpSystolic, int bpDiastolic) {
  final flags = <DangerFlag>[];

  // ── CRITICAL FLAGS ────────────────────────────────────────
  // Severe hypertension / pre-eclampsia
  if (bpSystolic >= 160 || bpDiastolic >= 110) {
    flags.add(const DangerFlag(
      message: 'Severe Hypertension — Immediate Referral Required',
      level: DangerLevel.critical,
      emoji: '🔴',
    ));
  } else if (bpSystolic >= 140 || bpDiastolic >= 90) {
    flags.add(const DangerFlag(
      message: 'Hypertension / Pre-eclampsia Risk',
      level: DangerLevel.critical,
      emoji: '🔴',
    ));
  }

  // Hypotension / shock
  if (bpSystolic < 90) {
    flags.add(const DangerFlag(
      message: 'Hypotension — Shock Risk',
      level: DangerLevel.critical,
      emoji: '🔴',
    ));
  }

  // ── WARNING FLAGS ─────────────────────────────────────────
  // Borderline high
  if (bpSystolic >= 130 && bpSystolic < 140 ||
      bpDiastolic >= 80 && bpDiastolic < 90) {
    // Only add if not already flagged as critical
    final alreadyCritical = flags.any((f) => f.level == DangerLevel.critical);
    if (!alreadyCritical) {
      flags.add(const DangerFlag(
        message: 'Borderline BP — Monitor Closely',
        level: DangerLevel.warning,
        emoji: '🟡',
      ));
    }
  }

  // Pulse pressure (difference) too narrow — may indicate cardiac issue
  final pulsePressure = bpSystolic - bpDiastolic;
  if (pulsePressure < 20 && bpSystolic >= 90) {
    flags.add(const DangerFlag(
      message: 'Narrow Pulse Pressure — Check Again',
      level: DangerLevel.warning,
      emoji: '🟡',
    ));
  }

  // Determine overall level
  DangerLevel overall = DangerLevel.normal;
  if (flags.any((f) => f.level == DangerLevel.critical)) {
    overall = DangerLevel.critical;
  } else if (flags.any((f) => f.level == DangerLevel.warning)) {
    overall = DangerLevel.warning;
  }

  return DangerSignResult(flags: flags, overallLevel: overall);
}
