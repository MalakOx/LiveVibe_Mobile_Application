import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_model.dart';
import '../models/slide_model.dart';
import '../models/participant_model.dart';
import '../models/response_model.dart';

final firestoreDatasourceProvider = Provider<FirestoreDatasource>((ref) {
  return FirestoreDatasource(FirebaseFirestore.instance);
});

class FirestoreDatasource {
  final FirebaseFirestore _db;

  static const _sessions = 'sessions';
  static const _slides = 'slides';
  static const _participants = 'participants';
  static const _responses = 'responses';

  FirestoreDatasource(this._db);

  // ─── SESSIONS ────────────────────────────────────────────────

  Future<String> createSession(SessionModel session) async {
    final ref = _db.collection(_sessions).doc();
    final model = session.copyWith(id: ref.id);
    await ref.set(model.toFirestore());
    return ref.id;
  }

  Stream<SessionModel> watchSession(String sessionId) {
    return _db
        .collection(_sessions)
        .doc(sessionId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            throw Exception('Session not found');
          }
          return SessionModel.fromFirestore(doc);
        });
  }

  Future<SessionModel?> getSessionByCode(String code) async {
    final query = await _db
        .collection(_sessions)
        .where('code', isEqualTo: code.toUpperCase())
        .where('status', whereIn: ['waiting', 'live'])
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return SessionModel.fromFirestore(query.docs.first);
  }

  Future<void> updateSession(String sessionId, Map<String, dynamic> data) async {
    await _db.collection(_sessions).doc(sessionId).update(data);
  }

  Future<void> startSession(String sessionId, String firstSlideId) async {
    await _db.collection(_sessions).doc(sessionId).update({
      'status': 'live',
      'startedAt': FieldValue.serverTimestamp(),
      'currentSlideIndex': 0,
      'currentSlideId': firstSlideId,
    });
  }

  Future<void> endSession(String sessionId) async {
    await _db.collection(_sessions).doc(sessionId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
      'timerActive': false,
    });
  }

  Future<void> navigateToSlide(
    String sessionId,
    int slideIndex,
    String slideId,
  ) async {
    await _db.collection(_sessions).doc(sessionId).update({
      'currentSlideIndex': slideIndex,
      'currentSlideId': slideId,
      'timerActive': false,
    });
  }

  // ─── SLIDES ──────────────────────────────────────────────────

  Future<String> createSlide(SlideModel slide) async {
    final ref = _db
        .collection(_sessions)
        .doc(slide.sessionId)
        .collection(_slides)
        .doc();
    final model = slide.copyWith(id: ref.id);
    await ref.set(model.toFirestore());
    return ref.id;
  }

  Stream<List<SlideModel>> watchSlides(String sessionId) {
    return _db
        .collection(_sessions)
        .doc(sessionId)
        .collection(_slides)
        .orderBy('order')
        .snapshots()
        .map((snap) {
          return snap.docs
              .where((doc) => doc.exists)
              .map((doc) {
                try {
                  return SlideModel.fromFirestore(doc);
                } catch (e) {
                  // Silently skip invalid documents
                  return null;
                }
              })
              .whereType<SlideModel>()
              .toList();
        });
  }

  Future<List<SlideModel>> getSlides(String sessionId) async {
    final snap = await _db
        .collection(_sessions)
        .doc(sessionId)
        .collection(_slides)
        .orderBy('order')
        .get();
    return snap.docs.map(SlideModel.fromFirestore).toList();
  }

  Future<void> updateSlide(
    String sessionId,
    String slideId,
    Map<String, dynamic> data,
  ) async {
    await _db
        .collection(_sessions)
        .doc(sessionId)
        .collection(_slides)
        .doc(slideId)
        .update(data);
  }

  Future<void> deleteSlide(String sessionId, String slideId) async {
    await _db
        .collection(_sessions)
        .doc(sessionId)
        .collection(_slides)
        .doc(slideId)
        .delete();
  }

  // ─── PARTICIPANTS ─────────────────────────────────────────────

  Future<String> joinSession({
    required String sessionId,
    required String name,
    required String avatar,
  }) async {
    // Prevent duplicate names in same session
    final existing = await _db
        .collection(_sessions)
        .doc(sessionId)
        .collection(_participants)
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Re-activate if previously offline
      final docId = existing.docs.first.id;
      await _db
          .collection(_sessions)
          .doc(sessionId)
          .collection(_participants)
          .doc(docId)
          .update({'isOnline': true});
      return docId;
    }

    final ref = _db
        .collection(_sessions)
        .doc(sessionId)
        .collection(_participants)
        .doc();

    await ref.set({
      'sessionId': sessionId,
      'name': name,
      'avatar': avatar,
      'score': 0,
      'rank': 0,
      'streak': 0,
      'joinedAt': FieldValue.serverTimestamp(),
      'isOnline': true,
      'answeredSlides': [],
    });

    // Increment participant count
    await _db.collection(_sessions).doc(sessionId).update({
      'participantCount': FieldValue.increment(1),
    });

    return ref.id;
  }

  Stream<List<ParticipantModel>> watchParticipants(String sessionId) {
    return _db
        .collection(_sessions)
        .doc(sessionId)
        .collection(_participants)
        .orderBy('score', descending: true)
        .limit(50)  // Limit to prevent loading thousands of participants
        .snapshots()
        .map((snap) {
          return snap.docs
              .where((doc) => doc.exists)
              .map((doc) {
                try {
                  return ParticipantModel.fromFirestore(doc);
                } catch (e) {
                  // Silently skip invalid documents
                  return null;
                }
              })
              .whereType<ParticipantModel>()
              .toList();
        });
  }

  Future<void> updateParticipantScore(
    String sessionId,
    String participantId,
    int additionalScore,
    String slideId,
  ) async {
    await _db
        .collection(_sessions)
        .doc(sessionId)
        .collection(_participants)
        .doc(participantId)
        .update({
      'score': FieldValue.increment(additionalScore),
      'answeredSlides': FieldValue.arrayUnion([slideId]),
    });
  }

  Future<void> setParticipantOffline(
    String sessionId,
    String participantId,
  ) async {
    await _db
        .collection(_sessions)
        .doc(sessionId)
        .collection(_participants)
        .doc(participantId)
        .update({'isOnline': false});
  }

  // ─── RESPONSES ───────────────────────────────────────────────

  Future<bool> hasParticipantResponded(
    String sessionId,
    String slideId,
    String participantId,
  ) async {
    final query = await _db
        .collection(_sessions)
        .doc(sessionId)
        .collection(_responses)
        .where('slideId', isEqualTo: slideId)
        .where('participantId', isEqualTo: participantId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<void> submitResponse(ResponseModel response) async {
    final ref = _db
        .collection(_sessions)
        .doc(response.sessionId)
        .collection(_responses)
        .doc();

    // Use transaction to prevent duplicate submissions
    await _db.runTransaction((transaction) async {
      final existing = await _db
          .collection(_sessions)
          .doc(response.sessionId)
          .collection(_responses)
          .where('slideId', isEqualTo: response.slideId)
          .where('participantId', isEqualTo: response.participantId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Already responded to this slide');
      }

      transaction.set(ref, response.toFirestore());
    });

    // Update participant score if correct MCQ
    if (response.isCorrect == true) {
      await updateParticipantScore(
        response.sessionId,
        response.participantId,
        response.pointsEarned,
        response.slideId,
      );
    } else if (response.type != SlideType.mcq) {
      // Non-MCQ slides always give participation points
      await updateParticipantScore(
        response.sessionId,
        response.participantId,
        10,
        response.slideId,
      );
    }
  }

  Stream<List<ResponseModel>> watchResponses(
    String sessionId,
    String slideId,
  ) {
    return _db
        .collection(_sessions)
        .doc(sessionId)
        .collection(_responses)
        .where('slideId', isEqualTo: slideId)
        .limit(50)  // Limit to prevent loading thousands of responses
        .snapshots()
        .map((snap) => snap.docs.map(ResponseModel.fromFirestore).toList());
  }

  Future<void> startTimer(String sessionId) async {
    await _db.collection(_sessions).doc(sessionId).update({
      'timerActive': true,
    });
  }

  Future<void> stopTimer(String sessionId) async {
    await _db.collection(_sessions).doc(sessionId).update({
      'timerActive': false,
    });
  }

  // ─── DELETE OPERATIONS ────────────────────────────────────────

  Future<List<ParticipantModel>> getParticipants(String sessionId) async {
    final snap = await _db
        .collection(_sessions)
        .doc(sessionId)
        .collection(_participants)
        .get();
    return snap.docs.map(ParticipantModel.fromFirestore).toList();
  }

  Future<void> deleteParticipant(String sessionId, String participantId) async {
    await _db
        .collection(_sessions)
        .doc(sessionId)
        .collection(_participants)
        .doc(participantId)
        .delete();
  }

  Future<void> deleteSession(String sessionId) async {
    await _db.collection(_sessions).doc(sessionId).delete();
  }
}