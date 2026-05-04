import 'package:flutter/material.dart';
import '../providers/plan_provider.dart';
import '../../shared/theme/app_colors.dart';

/// Returns the progress color for a date based on focus/free hours and completion rate.
/// Returns null for future dates or dates with no plans.
Color? dayProgressColor(DateTime date, DateTime today, PlanNotifier notifier) {
  if (date.isAfter(today)) return null;
  final plans = notifier.plansForDate(date);
  if (plans.isEmpty) return null;

  final freeHours = notifier.freeHoursForDate(date);
  final focusHours = notifier.focusHoursForDate(date);
  final completionRate = notifier.completedCountForDate(date) / plans.length;

  if (freeHours > 0 && focusHours > freeHours) return kPrimary;
  if (freeHours > 0 && focusHours < freeHours * 0.2) return kDanger;
  if (completionRate >= 0.8) return kSuccess;
  return kWarning;
}
