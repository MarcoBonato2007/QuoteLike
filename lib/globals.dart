import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotebook/constants.dart';

// This file contains global functions used in various files

/// This is used to access the new context after a login/logout (since that causes a screen switch)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Shows a non user dismissable CircularProgressIndicator() overlay
void showLoadingIcon() {
  showDialog(
    context: navigatorKey.currentContext!,
    barrierDismissible: false,
    builder: (BuildContext context) => const Center(child: CircularProgressIndicator())
  );
}

/// Same as Navigator.of(context).pop(), used with showLoadingIcon()
void hideLoadingIcon() => Navigator.of(navigatorKey.currentContext!).pop();

/// try excepts a function using firebase in some way, returns an error message (see constants.dart)
Future<ErrorCode?> firebaseErrorHandler(Logger log, Function() firebaseFunc, {bool doNetworkCheck = true, bool useCrashlytics = false}) async {
  ErrorCode? error;
  bool errorLoggedInCrashlytics = false;

  // first check for internet connection.
  if (doNetworkCheck && (await Connectivity().checkConnectivity()).contains(ConnectivityResult.none)) {
    error = ErrorCodes.NETWORK_ERROR;
    return error;
  }

  try { // next, run the function.
    await firebaseFunc();
  }
  on FirebaseException catch (e, stackTrace) { // handle possible errors
    if (e.code == "invalid-email" || e.code == "channel-error") { // channel-error means empty input of some kind
      log.info("${log.name}: Firebase caught error. Code: ${e.code}", e, stackTrace);
      error = ErrorCodes.INVALID_EMAIL;
    }
    else if (e.code == "email-already-in-use") { // for signing up
      error = ErrorCodes.EMAIL_ALREADY_IN_USE;
      log.info("${log.name}: Firebase caught error. Code: ${e.code}", e, stackTrace);
      // Ignore (prevents email enumeration attack)
    }
    else if (e.code == "too-many-requests") {
      log.info("${log.name}: Firebase caught error. Code: ${e.code}", e, stackTrace);
      error = ErrorCodes.SERVERS_BUSY;
    }
    else if (e.code == "user-not-found" || e.code == "wrong-password" || e.code == "invalid-credential") {
      log.info("${log.name}: Firebase caught error. Code: ${e.code}", e, stackTrace);
      error = ErrorCodes.INCORRECT_CREDENTIALS;
    }
    else if (e.code == "network-request-failed") {
      log.info("${log.name}: Firebase caught error. Code: ${e.code}", e, stackTrace);
      error = ErrorCodes.NETWORK_ERROR;
    }
    else if (e.code == "requires-recent-login") {
      log.info("${log.name}: Firebase caught error. Code: ${e.code}", e, stackTrace);
      error = ErrorCodes.REQUIRES_RECENT_LOGIN;
    }
    else {
      log.warning("${log.name}: Firebase unknown error. Code: ${e.code}", e, stackTrace);
      error = ErrorCodes.UNKNOWN_ERROR;
      try {
        await FirebaseCrashlytics.instance.recordError( // we always record unknown errors in crashlytics
          error,
          stackTrace,
          reason: '${log.name}: Unknown firebase error; ${e.code}',
        );
        errorLoggedInCrashlytics = true;        
      }
      catch (e, stackTrace) {
        log.warning("${log.name}: Crashlytics failed", e, stackTrace);
      }
    }
  }
  on TimeoutException catch (e, stackTrace) {
    log.info("${log.name}: Timeout caught error.", e, stackTrace);
    error = ErrorCodes.TIMEOUT;
  }
  catch (e, stackTrace) { // catch any non-firebase errors
    log.warning("${log.name}: Non-firebase unknown error", e, stackTrace);
    error = ErrorCodes.UNKNOWN_ERROR;
    try {
      await FirebaseCrashlytics.instance.recordError( // we always record unknown errors in crashlytics
        error,
        stackTrace,
        reason: '${log.name}: Unknown flutter error',
      );
      errorLoggedInCrashlytics = true;      
    }
    catch (e, stackTrace) {
      log.warning("${log.name}: Crashlytics failed", e, stackTrace);
    }
  }

  if (!errorLoggedInCrashlytics && useCrashlytics && error != null) {
    try {
      await FirebaseCrashlytics.instance.recordError( // we always record unknown errors in crashlytics
        error,
        null,
        reason: '${log.name}: Unknown flutter error',
      );      
    }
    catch (e, stackTrace) {
      log.warning("${log.name}: Crashlytics failed", e, stackTrace);
    }

  }

  return error;
}

/// convert an error from firebaseErrorHandler() into errors for an email and password field
/// 
/// Email already in use is is ignored to prevent an enumeration attack
(ErrorCode?, ErrorCode?) errorsForFields(ErrorCode? error) {
  ErrorCode? emailError, passwordError;
  
  if (error == ErrorCodes.INVALID_EMAIL || error == ErrorCodes.EMAIL_NOT_VERIFIED) {
    emailError = error;
  }
  else if (error != null && error != ErrorCodes.EMAIL_ALREADY_IN_USE) {
    emailError = ErrorCodes.HIGHLIGHT_RED;
    passwordError = error;
  }

  return (emailError, passwordError);
}

DateTime lastAction = DateTime(2000); // 1st jan 2000 represents never
/// Create a function that can only be called throttleTimeMs milliseconds from the last time it was called
void throttledFunc(int throttleTimeMs, Function() func) async {
  if (DateTime.timestamp().difference(lastAction).inMilliseconds >= throttleTimeMs) {
    await func();
    lastAction = DateTime.timestamp();
  }
}

/// Executes a function that takes at least the duration to execute every time, even if it finishes early.
/// 
/// This is usually used to prevent an email enumeration attack (in signup and forgot password)
Future<ErrorCode?> fixedTimeFunc(Logger log, Future<ErrorCode?> Function() func) async {
  final stopwatch = Stopwatch();
  ErrorCode? error;
  stopwatch.start();

  try {
    error = await func().timeout(Duration(seconds: 5));
  }
  on TimeoutException catch (e, stackTrace) {
    log.info("${log.name}: Firebase timeout caught error.", e, stackTrace);
    error = ErrorCodes.TIMEOUT;
  }

  stopwatch.stop();
  final stopwatchDuration = Duration(milliseconds: stopwatch.elapsedMilliseconds);
  if (stopwatchDuration.compareTo(Duration(seconds: 5)) < 0) {
    await Future.delayed(Duration(seconds: 5) - stopwatchDuration);
  }

  return error;
}

/// Shows a popup message on the bottom of the screen
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
