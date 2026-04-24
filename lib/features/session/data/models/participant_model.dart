import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ParticipantModel extends Equatable {
  final String id;
  final String sessionId;
  final String name;
  final String avatar;
  final int score;
  final int rank;
  final int streak;
  final DateTime joinedAt;
  final bool isOnline;
  final List<String> answeredSlides;

  const ParticipantModel({
    required this.id,
    required this.sessionId,
    required this.name,
    required this.avatar,
    this.score = 0,
    this.rank = 0,
    this.streak = 0,
    required this.joinedAt,
    this.isOnline = true,
    this.answeredSlides = const [],
  });

  factory ParticipantModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw Exception('Document does not exist');
    }
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }
    return ParticipantModel(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      name: data['name'] ?? '',
      avatar: data['avatar'] ?? '👤',
      score: data['score'] ?? 0,
      rank: data['rank'] ?? 0,
      streak: data['streak'] ?? 0,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnline: data['isOnline'] ?? true,
      answeredSlides: List<String>.from(data['answeredSlides'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'sessionId': sessionId,
    'name': name,
    'avatar': avatar,
    'score': score,
    'rank': rank,
    'streak': streak,
    'joinedAt': Timestamp.fromDate(joinedAt),
    'isOnline': isOnline,
    'answeredSlides': answeredSlides,
  };

  ParticipantModel copyWith({
    String? id, String? sessionId, String? name, String? avatar,
    int? score, int? rank, int? streak, bool? isOnline,
    List<String>? answeredSlides,
  }) => ParticipantModel(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    name: name ?? this.name,
    avatar: avatar ?? this.avatar,
    score: score ?? this.score,
    rank: rank ?? this.rank,
    streak: streak ?? this.streak,
    joinedAt: joinedAt,
    isOnline: isOnline ?? this.isOnline,
    answeredSlides: answeredSlides ?? this.answeredSlides,
  );

  @override
  List<Object?> get props => [id, name, score, rank];
}