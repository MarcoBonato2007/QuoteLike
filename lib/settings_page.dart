import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:quotelike/utilities/auth_functions.dart' as auth_functions;
import 'package:quotelike/utilities/enums.dart';
import 'package:quotelike/utilities/globals.dart';
import 'package:quotelike/utilities/theme_settings.dart';
import 'package:quotelike/widgets/about_buttons.dart';
import 'package:quotelike/widgets/validated_form.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _emailFormKey = GlobalKey<ValidatedFormState>(); // used when inputting an email to change to
  final _emailField = EmailField("New email");

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
        ErrorCode.FAILED_ACCOUNT_DELETION.errorText + error.errorText, 
        Duration(seconds: 4)
      );
    }
    else {
      showToast(
        navigatorKey.currentContext!, // we use navigator key since the context may have changed (possible screen swap)
        "Account deleted successfully", 
        Duration(seconds: 3)
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
        Duration(seconds: 3),
      );
    }
    else if (error != null && mounted) {
      showToast(
        context, 
        error.errorText,
        Duration(seconds: 3),
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

  void showConfirmationDialog(String title, FilledButton confirmButton, {Widget? body, String? warningText}) => showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title, textAlign: TextAlign.center),
      titlePadding: EdgeInsetsGeometry.only(left: 24, right: 24, top: 24),
      contentPadding: EdgeInsets.only(left: 24, right: 24, top: 5),
      actionsPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          warningText != null ? RichText( // show warning text
            textAlign: TextAlign.center,
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: <TextSpan>[
                TextSpan(text: 'Warning: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: warningText),
              ],
            ),
          ) : SizedBox.shrink(),
          SizedBox(height: 15),
          body ?? SizedBox.shrink()
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        BackButton(),
        confirmButton
      ]  
    )
  );

  @override
  Widget build(BuildContext context) {
    Widget changeEmailButton = ElevatedButton.icon(label: Text("Change email"), icon: Icon(Icons.email), onPressed: () => showConfirmationDialog(
      "Confirm email change",
      FilledButton(
        child: Text("Change email"), 
        onPressed: () async {
          _emailFormKey.currentState!.removeErrors();
          if (_emailFormKey.currentState!.validate(_emailField.id)) {
            await changeEmail(_emailFormKey.currentState!.text(_emailField.id));
          }
        }
      ),
      warningText: "Maximum 1 email change / day. Make sure the email is spelled correctly.",
      body: ValidatedForm(
        key: _emailFormKey,
        [_emailField],
      ),
    ));

    Widget resetPasswordButton = ElevatedButton.icon(label: Text("Forgot/reset password"), icon: Icon(Icons.key), onPressed: () => showConfirmationDialog(
      "Confirm password reset",
      FilledButton(child: Text("Reset password"), onPressed: () async => await forgotPassword()),
      warningText: 'Maximum once per hour'
    ));

    Widget logoutButton = ElevatedButton.icon(label: Text("Log out"), icon: Icon(Icons.logout), onPressed: () => showConfirmationDialog( // show confirmation dialog
      "Confirm log out",
      FilledButton(child: Text("Log out"), onPressed: () async => await signout())          
    ));

    Widget deleteAccountButton = ElevatedButton.icon(label: Text("Delete account"), icon: Icon(Icons.delete), onPressed: () => showConfirmationDialog( // show confirmation dialog
      "Confirm account deletion",
      FilledButton(child: Text("Delete account"), onPressed: () async => await deleteUser()),
      warningText: "This is non-reversible"
    ));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center( // a read-only text form field showing the user's email
          child: TextFormField(
            initialValue: FirebaseAuth.instance.currentUser!.email!,
            readOnly: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              label: Text("Email address"),
            ),
          )
        ),
        SizedBox(height: 5),
        changeEmailButton,
        resetPasswordButton,
        logoutButton,
        deleteAccountButton,
        SwapThemeButton(),
        PrivacyPolicyButton(),
        AboutButton()
      ]
    );
  }
}
