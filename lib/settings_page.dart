// on delete user, make sure to delete their document entry in the firestore

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:quotebook/constants.dart';
import 'package:quotebook/globals.dart';
import 'package:quotebook/theme_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
    showLoadingIcon();

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
        settingsButton("Log out", Icon(Icons.logout), () => showDialog( // show confirmation dialog
          context: context,
          builder: (BuildContext context) => AlertDialog(
            content: Text(
              "Are you sure you want to log out?",
              textAlign: TextAlign.center
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              BackButton( // back button
                onPressed: () => Navigator.of(context).pop()  
              ),
              elevatedButton( // add back button
                context, 
                "Log out", 
                () async {
                  showLoadingIcon();
                  ErrorCode? error = await firebaseAuthErrorCatch(() async {
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
        settingsButton("Delete account", Icon(Icons.delete), () => showDialog( // show confirmation dialog
          context: context,
          builder: (BuildContext context) => AlertDialog(
            content: Text(
              "Are you sure you want to delete your account? This is non-reversible.",
              textAlign: TextAlign.center
            ),
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
        settingsButton("Privacy policy", Icon(Icons.privacy_tip), () => showDialog(
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
              BackButton( // back button
                onPressed: () => Navigator.of(context).pop()  
              )
            ]
          )
        )),
        settingsButton(
          "Swap color theme", 
          Provider.of<ThemeSettings>(context, listen: false).isColorThemeLight ? Icon(Icons.light_mode) : Icon(Icons.dark_mode), 
          () async {
            showLoadingIcon();
            await Provider.of<ThemeSettings>(context, listen: false).invertColorTheme();
            setState(() {});
            hideLoadingIcon();
          }
        ),
      ]
    );
  }
}
