// on delete user, make sure to delete their document entry in the firestore

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Widget settingsButton(String text, Icon icon) {
    ElevatedButton mainButton = ElevatedButton.icon(
      label: Text(text),
      icon: icon,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10)) 
      ),
      onPressed: () {}
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
        settingsButton("Delete account", Icon(Icons.delete)),
        settingsButton("Log out", Icon(Icons.logout)),
        settingsButton("Privacy policy", Icon(Icons.policy)),
        settingsButton("Light/dark mode", Icon(Icons.light_mode)),
      ]
    );
  }
}

// TODO: make all these actually work
  // delete account, log out, privacy policy, swap light/dark mode
