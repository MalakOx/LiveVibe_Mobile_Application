import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/entities/auth_user.dart';

class AuthUserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String role; // stored as string in Firestore
  final DateTime createdAt;

  AuthUserModel({
    required this.uid,
    required this.email,
    this.displayName,
    required this.role,
    required this.createdAt,
  });

  factory AuthUserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return AuthUserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      role: data['role'] ?? 'host',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Convert to domain entity
  AuthUser toEntity() {
    return AuthUser(
      uid: uid,
      email: email,
      displayName: displayName,
      role: userRoleFromString(role),
      createdAt: createdAt,
    );
  }

  AuthUserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    DateTime? createdAt,
  }) {
    return AuthUserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
