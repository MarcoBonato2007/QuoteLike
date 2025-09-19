import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:quotelike/utilities/constants.dart';
import 'package:quotelike/utilities/globals.dart';
import 'package:quotelike/utilities/rate_limiting.dart';

// All of these functions perform the named operation and return an ErrorCode? (null if no errors)
// Usually, these are overriden inside the classes they are used in, to show error messages using the context

/// Only call this for logged in users
Future<ErrorCode?> sendEmailVerification(User user) async {
  final log = Logger("sendEmailVerification() in auth_functions.dart");
  showLoadingIcon();

  ErrorCode? error = await RateLimits.VERIFICATION_EMAIL.testCooldown(user.uid);
  error ??= await firebaseErrorHandler(log, () async {
    await FirebaseAuth.instance.currentUser!.sendEmailVerification().timeout(Duration(seconds: 5));
    await logEvent("Send email verification");
  });
  if (error == null) {
    await RateLimits.VERIFICATION_EMAIL.setTimestamp(user.uid);
  }

  hideLoadingIcon();

  return error;
}

Future<ErrorCode?> forgotPassword(String email) async {
  final log = Logger("forgotPassword() in auth_functions.dart");
  showLoadingIcon();
  
  ErrorCode? error = await RateLimits.PASSWORD_RESET_EMAIL.testCooldown(email);
  error ??= await firebaseErrorHandler(log, () async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email).timeout(Duration(seconds: 5));
    await logEvent("Send password reset email");
  });
  if (error == null) {
    await RateLimits.PASSWORD_RESET_EMAIL.setTimestamp(email);
  }

  hideLoadingIcon();

  return error;
}

Future<ErrorCode?> login(String email, String password) async {
  final log = Logger("login() in auth_functions.dart");
  showLoadingIcon();

  // Attempt to log the user in
  // The sign out before is necessary, since the user may be logged into an unverified account already
  ErrorCode? error = await firebaseErrorHandler(log, () async {
    await FirebaseAuth.instance.signOut().timeout(Duration(seconds: 5));
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password
    ).timeout(Duration(seconds: 5));
    await logEvent("Login");
  });

  hideLoadingIcon(); 

  return error;
}

Future<ErrorCode?> signup(String email, String password) async {
  showLoadingIcon();

  final log = Logger("signup() in auth_functions.dart");

  // Create the user in firebase auth
  ErrorCode? error = await firebaseErrorHandler(log, () async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password
    ).timeout(Duration(seconds: 5));
    await logEvent("Signup");
  });

  hideLoadingIcon();

  return error;
}

Future<ErrorCode?> signout() async {
  final log = Logger("Log out button in settings_page.dart");
  showLoadingIcon();

  ErrorCode? error = await firebaseErrorHandler(log, doNetworkCheck: false, () async {
    await FirebaseAuth.instance.signOut().timeout(Duration(seconds: 5));
    await logEvent("Logout");
  });

  hideLoadingIcon();

  return error;
}

/// Only call this for logged in users
Future<ErrorCode?> deleteUser() async {
  final log = Logger("deleteUser() in settings_page.dart");
  showLoadingIcon();

  // Delete all documents in liked quotes subcollection, so as to delete the user doc
  // This also decrements the like count for all quotes the user has liked
  CollectionReference likedQuotesRef = FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser!.uid).collection("liked_quotes");
  CollectionReference quoteCollectionRef = FirebaseFirestore.instance.collection("quotes");
  ErrorCode? error = await firebaseErrorHandler(log, () async {
    await likedQuotesRef.get().timeout(Duration(seconds: 5)).then((QuerySnapshot querySnapshot) async {
      for (DocumentSnapshot doc in querySnapshot.docs) { // for every quote the user has liked,
        await FirebaseFirestore.instance.runTransaction(timeout: Duration(seconds: 5), (transaction) async {
          final quoteDocRef = quoteCollectionRef.doc(doc.id);
          final quoteDocSnapshot = await transaction.get(quoteDocRef);
          transaction.delete(likedQuotesRef.doc(doc.id)); // delete the liked quote doc
          transaction.update( // decrement the number of likes on the document for the quote
            quoteDocRef, 
            {"likes": quoteDocSnapshot["likes"] - 1}
          );
        }).timeout(Duration(seconds: 5));
      }
      await logEvent("Delete liked quotes");
    }).timeout(Duration(seconds: 5));
  });

  error ??= await firebaseErrorHandler(log, () async {
    // Delete the user from firebase auth (this also signs out the user)
    await FirebaseAuth.instance.currentUser!.delete().timeout(Duration(seconds: 5));

    // Delete the uid-based timestamps
    await RateLimits.VERIFICATION_EMAIL.deleteTimestamp(FirebaseAuth.instance.currentUser!.uid);
    await RateLimits.QUOTE_SUGGESTION.deleteTimestamp(FirebaseAuth.instance.currentUser!.uid);
    await RateLimits.EMAIL_CHANGE.deleteTimestamp(FirebaseAuth.instance.currentUser!.uid);
    
    await logEvent("Delete user from auth");
  });

  hideLoadingIcon();

  return error;
}

/// Only call this for logged in users
Future<ErrorCode?> changeEmail(String newEmail) async {
  final log = Logger("changeEmail() in auth_functions.dart");
  showLoadingIcon();

  ErrorCode? error = await RateLimits.EMAIL_CHANGE.testCooldown(FirebaseAuth.instance.currentUser!.uid);
  error ??= await firebaseErrorHandler(log, () async {
    await FirebaseAuth.instance.currentUser!.verifyBeforeUpdateEmail(newEmail).timeout(Duration(seconds: 5));
    await logEvent("Send email change email");
  });
  if (error == null) {
    await RateLimits.EMAIL_CHANGE.setTimestamp(FirebaseAuth.instance.currentUser!.uid);
  }

  hideLoadingIcon();

  return error;
}
