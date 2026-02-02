/// Defines the types of manual interventions for streak calculation.
enum StreakAdjustmentType {
  /// A paid action to bridge a gap in the past.
  restore,

  /// A pre-emptive action from a premium subscription to prevent a streak from breaking.
  freeze,
}