import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum SlideType { mcq, openText, wordCloud }
enum AnswerMode { single, multiple }  // NEW

class SlideModel extends Equatable {
  final String id;
  final String sessionId;
  final SlideType type;
  final int order;
  final String question;
  final List<String> options;
  final int? correctOptionIndex;  // For backward compat (single answer)
  final List<int> correctOptionIndices;  // NEW: For multiple answers
  final AnswerMode answerMode;  // NEW: single or multiple
  final int points;
  final int timeLimit;
  final bool isActive;
  final String? imageUrl;
  final DateTime createdAt;

  const SlideModel({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.order,
    required this.question,
    this.options = const [],
    this.correctOptionIndex,
    this.correctOptionIndices = const [],
    this.answerMode = AnswerMode.single,
    this.points = 100,
    this.timeLimit = 30,
    this.isActive = true,
    this.imageUrl,
    required this.createdAt,
  });

  factory SlideModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw Exception('Document does not exist');
    }
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }
    return SlideModel(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      type: _parseType(data['type']),
      order: data['order'] ?? 0,
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctOptionIndex: data['correctOptionIndex'],
      correctOptionIndices: List<int>.from(data['correctOptionIndices'] ?? []),
      answerMode: _parseAnswerMode(data['answerMode']),
      points: data['points'] ?? 100,
      timeLimit: data['timeLimit'] ?? 30,
      isActive: data['isActive'] ?? true,
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'sessionId': sessionId,
    'type': type.name,
    'order': order,
    'question': question,
    'options': options,
    'correctOptionIndex': correctOptionIndex,
    'correctOptionIndices': correctOptionIndices,
    'answerMode': answerMode.name,
    'points': points,
    'timeLimit': timeLimit,
    'isActive': isActive,
    'imageUrl': imageUrl,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  SlideModel copyWith({
    String? id, String? sessionId, SlideType? type, int? order,
    String? question, List<String>? options, int? correctOptionIndex,
    List<int>? correctOptionIndices, AnswerMode? answerMode,
    int? points, int? timeLimit, bool? isActive, String? imageUrl,
  }) => SlideModel(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    type: type ?? this.type,
    order: order ?? this.order,
    question: question ?? this.question,
    options: options ?? this.options,
    correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
    correctOptionIndices: correctOptionIndices ?? this.correctOptionIndices,
    answerMode: answerMode ?? this.answerMode,
    points: points ?? this.points,
    timeLimit: timeLimit ?? this.timeLimit,
    isActive: isActive ?? this.isActive,
    imageUrl: imageUrl ?? this.imageUrl,
    createdAt: createdAt,
  );

  static SlideType _parseType(String? t) {
    switch (t) {
      case 'mcq': return SlideType.mcq;
      case 'openText': return SlideType.openText;
      case 'wordCloud': return SlideType.wordCloud;
      default: return SlideType.mcq;
    }
  }

  static AnswerMode _parseAnswerMode(String? mode) {
    switch (mode) {
      case 'single': return AnswerMode.single;
      case 'multiple': return AnswerMode.multiple;
      default: return AnswerMode.single;
    }
  }

  @override
  List<Object?> get props => [id, sessionId, type, order, question, options, correctOptionIndex, correctOptionIndices, answerMode];
}