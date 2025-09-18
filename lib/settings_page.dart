import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quotelike/utilities/auth_functions.dart' as auth_functions;
import 'package:quotelike/utilities/constants.dart';
import 'package:quotelike/utilities/globals.dart';
import 'package:quotelike/widgets/standard_widgets.dart';
import 'package:quotelike/utilities/theme_settings.dart';
import 'package:quotelike/widgets/validated_form.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final emailFormKey = GlobalKey<ValidatedFormState>(); // used when inputting an email to change to
  final emailField = EmailField("New email");

  /// This is used instead of auth_functions.signout()
  Future<void> signout() async {
    ErrorCode? error = await auth_functions.signout();

    Navigator.of(navigatorKey.currentContext!).pop(); // remove confirmation dialog

    if (error != null) {
      showToast(navigatorKey.currentContext!, error.errorText, Duration(seconds: 3));
    }     
  }

  /// This is used instead of auth_functions.deleteUser()
  Future<void> deleteUser() async {
    ErrorCode? error = await auth_functions.deleteUser();

    Navigator.of(navigatorKey.currentContext!).pop(); // remove confirmation dialog     

    if (error != null) {
      showToast(
        navigatorKey.currentContext!, // we use navigator key since the context may have changed (possible screen swap)
        ErrorCodes.FAILED_ACCOUNT_DELETION.errorText + error.errorText, 
        Duration(seconds: 5)
      );
    }
    else {
      showToast(
        navigatorKey.currentContext!, // we use navigator key since the context may have changed (possible screen swap)
        "Account deleted successfully", 
        Duration(seconds: 5)
      );  
    }
  }

  /// This is used instead of auth_functions.forgotPassword()
  Future<void> forgotPassword() async {
    ErrorCode? error = await auth_functions.forgotPassword(FirebaseAuth.instance.currentUser!.email!);

    if (error == null && mounted) {
      showToast(
        context, 
        "A password reset email has been sent.",
        Duration(seconds: 5),
      );
    }
    else if (error != null && mounted) {
      showToast(
        context, 
        error.errorText,
        Duration(seconds: 5),
      ); 
    }

    if (mounted) {
      Navigator.of(context).pop(); // remove confirmation dialog
    }
  }

  /// This is used instead of auth_functions.changeEmail()
  Future<void> changeEmail(String newEmail) async {
    ErrorCode? error = await auth_functions.changeEmail(newEmail);

    if (error == null && mounted) {
      showToast(
        context, 
        "Check the inbox of $newEmail for a verification email. You may need to log out and back in.",
        Duration(seconds: 5),
      );
    }
    else if (error != null && mounted) {
      showToast(
        context, 
        error.errorText,
        Duration(seconds: 5),
      ); 
    }

    if (mounted) {
      Navigator.of(context).pop(); // remove confirmation dialog
    }
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
        StandardSettingsButton("Change email", Icon(Icons.email), () => showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            contentPadding: EdgeInsets.only(left: 24, right: 24, top: 24),
            actionsPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Confirm email change",
                  textAlign: TextAlign.center
                ),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: const <TextSpan>[
                      TextSpan(text: 'Warning: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'Maximum 1 email change / day. Make sure the email is spelled correctly.'),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: ValidatedForm(
                    key: emailFormKey,
                    [emailField],
                  ),
                )
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              BackButton(),
              StandardElevatedButton(
                "Change email", 
                () async {
                  emailFormKey.currentState!.removeErrors();
                  if (emailFormKey.currentState!.validate(emailField.id)) {
                    await changeEmail(emailFormKey.currentState!.text(emailField.id));
                  }
                }
              )
            ]
          )
        )),
        StandardSettingsButton("Forgot/reset password", Icon(Icons.key), () => showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Confirm password reset",
                  textAlign: TextAlign.center
                ),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: const <TextSpan>[
                      TextSpan(text: 'Warning: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'Maximum once per day'),
                    ],
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              BackButton(),
              StandardElevatedButton(
                "Reset password", 
                () async => await forgotPassword()
              )
            ]
          )
        )),
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
              StandardElevatedButton(
                "Log out", 
                () async => await signout()
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
                () async => await deleteUser()
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
