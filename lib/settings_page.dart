// on delete user, make sure to delete their document entry in the firestore

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotebook/constants.dart';
import 'package:quotebook/globals.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  /// Standardizes the style for a settings button used in the settings page
  Widget settingsButton(String text, Icon icon, Function() onPressed) {
    ElevatedButton mainButton = ElevatedButton.icon(
      label: Text(text),
      icon: icon,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10)) 
      ),
      onPressed: onPressed
    );

    return Row(children: [Expanded(child: mainButton)]);
  }
  
  /// deletes currently logged in user, returns an error code
  Future<ErrorCode?> deleteUser(BuildContext context) async {
    showLoadingIcon(context);

    final log = Logger("Deleting account");

    ErrorCode? error;

    // Remove user entry from firebase
    DocumentReference userDocRef = FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser!.email);
    await userDocRef.delete().timeout(Duration(seconds: 5))
    .catchError((firestoreError) {
      error = firestoreErrorHandler(log, firestoreError);
    });
    
    if (error != null) { // we always return the FIRST error encountered
      return error;
    }
    
    error = await firebaseAuthErrorCatch(() async {
      await FirebaseAuth.instance.currentUser!.delete().timeout(Duration(seconds: 5));
    });

    if (context.mounted) {
      hideLoadingIcon(context);
      Navigator.of(context).pop(); // remove confirmation dialog     
    }

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
        settingsButton("Log out", Icon(Icons.logout), () async {
          showLoadingIcon(context);
          ErrorCode? error = await firebaseAuthErrorCatch(() async => await FirebaseAuth.instance.signOut().timeout(Duration(seconds: 5)));
          if (context.mounted) {
            hideLoadingIcon(context);
          }
          if (error != null && context.mounted) {
            showToast(context, error.errorText, Duration(seconds: 3));
          }
        }),
        settingsButton("Delete account", Icon(Icons.delete), () => showDialog( // show confirmation dialog
          context: context,
          builder: (BuildContext context) => AlertDialog(
            content: Text("Are you sure you want to delete your account? This is non-reversible."),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              BackButton( // back button
                onPressed: () => Navigator.of(context).pop()  
              ),
              elevatedButton( // add back button
                context, 
                "Delete account", 
                () async {
                  ErrorCode? error = await deleteUser(context);
                  if (error != null && context.mounted) {
                    showToast(
                      context, 
                      ErrorCodes.FAILED_ACCOUNT_DELETION.errorText + error.errorText, 
                      Duration(seconds: 5)
                    );
                  }
                }
              )
            ]
          )
        )),
        settingsButton("Privacy policy", Icon(Icons.privacy_tip), () {}), // TODO: add a privacy policy popup
        settingsButton("Swap color theme", Icon(Icons.light_mode), () {}), // TODO: make it work, change icon depending on theme
      ]
    );
  }
}
