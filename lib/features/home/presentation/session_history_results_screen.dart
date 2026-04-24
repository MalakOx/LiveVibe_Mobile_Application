import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_history_view_screen.dart';

class SessionHistoryResultsScreen extends ConsumerWidget {
  final String sessionId;

  const SessionHistoryResultsScreen({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SessionHistoryViewScreen(sessionId: sessionId);
  }
}
