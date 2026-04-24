import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/participant_entry_screen.dart';
import '../../features/auth/presentation/screens/participant_name_screen.dart';
import '../../features/auth/presentation/screens/qr_scanner_screen.dart';
import '../../features/auth/presentation/screens/host_auth_screen.dart';
import '../../features/auth/presentation/screens/host_dashboard_screen.dart';
import '../../features/home/presentation/session_history_screen.dart';
import '../../features/home/presentation/session_history_results_screen.dart';
import '../../features/session/presentation/host/create_session_screen.dart';
import '../../features/session/presentation/host/host_dashboard_screen.dart';
import '../../features/session/presentation/host/live_results_screen.dart';
import '../../features/session/presentation/host/slide_editor_screen.dart';
import '../../features/session/presentation/shared/session_final_dashboard.dart';
import '../../features/session/presentation/participant/waiting_room_screen.dart';
import '../../features/session/presentation/participant/answer_screen.dart';
import '../../features/session/presentation/participant/participant_results_screen.dart';

// Auth guard redirect
String? _authGuard(BuildContext context, GoRouterState state, bool isAuthenticated) {
  // If trying to access host routes but not authenticated
  if (state.matchedLocation.startsWith('/host') && state.matchedLocation != '/host/auth') {
    if (!isAuthenticated) {
      return '/host/auth';
    }
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    loading: () => GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    ),
    error: (err, stack) => GoRouter(
      initialLocation: '/participant/entry',
      routes: _buildRoutes(),
      errorBuilder: (context, state) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Text(
            'Page not found: ${state.error}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    ),
    data: (user) {
      final isAuthenticated = user != null;

      return GoRouter(
        initialLocation: isAuthenticated ? '/host/dashboard' : '/participant/entry',
        debugLogDiagnostics: false,
        routes: _buildRoutes(),
        errorBuilder: (context, state) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: Text(
              'Page not found: ${state.error}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        redirect: (context, state) {
          return _authGuard(context, state, isAuthenticated);
        },
      );
    },
  );
});

List<GoRoute> _buildRoutes() {
  return [
    // SPLASH
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    ),

    // PARTICIPANT ROUTES
    GoRoute(
      path: '/participant/entry',
      name: 'participant-entry',
      builder: (_, __) => const ParticipantEntryScreen(),
    ),
    GoRoute(
      path: '/participant/qr',
      name: 'participant-qr',
      builder: (_, __) => const QRScannerScreen(),
    ),
    GoRoute(
      path: '/participant/name/:sessionCode',
      name: 'participant-name',
      builder: (_, state) => ParticipantNameScreen(
        sessionCode: state.pathParameters['sessionCode']!,
      ),
    ),

    // HOST AUTH
    GoRoute(
      path: '/host/auth',
      name: 'host-auth',
      builder: (_, __) => const HostAuthScreen(),
    ),

    // HOST DASHBOARD
    GoRoute(
      path: '/host/dashboard',
      name: 'host-dashboard-main',
      builder: (_, __) => const HostDashboardScreen(),
    ),

    // SESSION HISTORY
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (_, __) => const SessionHistoryScreen(),
    ),
    GoRoute(
      path: '/history/results/:sessionId',
      name: 'history-results',
      builder: (_, state) => SessionHistoryResultsScreen(
        sessionId: state.pathParameters['sessionId']!,
      ),
    ),

    // SESSION ROUTES
    GoRoute(
      path: '/session/final/:sessionId',
      name: 'session-final',
      builder: (_, state) => SessionFinalDashboard(
        sessionId: state.pathParameters['sessionId']!,
      ),
    ),
    GoRoute(
      path: '/session/final/:sessionId/:participantId',
      name: 'participant-final',
      builder: (_, state) => SessionFinalDashboard(
        sessionId: state.pathParameters['sessionId']!,
        participantId: state.pathParameters['participantId']!,
      ),
    ),

    // HOST SESSION ROUTES
    GoRoute(
      path: '/host/create',
      name: 'create-session',
      builder: (_, __) => const CreateSessionScreen(),
    ),
    GoRoute(
      path: '/host/editor/:sessionId',
      name: 'slide-editor',
      builder: (_, state) => SlideEditorScreen(
        sessionId: state.pathParameters['sessionId']!,
      ),
    ),
    GoRoute(
      path: '/host/session/:sessionId',
      name: 'host-session-dashboard',
      builder: (_, state) => HostSessionDashboardScreen(
        sessionId: state.pathParameters['sessionId']!,
      ),
    ),
    GoRoute(
      path: '/host/live/:sessionId',
      name: 'live-results',
      builder: (_, state) => LiveResultsScreen(
        sessionId: state.pathParameters['sessionId']!,
      ),
    ),

    // PARTICIPANT SESSION ROUTES
    GoRoute(
      path: '/session/waiting/:sessionCode',
      name: 'waiting',
      builder: (_, state) {
        final sessionCode = state.pathParameters['sessionCode']!;
        final name = state.uri.queryParameters['name'] ?? 'Participant';
        final avatar = state.uri.queryParameters['avatar'];
        return WaitingRoomScreen(
          sessionCode: sessionCode,
          participantName: name,
          avatar: avatar,
        );
      },
    ),
    GoRoute(
      path: '/session/answer/:sessionId/:participantId',
      name: 'answer',
      builder: (_, state) => AnswerScreen(
        sessionId: state.pathParameters['sessionId']!,
        participantId: state.pathParameters['participantId']!,
      ),
    ),
    GoRoute(
      path: '/results/:sessionId/:participantId',
      name: 'participant-results',
      builder: (_, state) => ParticipantResultsScreen(
        sessionId: state.pathParameters['sessionId']!,
        participantId: state.pathParameters['participantId']!,
      ),
    ),
  ];
}