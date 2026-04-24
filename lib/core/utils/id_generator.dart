import 'dart:math';
import 'package:uuid/uuid.dart';

class IdGenerator {
  static const _uuid = Uuid();
  static final _random = Random();

  static String generateId() => _uuid.v4();

  static String generateSessionCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  static String generateAvatarEmoji() {
    const avatars = [
      '🦊', '🐼', '🦁', '🐯', '🦄', '🐸', '🐧', '🦋',
      '🦅', '🐻', '🦊', '🦝', '🦨', '🦡', '🐨', '🐮',
    ];
    return avatars[_random.nextInt(avatars.length)];
  }
}