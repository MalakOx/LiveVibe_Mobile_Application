enum UserRole {
  host,
  participant,
}

extension UserRoleExtension on UserRole {
  String get name {
    return switch (this) {
      UserRole.host => 'host',
      UserRole.participant => 'participant',
    };
  }
}

// Static helper function
UserRole userRoleFromString(String value) {
  return switch (value.toLowerCase()) {
    'host' => UserRole.host,
    'participant' => UserRole.participant,
    _ => UserRole.participant,
  };
}
