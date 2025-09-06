// on delete user, make sure to delete their document entry in the firestore

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotebook/constants.dart';
import 'package:quotebook/globals.dart';
import 'package:quotebook/standard_widgets.dart';
import 'package:quotebook/theme_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// deletes currently logged in user, returns an error code
  Future<ErrorCode?> deleteUser(BuildContext context) async {
    showLoadingIcon();

    final log = Logger("Deleting account");

    ErrorCode? error;

    // Remove user entry from firebase
    DocumentReference userDocRef = FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser!.email);
    error = await firebaseErrorHandler(log, () async {
      await userDocRef.delete().timeout(Duration(seconds: 5));
    });
    if (error != null) { // we always return the FIRST error encountered
      return error;
    }
    
    error = await firebaseErrorHandler(log, () async {
      // This also signs out the user
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
                  final log = Logger("Logging out");
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
                      navigatorKey.currentContext!, 
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
