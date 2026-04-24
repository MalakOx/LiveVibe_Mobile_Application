import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'slide_model.dart';

class ResponseModel extends Equatable {
  final String id;
  final String sessionId;
  final String slideId;
  final String participantId;
  final String participantName;
  final SlideType type;
  final String value;
  final int? selectedOptionIndex;
  final bool? isCorrect;
  final int pointsEarned;
  final int responseTimeMs;
  final DateTime submittedAt;

  const ResponseModel({
    required this.id,
    required this.sessionId,
    required this.slideId,
    required this.participantId,
    required this.participantName,
    required this.type,
    required this.value,
    this.selectedOptionIndex,
    this.isCorrect,
    this.pointsEarned = 0,
    required this.responseTimeMs,
    required this.submittedAt,
  });

  factory ResponseModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw Exception('Document does not exist');
    }
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }
    return ResponseModel(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      slideId: data['slideId'] ?? '',
      participantId: data['participantId'] ?? '',
      participantName: data['participantName'] ?? '',
      type: _parseType(data['type']),
      value: data['value'] ?? '',
      selectedOptionIndex: data['selectedOptionIndex'],
      isCorrect: data['isCorrect'],
      pointsEarned: data['pointsEarned'] ?? 0,
      responseTimeMs: data['responseTimeMs'] ?? 0,
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'sessionId': sessionId,
    'slideId': slideId,
    'participantId': participantId,
    'participantName': participantName,
    'type': type.name,
    'value': value,
    'selectedOptionIndex': selectedOptionIndex,
    'isCorrect': isCorrect,
    'pointsEarned': pointsEarned,
    'responseTimeMs': responseTimeMs,
    'submittedAt': Timestamp.fromDate(submittedAt),
  };

  static SlideType _parseType(String? t) {
    switch (t) {
      case 'mcq': return SlideType.mcq;
      case 'openText': return SlideType.openText;
      case 'wordCloud': return SlideType.wordCloud;
      default: return SlideType.mcq;
    }
  }

  @override
  List<Object?> get props => [id, slideId, participantId];
}