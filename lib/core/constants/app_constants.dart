/// Application-wide constants.
/// Replaces magic numbers and strings throughout the codebase.

class AppConstants {
  // ─── TIMERS & DURATIONS ──────────────────────────────────────

  static const int defaultSlideTimerSeconds = 30;
  static const int sessionFinishTimeoutSeconds = 5;

  // ─── SCORING ──────────────────────────────────────────────────

  static const int basePointsPerQuestion = 50;
  static const int bonusPointsForSpeed = 50;
  static const double partialCreditPercentage = 0.5; // 50% for partial answers

  // ─── PAGINATION & LIMITS ─────────────────────────────────────

  static const int responsesPageLimit = 50;
  static const int participantsPageLimit = 50;

  // ─── FIRESTORE COLLECTIONS ───────────────────────────────────

  static const String firestoreCollectionSessions = 'sessions';
  static const String firestoreCollectionSlides = 'slides';
  static const String firestoreCollectionParticipants = 'participants';
  static const String firestoreCollectionResponses = 'responses';

  // ─── SESSION STATUSES ─────────────────────────────────────────

  // Note: These should match SessionStatus enum
  // They're included here for Firestore queries where type is string
  static const String sessionStatusWaiting = 'waiting';
  static const String sessionStatusLive = 'live';
  static const String sessionStatusEnded = 'ended';

  // ─── UI ───────────────────────────────────────────────────────

  static const int animationDurationMs = 300;
}
