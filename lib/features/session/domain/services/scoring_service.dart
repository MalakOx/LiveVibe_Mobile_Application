import 'dart:math';

/// Service responsible for all scoring calculations.
/// Single source of truth for point calculations.
class ScoringService {
  /// Calculate points for a response.
  ///
  /// For correct answers: 50 base points + up to 50 bonus points for speed
  /// For partial answers: 50% of correct answer points
  /// For incorrect answers: 0 points
  ///
  /// Returns points between 0-100 for MCQ questions.
  int calculatePoints({
    required bool isCorrect,
    required bool isPartial,
    required int responseTimeMs,
    required int timeLimitSeconds,
  }) {
    // Incorrect answer with no partial credit = 0 points
    if (!isCorrect && !isPartial) {
      return 0;
    }

    // Calculate speed ratio: 1.0 = instant (full bonus), 0.0 = out of time
    final speedRatio = 1.0 - (responseTimeMs / (timeLimitSeconds * 1000));
    final clampedSpeedRatio = speedRatio.clamp(0, 1);

    // Base points + speed bonus
    const basePoints = 50;
    const bonusPoints = 50;
    final totalPoints = basePoints + (bonusPoints * clampedSpeedRatio);

    // Partial answers get 50% of points
    if (isPartial) {
      return (totalPoints / 2).round();
    }

    // Correct answers get full points
    return totalPoints.round();
  }

  /// Determine if answer is partially correct.
  /// Used for multiple-choice questions with multiple answers.
  ///
  /// Returns true if:
  /// - All selected options are correct
  /// - But not all correct options are selected
  bool isPartialCorrect({
    required Set<int> selectedIndices,
    required List<int> correctIndices,
  }) {
    if (selectedIndices.isEmpty) return false;

    // Check if all selected are correct
    final allSelectedAreCorrect = selectedIndices.every(
      (idx) => correctIndices.contains(idx),
    );

    // Check if it's a full match
    final isFullMatch = allSelectedAreCorrect &&
        selectedIndices.length == correctIndices.length;

    // Partial = all selected correct but incomplete set
    return allSelectedAreCorrect && !isFullMatch;
  }

  /// Determine if answer is fully correct.
  /// For single-choice: selected index matches correct index.
  /// For multiple-choice: all selected indices match all correct indices.
  bool isFullyCorrect({
    required int? selectedIndex,
    required int? correctIndex,
    required Set<int> selectedIndices,
    required List<int> correctIndices,
  }) {
    // Single-choice comparison
    if (selectedIndex != null && correctIndex != null) {
      return selectedIndex == correctIndex;
    }

    // Multiple-choice comparison
    if (selectedIndices.isNotEmpty && correctIndices.isNotEmpty) {
      return selectedIndices.length == correctIndices.length &&
          selectedIndices.every((idx) => correctIndices.contains(idx));
    }

    return false;
  }
}
