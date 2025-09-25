import 'dart:async';

import 'package:flutter/material.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:logging/logging.dart';

import 'package:quotelike/utilities/enums.dart';

// This file contains global functions and variablesused in various files

/// This is used to access the new context after a login/logout (since that causes a screen switch)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// We maintain a local copy of the list of liked quotes.
/// This avoids having to constantly re-fetch this from the server.
/// 
/// This is initialized in explore_page.dart, and updated in quote_card.dart
Set<String> likedQuotes = {};

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

/// Log an event in Firebase analytics
Future<void> logEvent(Event event) async {
  final log = Logger("logCustomevent() in globals.dart");

  // we don't tell the user about any errors here
  // instead we log failures to crashlytics
  await firebaseErrorHandler(log, useCrashlytics: true, () async {
    await switch (event) {
      Event.LOGIN => FirebaseAnalytics.instance.logLogin(
        parameters: {
          "uid": FirebaseAuth.instance.currentUser?.uid ?? "null",
          "email": FirebaseAuth.instance.currentUser?.email ?? "null"
        }
      ),
      Event.SIGN_UP => FirebaseAnalytics.instance.logSignUp(
        signUpMethod: "Email & Password",
        parameters: {
          "uid": FirebaseAuth.instance.currentUser?.uid ?? "null",
          "email": FirebaseAuth.instance.currentUser?.email ?? "null"
        }
      ),
      Event.APP_OPEN => FirebaseAnalytics.instance.logAppOpen(
        parameters: {
          "uid": FirebaseAuth.instance.currentUser?.uid ?? "null",
          "email": FirebaseAuth.instance.currentUser?.email ?? "null"
        }
      ),
      _ => FirebaseAnalytics.instance.logEvent(
        name: event.eventName, 
        parameters: {
          "uid": FirebaseAuth.instance.currentUser?.uid ?? "null",
          "email": FirebaseAuth.instance.currentUser?.email ?? "null"
        }
      )
    }.timeout(Duration(seconds: 5));
  });
}

Future<void> logErrorInCrashlytics(dynamic error, dynamic stackTrace, ErrorCode? errorCode, Logger log) async {
  try {
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: '${log.name}: Error logged with crashlytics: $errorCode. ${error?.code == null ? "Not firebase error" : "Firebase code: ${error.code}"}',
    );
  }
  catch (e, stackTrace) {
    log.warning("${log.name}: Crashlytics failed", e, stackTrace);
  }
}

/// try excepts a function using firebase in some way, returns an error message (see enums.dart)
Future<ErrorCode?> firebaseErrorHandler(Logger log, Function() firebaseFunc, {bool doNetworkCheck = true, bool useCrashlytics = false}) async {
  ErrorCode? errorCode;
  dynamic error, stack;

  // first check for internet connection.
  if (doNetworkCheck && (await Connectivity().checkConnectivity()).contains(ConnectivityResult.none)) {
    errorCode = ErrorCode.NETWORK_ERROR;
    return errorCode;
  }

  try { // next, run the function.
    await firebaseFunc();
  }
  on FirebaseException catch (e, stackTrace) { // handle possible errors
    error = e;
    stack = stackTrace;

    errorCode = switch (e.code) {
      "invalid-email" || "channel-error" => ErrorCode.INVALID_EMAIL,
      "email-already-in-use" => ErrorCode.EMAIL_ALREADY_IN_USE,
      "too-many-requests" => ErrorCode.SERVERS_BUSY,
      "user-not-found" || "wrong-password" || "invalid-credential" => ErrorCode.INCORRECT_CREDENTIALS,
      "network-request-failed" => ErrorCode.NETWORK_ERROR,
      "requires-recent-login" || "user-token-expired" => ErrorCode.REQUIRES_RECENT_LOGIN,
      _ => ErrorCode.UNKNOWN_ERROR
    };
    print(e);
    log.warning("${log.name}: Firebase unknown error. Code: ${e.code}", e, stackTrace);
  }
  on TimeoutException catch (e, stackTrace) {
    error = e;
    stack = stackTrace;
    log.info("${log.name}: Timeout caught error.", e, stackTrace);
    errorCode = ErrorCode.TIMEOUT;
  }
  catch (e, stackTrace) { // catch any non-firebase errors
    error = e;
    stack = stackTrace;
    log.warning("${log.name}: Non-firebase unknown error", e, stackTrace);
    errorCode = ErrorCode.UNKNOWN_ERROR;  
  }

  if (useCrashlytics && error != null) {
    await logErrorInCrashlytics(error, stack, errorCode, log);
  }

  return errorCode;
}

/// convert an error from firebaseErrorHandler() into errors for an email and password field
(ErrorCode?, ErrorCode?) errorsForFields(ErrorCode? error) {
  ErrorCode? emailError, passwordError;
  
  if (error == ErrorCode.INVALID_EMAIL || error == ErrorCode.EMAIL_NOT_VERIFIED) {
    emailError = error; // in this case, only the email field gets an error
  }
  else if (error != null) {
    // otherwise, the email field is highlighted and error is shown in password filed
    emailError = ErrorCode.HIGHLIGHT_RED;
    passwordError = error;
  }

  return (emailError, passwordError);
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
