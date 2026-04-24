import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum SessionStatus { waiting, live, ended }

class SessionModel extends Equatable {
  final String id;
  final String title;
  final String hostId;
  final String hostName;
  final String code;
  final SessionStatus status;
  final int currentSlideIndex;
  final String? currentSlideId;
  final int timerSeconds;
  final bool timerActive;
  final int participantCount;
  final int slideCount;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final SessionSettings settings;

  const SessionModel({
    required this.id,
    required this.title,
    required this.hostId,
    required this.hostName,
    required this.code,
    required this.status,
    required this.currentSlideIndex,
    this.currentSlideId,
    required this.timerSeconds,
    required this.timerActive,
    required this.participantCount,
    required this.slideCount,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    required this.settings,
  });

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw Exception('Document does not exist');
    }
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }
    return SessionModel(
      id: doc.id,
      title: data['title'] ?? '',
      hostId: data['hostId'] ?? '',
      hostName: data['hostName'] ?? '',
      code: data['code'] ?? '',
      status: _parseStatus(data['status']),
      currentSlideIndex: data['currentSlideIndex'] ?? 0,
      currentSlideId: data['currentSlideId'],
      timerSeconds: data['timerSeconds'] ?? 30,
      timerActive: data['timerActive'] ?? false,
      participantCount: data['participantCount'] ?? 0,
      slideCount: data['slideCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
      settings: SessionSettings.fromMap(data['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'hostId': hostId,
    'hostName': hostName,
    'code': code,
    'status': status.name,
    'currentSlideIndex': currentSlideIndex,
    'currentSlideId': currentSlideId,
    'timerSeconds': timerSeconds,
    'timerActive': timerActive,
    'participantCount': participantCount,
    'slideCount': slideCount,
    'createdAt': Timestamp.fromDate(createdAt),
    'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
    'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
    'settings': settings.toMap(),
  };

  SessionModel copyWith({
    String? id, String? title, String? hostId, String? hostName,
    String? code, SessionStatus? status, int? currentSlideIndex,
    String? currentSlideId, int? timerSeconds, bool? timerActive,
    int? participantCount, int? slideCount, DateTime? createdAt, DateTime? startedAt,
    DateTime? endedAt, SessionSettings? settings,
  }) => SessionModel(
    id: id ?? this.id,
    title: title ?? this.title,
    hostId: hostId ?? this.hostId,
    hostName: hostName ?? this.hostName,
    code: code ?? this.code,
    status: status ?? this.status,
    currentSlideIndex: currentSlideIndex ?? this.currentSlideIndex,
    currentSlideId: currentSlideId ?? this.currentSlideId,
    timerSeconds: timerSeconds ?? this.timerSeconds,
    timerActive: timerActive ?? this.timerActive,
    participantCount: participantCount ?? this.participantCount,
    slideCount: slideCount ?? this.slideCount,
    createdAt: createdAt ?? this.createdAt,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    settings: settings ?? this.settings,
  );

  static SessionStatus _parseStatus(String? s) {
    return SessionStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => SessionStatus.waiting,
    );
  }

  @override
  List<Object?> get props => [id, title, status, currentSlideIndex, timerActive];
}

class SessionSettings extends Equatable {
  final bool showLeaderboard;
  final bool allowLateJoin;
  final bool shuffleOptions;

  const SessionSettings({
    this.showLeaderboard = true,
    this.allowLateJoin = true,
    this.shuffleOptions = false,
  });

  factory SessionSettings.fromMap(Map<String, dynamic> map) => SessionSettings(
    showLeaderboard: map['showLeaderboard'] ?? true,
    allowLateJoin: map['allowLateJoin'] ?? true,
    shuffleOptions: map['shuffleOptions'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'showLeaderboard': showLeaderboard,
    'allowLateJoin': allowLateJoin,
    'shuffleOptions': shuffleOptions,
  };

  @override
  List<Object?> get props => [showLeaderboard, allowLateJoin, shuffleOptions];
}