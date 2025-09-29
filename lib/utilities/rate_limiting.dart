// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:quotelike/utilities/enums.dart';

DateTime _lastAction = DateTime(0); // this value represents never
/// Create a function that can only be called [throttleTimeMs] milliseconds from the last time it was called
void throttledFunc(int throttleTimeMs, Function() func) async {
  if (DateTime.timestamp().difference(_lastAction).inMilliseconds >= throttleTimeMs) {
    await func();
    _lastAction = DateTime.timestamp();
  }
}

final _storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

/// Rate limits are per-id, stored in a json-formatted string
class RateLimit {
  final String id;
  final Duration cooldown;
  final ErrorCode error;
  const RateLimit(this.id, this.cooldown, this.error);

  void init() async {
    if (await _storage.read(key: id) == null) {
      await _storage.write(key: id, value: jsonEncode({}));
    }
  }

  /// Returns an error if the cooldown hasn't expired yet
  Future<ErrorCode?> testCooldown(String identifier) async {
    String? timestampsJsonString = await _storage.read(key: id);
    if (timestampsJsonString == null) {
      timestampsJsonString = jsonEncode({});
      await _storage.write(key: id, value: timestampsJsonString);
    }

    Map<String, dynamic> timestampsJson = jsonDecode(timestampsJsonString);
    if (timestampsJson[identifier] == null) {
      // if new identifier encountered, add it
      await setTimestamp(identifier, reset: true);
      timestampsJson[identifier] = DateTime(0).toString();
    }

    if (DateTime.now().difference(DateTime.parse(timestampsJson[identifier]!)) < cooldown) {
      return error;
    }
    else {
      return null;
    }
  }

  Future<void> setTimestamp(String identifier, {bool reset = false}) async {
    String? timestampsJsonString = await _storage.read(key: id);
    if (timestampsJsonString == null) {
      throw Exception("Timestamp doesn't exist in setTimestamp()"); // should never happen
    }

    Map<String, dynamic> timestampsJson = jsonDecode(timestampsJsonString);
    timestampsJson[identifier] = reset ? DateTime(0).toString() : DateTime.now().toString();

    await _storage.write(key: id, value: jsonEncode(timestampsJson));
  }

  Future<void> deleteTimestamp(String identifier) async {
    await _storage.delete(key: identifier);
  }

}

class RateLimits {
  static RateLimit PASSWORD_RESET_EMAIL = RateLimit(
    "Password reset email", 
    Duration(minutes: 59),
    ErrorCode.RECENT_PASSWORD_RESET
  );
  static RateLimit VERIFICATION_EMAIL = RateLimit(
    "Verification email", 
    Duration(hours: 70),
    ErrorCode.RECENT_VERIFICATION_EMAIL
  );
  static RateLimit EMAIL_CHANGE = RateLimit(
    "Changing email", 
    Duration(hours: 23),
    ErrorCode.RECENT_EMAIL_CHANGE
  );
  static RateLimit QUOTE_SUGGESTION = RateLimit(
    "Quote suggestion", 
    Duration(minutes: 59),
    ErrorCode.RECENT_SUGGESTION
  );
}
