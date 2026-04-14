class StepGoalCalculator {
  /// Calculates the new daily step goal based on the current goal and the user's confidence level.
  ///
  /// The formula increases the goal by a percentage equal to the confidence level (1-10)
  /// and rounds to the nearest 10.
  static int calculateNewGoal(int currentGoal, int confidence) {
    final rawGoal = currentGoal * (1 + confidence / 100);
    return (rawGoal / 10).round() * 10;
  }
}
