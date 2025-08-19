import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotebook/constants.dart';

void showLoadingIcon(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => const Center(child: CircularProgressIndicator())
  );
}

void hideLoadingIcon(BuildContext context) => Navigator.of(context).pop();

// try excepts a firebase auth function, returns any password and email error messages
Future<(String?, String?)> firebaseAuthErrorCatch(BuildContext context, Function() func, {bool isEmailVerificationSend = false}) async {
  final log = Logger("Firebase auth error catch");
  String? newEmailErrorText;
  String? newPasswordErrorText;

  // first check for internet connection.
  if ((await Connectivity().checkConnectivity()).contains(ConnectivityResult.none)) {
    newEmailErrorText = HIGHLIGHT_RED;
    newPasswordErrorText = NETWORK_ERROR;
  }
  try { // next, run the function.
    await func();
  }
  on FirebaseAuthException catch (e, stackTrace) { // handle possible errors
    if (e.code == "invalid-email" || e.code == "channel-error") {
      log.info("${log.name}: Firebase caught error. Code: ${e.code}", e, stackTrace);
      newEmailErrorText = INVALID_EMAIL;
    }
    else if (e.code == "email-already-in-use") { // for signing up
      log.info("${log.name}: Firebase caught error. Code: ${e.code}", e, stackTrace);
      // We don't tell the user the email is already in use (we pretend no error).
      // This prevents an email enumeration attack.
    }
    else if (e.code == "too-many-requests") {
      log.info("${log.name}: Firebase caught error. Code: ${e.code}", e, stackTrace);
      newEmailErrorText = HIGHLIGHT_RED;
      newPasswordErrorText = SERVERS_BUSY;
    }
    else if (e.code == "user-not-found" || e.code == "wrong-password" || e.code == "invalid-credential") {
      log.info("${log.name}: Firebase caught error. Code: ${e.code}", e, stackTrace);
      newEmailErrorText = HIGHLIGHT_RED; // blank so it will just highlight red
      newPasswordErrorText = INCORRECT_CREDENTIALS;
    }
    else if (e.code == "network-request-failed") {
      log.info("${log.name}: Firebase caught error. Code: ${e.code}", e, stackTrace);
      newEmailErrorText = HIGHLIGHT_RED;
      newPasswordErrorText = NETWORK_ERROR;
    }
    else {
      log.warning("${log.name}: Firebase unknown error. Code: ${e.code}", e, stackTrace);
      newEmailErrorText = HIGHLIGHT_RED;
      newPasswordErrorText = UNKNOWN_ERROR;
    }
  }
  catch (e, stackTrace) { // catch any non-firebase errors
    log.warning("${log.name}: Non-firebase unknown error", e, stackTrace);
    newEmailErrorText = HIGHLIGHT_RED;
    newPasswordErrorText = UNKNOWN_ERROR;
  }

  if (isEmailVerificationSend && newPasswordErrorText != null && context.mounted) {
    // If an email verification message was sent and there's an error, use a toast message instead
    // This is because the error text is "Email not verified", and extra messages are shown through toast
    showToast(
      context,
      NO_VERIFICATION_EMAIL + newPasswordErrorText, 
      Duration(seconds: 3)
    );       
  }

  return (newEmailErrorText, newPasswordErrorText);
}

DateTime lastAction = DateTime(2000); // 1st jan 2000 represents never
void throttledFunc(int throttleTimeMs, Function() func) { // only allow action once every second at most
  if (DateTime.timestamp().difference(lastAction).inMilliseconds >= throttleTimeMs) {
    func();
    lastAction = DateTime.timestamp();
  }
}

void showToast(BuildContext context, String message, Duration duration) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).clearSnackBars();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: duration,
      content: Text(message, textAlign: TextAlign.center),
      behavior: SnackBarBehavior.floating,
      backgroundColor: ColorScheme.of(context).primary,
    ),
    snackBarAnimationStyle: AnimationStyle(
      curve: Curves.fastOutSlowIn,
      duration: Duration(milliseconds: 2000),
      reverseCurve: Curves.easeOut,
      reverseDuration: Duration(milliseconds: 2000)
    )
  );
}
