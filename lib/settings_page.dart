import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotelike/constants.dart';
import 'package:quotelike/globals.dart';
import 'package:quotelike/rate_limiting.dart';
import 'package:quotelike/standard_widgets.dart';
import 'package:quotelike/theme_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// deletes currently logged in user, returns an error code
  Future<ErrorCode?> deleteUser(BuildContext context) async {
    final log = Logger("deleteUser() in settings_page.dart");
    showLoadingIcon();

    // Clear verification and password reset email timestamps
    // So that the user can recreate this account if they want to
    await RateLimits.VERIFICATION_EMAIL.setTimestamp(FirebaseAuth.instance.currentUser!.email!, reset: true);
    await RateLimits.PASSWORD_RESET_EMAIL.setTimestamp(FirebaseAuth.instance.currentUser!.email!, reset: true);

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
      }).timeout(Duration(seconds: 5));
    });

    error ??= await firebaseErrorHandler(log, () async {
      // Delete the user from firebase auth (this also signs out the user)
      await FirebaseAuth.instance.currentUser!.delete().timeout(Duration(seconds: 5));
    });

    hideLoadingIcon();
    Navigator.of(navigatorKey.currentContext!).pop(); // remove confirmation dialog     

    return error;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: TextFormField(
            initialValue: FirebaseAuth.instance.currentUser!.email!,
            readOnly: true,
            autofocus: false,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              label: Text("Email address"),
            ),
          )
        ),
        SizedBox(height: 5),
        StandardSettingsButton("Log out", Icon(Icons.logout), () => showDialog( // show confirmation dialog
          context: context,
          builder: (BuildContext context) => AlertDialog(
            content: Text(
              "Are you sure you want to log out?",
              textAlign: TextAlign.center
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              BackButton(),
              StandardElevatedButton( // add back button
                "Log out", 
                () async {
                  final log = Logger("Log out button in settings_page.dart");
                  showLoadingIcon();
                  ErrorCode? error = await firebaseErrorHandler(log, doNetworkCheck: false, () async {
                    await FirebaseAuth.instance.signOut().timeout(Duration(seconds: 5));
                  });
                  hideLoadingIcon();
                  Navigator.of(navigatorKey.currentContext!).pop(); // remove confirmation dialog
                  if (error != null) {
                    showToast(navigatorKey.currentContext!, error.errorText, Duration(seconds: 3));
                  }                  
                }
              )
            ]
          )
        )),
        StandardSettingsButton("Delete account", Icon(Icons.delete), () => showDialog( // show confirmation dialog
          context: context,
          builder: (BuildContext context) => AlertDialog(
            content: Text(
              "Are you sure you want to delete your account? This is non-reversible.",
              textAlign: TextAlign.center
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              BackButton(),
              StandardElevatedButton( // add back button
                "Delete account", 
                () async {
                  ErrorCode? error = await deleteUser(context);
                  if (error != null) {
                    showToast(
                      navigatorKey.currentContext!, // we use navigator key since the context may have changed (possible screen swap)
                      ErrorCodes.FAILED_ACCOUNT_DELETION.errorText + error.errorText, 
                      Duration(seconds: 5)
                    );
                  }
                }
              )
            ]
          )
        )),
        StandardSettingsButton("Privacy policy", Icon(Icons.privacy_tip), () => showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            content: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Text(
                  PRIVACY_POLICY,
                  textAlign: TextAlign.center
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.start,
            actions: [
              BackButton()
            ]
          )
        )),
        SwapThemeButton()
      ]
    );
  }
}
