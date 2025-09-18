
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:quotelike/utilities/constants.dart';

DateTime lastAction = DateTime(2000); // 1st jan 2000 represents never
/// Create a function that can only be called throttleTimeMs milliseconds from the last time it was called
void throttledFunc(int throttleTimeMs, Function() func) async {
  if (DateTime.timestamp().difference(lastAction).inMilliseconds >= throttleTimeMs) {
    await func();
    lastAction = DateTime.timestamp();
  }
}

final storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
/// Rate limits are per-email, stored in a json-formatted string
class RateLimit {
  final String id;
  final Duration cooldown;
  final ErrorCode error;
  const RateLimit(this.id, this.cooldown, this.error);

  void init() async {
    if (await storage.read(key: id) == null) {
      await storage.write(key: id, value: jsonEncode({}));
    }
  }

  /// Returns an error if the cooldown hasn't expired yet
  Future<ErrorCode?> testCooldown(String identifier) async {
    String? timestampsJsonString = await storage.read(key: id);
    if (timestampsJsonString == null) {
      timestampsJsonString = jsonEncode({});
      await storage.write(key: id, value: timestampsJsonString);
    }

    Map<String, dynamic> timestampsJson = jsonDecode(timestampsJsonString);
    if (timestampsJson[identifier] == null) {
      // if new email encountered, add it
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
    String? timestampsJsonString = await storage.read(key: id);
    if (timestampsJsonString == null) {
      throw Exception(); // should never be null
    }

    Map<String, dynamic> timestampsJson = jsonDecode(timestampsJsonString);
    timestampsJson[identifier] = reset ? DateTime(0).toString() : DateTime.now().toString();

    await storage.write(key: id, value: jsonEncode(timestampsJson));
  }

}

class RateLimits {
  static RateLimit PASSWORD_RESET_EMAIL = RateLimit(
    "Password reset email", 
    Duration(minutes: 59),
    ErrorCode("You have already requested a password reset in the past hour.")
  );
  static RateLimit VERIFICATION_EMAIL = RateLimit(
    "Verification email", 
    Duration(hours: 70),
    ErrorCode("A verification email was already sent recently. Check your inbox and spam folder.")
  );
  static RateLimit EMAIL_CHANGE = RateLimit(
    "Changing email", 
    Duration(hours: 23),
    ErrorCode("An email change was already requested in the past day.")
  );
  static RateLimit QUOTE_SUGGESTION = RateLimit(
    "Quote suggestion", 
    Duration(minutes: 59),
    ErrorCode("You have already made a suggestion in the past hour.")
  );
}
