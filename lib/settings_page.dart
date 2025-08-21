// on delete user, make sure to delete their document entry in the firestore

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
          ErrorCode? error = await firebaseAuthErrorCatch(() async => await FirebaseAuth.instance.signOut());
          if (error != null && context.mounted) {
            showToast(context, error.errorText, Duration(seconds: 3));
          }
          if (context.mounted) {hideLoadingIcon(context);}
        }),
        settingsButton("Delete account", Icon(Icons.delete), () => showDialog( // show confirmation dialog
          context: context,
          builder: (BuildContext context) => AlertDialog(
            content: Text("Are you sure you want to delete your account?"),
            actions: [elevatedButton(
              context, 
              "Delete account", 
              () async {
                // TODO: remove entry from firebase first
                // then call delete account
                // use error catching on BOTH, give snackbar error for .catchError
              }
            )]
          )
        )),
        settingsButton("Privacy policy", Icon(Icons.privacy_tip), () {}), // TODO: add a privacy policy popup
        settingsButton("Swap color theme", Icon(Icons.light_mode), () {}), // TODO: make it work, change icon depending on theme
      ]
    );
  }
}
