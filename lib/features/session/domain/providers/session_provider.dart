import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/firestore_datasource.dart';
import '../../data/models/session_model.dart';
import '../../data/models/slide_model.dart';
import '../../data/models/participant_model.dart';
import '../../data/models/response_model.dart';
import '../../../../core/utils/id_generator.dart';
import '../services/scoring_service.dart';

// ─── SCORING SERVICE ──────────────────────────────────────────────

final scoringServiceProvider = Provider<ScoringService>((_) {
  return ScoringService();
});

// ─── SESSION STREAM ───────────────────────────────────────────────

final sessionStreamProvider = StreamProvider.family<SessionModel, String>((
  ref,
  sessionId,
) {
  final datasource = ref.watch(firestoreDatasourceProvider);
  return datasource.watchSession(sessionId);
});

// ─── SLIDES STREAM ────────────────────────────────────────────────

final slidesStreamProvider = StreamProvider.family<List<SlideModel>, String>((
  ref,
  sessionId,
) {
  final datasource = ref.watch(firestoreDatasourceProvider);
  return datasource.watchSlides(sessionId);
});

// ─── PARTICIPANTS STREAM ──────────────────────────────────────────

final participantsStreamProvider =
    StreamProvider.family<List<ParticipantModel>, String>((ref, sessionId) {
  final datasource = ref.watch(firestoreDatasourceProvider);
  return datasource.watchParticipants(sessionId);
});

// ─── RESPONSES STREAM ────────────────────────────────────────────

typedef SlideResponseArgs = ({String sessionId, String slideId});

final responsesStreamProvider =
    StreamProvider.family<List<ResponseModel>, SlideResponseArgs>((
  ref,
  args,
) {
  final datasource = ref.watch(firestoreDatasourceProvider);
  return datasource.watchResponses(args.sessionId, args.slideId);
});

// ─── SESSION FINISH NOTIFIER ──────────────────────────────────────

/// Atomically finishes a session and waits for backend confirmation.
/// This ensures participants are notified via Firestore stream before
/// the host navigates to the final dashboard.
class SessionFinishNotifier extends AsyncNotifier<void> {
  FirestoreDatasource get _ds => ref.read(firestoreDatasourceProvider);

  @override
  Future<void> build() async {}

  /// Finish session atomically:
  /// 1. Update backend with status = ended
  /// 2. Wait for status confirmation via stream
  /// 3. Return only after confirmed (or timeout)
  Future<void> finishSession(String sessionId) async {
    state = const AsyncLoading();
    try {
      // Step 1: Update backend
      await _ds.endSession(sessionId);
      
      // Step 2: Wait for status confirmation via stream
      // This ensures Firestore has propagated the change to all listeners
      final sessionStream = _ds.watchSession(sessionId);
      await sessionStream
          .firstWhere(
            (session) => session.status == SessionStatus.ended,
            orElse: () => throw Exception('Session finish confirmation timeout'),
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Session finish confirmation timeout'),
          );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final sessionFinishProvider = AsyncNotifierProvider<SessionFinishNotifier, void>(
  SessionFinishNotifier.new,
);

// ─── SESSION CONTROLLER ───────────────────────────────────────────

class SessionController extends AsyncNotifier<void> {
  FirestoreDatasource get _ds => ref.read(firestoreDatasourceProvider);

  @override
  Future<void> build() async {}

  Future<String> createSession({
    required String title,
    required String hostId,
    required String hostName,
  }) async {
    state = const AsyncLoading();
    try {
      final session = SessionModel(
        id: '',
        title: title,
        hostId: hostId,
        hostName: hostName,
        code: IdGenerator.generateSessionCode(),
        status: SessionStatus.waiting,
        currentSlideIndex: 0,
        timerSeconds: 30,
        timerActive: false,
        participantCount: 0,
        slideCount: 0,
        createdAt: DateTime.now(),
        settings: const SessionSettings(),
      );
      final id = await _ds.createSession(session);
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<String> createSessionFromTemplate({
    required String templateSessionId,
    required String title,
    required String hostId,
    required String hostName,
  }) async {
    state = const AsyncLoading();
    try {
      // 1. Créer la nouvelle session
      final newSession = SessionModel(
        id: '',
        title: title,
        hostId: hostId,
        hostName: hostName,
        code: IdGenerator.generateSessionCode(),
        status: SessionStatus.waiting,
        currentSlideIndex: 0,
        timerSeconds: 30,
        timerActive: false,
        participantCount: 0,
        slideCount: 0,
        createdAt: DateTime.now(),
        settings: const SessionSettings(),
      );
      final newSessionId = await _ds.createSession(newSession);

      // 2. Récupérer les slides de l'ancienne session
      final templateSlides = await _ds.getSlides(templateSessionId);
      
      // 3. Copier chaque slide dans la nouvelle session
      for (int i = 0; i < templateSlides.length; i++) {
        final oldSlide = templateSlides[i];
        final newSlide = SlideModel(
          id: '',
          sessionId: newSessionId,
          type: oldSlide.type,
          order: i,
          question: oldSlide.question,
          options: oldSlide.options,
          correctOptionIndex: oldSlide.correctOptionIndex,
          timeLimit: oldSlide.timeLimit,
          createdAt: DateTime.now(),
        );
        await _ds.createSlide(newSlide);
      }

      state = const AsyncData(null);
      return newSessionId;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> startSession(String sessionId) async {
    final slides = await _ds.getSlides(sessionId);
    if (slides.isEmpty) throw Exception('Add at least one slide to start.');
    await _ds.startSession(sessionId, slides.first.id);
  }

  Future<void> navigateSlide(
    String sessionId,
    List<SlideModel> slides,
    int newIndex,
  ) async {
    if (newIndex < 0 || newIndex >= slides.length) return;
    await _ds.navigateToSlide(sessionId, newIndex, slides[newIndex].id);
  }

  Future<void> endSession(String sessionId) async {
    await _ds.endSession(sessionId);
  }

  Future<void> toggleTimer(String sessionId, bool active) async {
    if (active) {
      await _ds.startTimer(sessionId);
    } else {
      await _ds.stopTimer(sessionId);
    }
  }

  Future<String> addSlide({
    required String sessionId,
    required SlideType type,
    required int order,
  }) async {
    final slide = SlideModel(
      id: '',
      sessionId: sessionId,
      type: type,
      order: order,
      question: _defaultQuestion(type),
      options: type == SlideType.mcq
          ? ['Option A', 'Option B', 'Option C', 'Option D']
          : [],
      createdAt: DateTime.now(),
    );
    return _ds.createSlide(slide);
  }

  Future<void> updateSlide(
    String sessionId,
    String slideId,
    Map<String, dynamic> data,
  ) async {
    await _ds.updateSlide(sessionId, slideId, data);
  }

  Future<void> deleteSlide(String sessionId, String slideId) async {
    await _ds.deleteSlide(sessionId, slideId);
  }

  Future<void> deleteSession(String sessionId) async {
    // Delete all slides first
    final slides = await _ds.getSlides(sessionId);
    for (final slide in slides) {
      await _ds.deleteSlide(sessionId, slide.id);
    }
    // Delete all participants
    final participants = await _ds.getParticipants(sessionId);
    for (final participant in participants) {
      await _ds.deleteParticipant(sessionId, participant.id);
    }
    // Delete the session
    await _ds.deleteSession(sessionId);
  }

  String _defaultQuestion(SlideType type) {
    switch (type) {
      case SlideType.mcq: return 'Your question here?';
      case SlideType.openText: return 'Share your thoughts...';
      case SlideType.wordCloud: return 'What word comes to mind?';
    }
  }
}

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, void>(SessionController.new);

// ─── PARTICIPANT CONTROLLER ──────────────────────────────────────

class ParticipantController extends AsyncNotifier<String?> {
  FirestoreDatasource get _ds => ref.read(firestoreDatasourceProvider);

  @override
  Future<String?> build() async => null;

  Future<String> joinSession({
    required String code,
    required String name,
    required String avatar,
  }) async {
    state = const AsyncLoading();
    try {
      final session = await _ds.getSessionByCode(code);
      if (session == null) throw Exception('Session not found or has ended.');
      if (session.status == SessionStatus.ended) {
        throw Exception('This session has already ended.');
      }
      if (!session.settings.allowLateJoin &&
          session.status == SessionStatus.live) {
        throw Exception('Late joining is disabled for this session.');
      }

      final participantId = await _ds.joinSession(
        sessionId: session.id,
        name: name.trim(),
        avatar: avatar,
      );

      state = AsyncData(session.id);
      return participantId;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final participantControllerProvider =
    AsyncNotifierProvider<ParticipantController, String?>(
  ParticipantController.new,
);

// ─── RESPONSE CONTROLLER ─────────────────────────────────────────

class ResponseController extends AsyncNotifier<void> {
  FirestoreDatasource get _ds => ref.read(firestoreDatasourceProvider);

  @override
  Future<void> build() async {}

  Future<void> submitResponse({
    required String sessionId,
    required String slideId,
    required String participantId,
    required String participantName,
    required SlideType type,
    required String value,
    int? selectedOptionIndex,
    bool? isCorrect,
    int? correctOptionIndex,
    required int responseTimeMs,
    int timeLimit = 30,
  }) async {
    // Duplicate guard
    final alreadyAnswered = await _ds.hasParticipantResponded(
      sessionId, slideId, participantId,
    );
    if (alreadyAnswered) throw Exception('Already submitted for this slide.');

    // Calculate points using ScoringService
    final scoringService = ref.read(scoringServiceProvider);
    int pointsEarned = 0;
    if (type == SlideType.mcq && isCorrect == true) {
      pointsEarned = scoringService.calculatePoints(
        isCorrect: true,
        isPartial: false,
        responseTimeMs: responseTimeMs,
        timeLimitSeconds: timeLimit,
      );
    }

    final response = ResponseModel(
      id: '',
      sessionId: sessionId,
      slideId: slideId,
      participantId: participantId,
      participantName: participantName,
      type: type,
      value: value,
      selectedOptionIndex: selectedOptionIndex,
      isCorrect: isCorrect,
      pointsEarned: pointsEarned,
      responseTimeMs: responseTimeMs,
      submittedAt: DateTime.now(),
    );

    await _ds.submitResponse(response);
  }
}

final responseControllerProvider =
    AsyncNotifierProvider<ResponseController, void>(ResponseController.new);