import 'package:flutter/material.dart';

import 'package:quotelike/utilities/auth_functions.dart' as auth_functions;
import 'package:quotelike/utilities/enums.dart';
import 'package:quotelike/utilities/globals.dart';
import 'package:quotelike/utilities/rate_limiting.dart';
import 'package:quotelike/utilities/theme_settings.dart';
import 'package:quotelike/widgets/about_buttons.dart';
import 'package:quotelike/widgets/validated_form.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>{
  final _signupFormKey = GlobalKey<ValidatedFormState>();
  final Field _emailField = EmailField("Email");
  late Field _passwordField;
  late Field _passwordConfirmField;

  /// This is used instead of auth_functions.signup()
  Future<void> signup(String email, String password) async {
    ErrorCode? error = await auth_functions.signup(email, password);

    if ((error == null || error == ErrorCode.EMAIL_ALREADY_IN_USE) && mounted) {
      Navigator.of(context).pop(); // return to login page
      showToast(
        context,
        error == null ? "Sign up successful": "Account already exists. Please log in.", 
        Duration(seconds: 3),
      );        
    }
    else {
      // set error messages
      ErrorCode? newEmailError;
      ErrorCode? newPasswordError;
      (newEmailError, newPasswordError) = errorsForFields(error);
      _signupFormKey.currentState!.setError(_emailField.id, newEmailError);
      _signupFormKey.currentState!.setError(_passwordConfirmField.id, newPasswordError);
      if (newEmailError == ErrorCode.HIGHLIGHT_RED) { // If email field highlighted, password field highlighted
        _signupFormKey.currentState!.setError(_passwordField.id, ErrorCode.HIGHLIGHT_RED);
      }      
    }
  }

  @override
  Widget build(BuildContext context) {
    _passwordField = Field(
      "Password",
      Icon(Icons.lock),
      true,
      (String? currentValue) {
        const List<String> specialCharacters = ["^", "\$", "*", ".", "[", "]", "{", "}", "(", ")", "?", '"', "!", "@", "#", "%", "&", "/", "\\", ",", ">", "<", "'", ":", ";", "|", "_", "~"];
        
        if (currentValue == "") {
          return "Please enter a password";
        }
        else if (currentValue!.length < 8) {
          return "Password must be at least 8 characters";
        }
        else if (currentValue.length > 4096) {
          return "Password must be shorter than 4096 characters";
        }
        else if (!RegExp(r'[a-z]').hasMatch(currentValue)) {
          return "Password must contain a lowercase letter";
        }
        else if (!RegExp(r'[A-Z]').hasMatch(currentValue)) {
          return "Password must contain an uppercae letter";
        }
        else if (!RegExp(r'[0-9]').hasMatch(currentValue)) {
          return "Password must contain a digit";
        }
        else if (!specialCharacters.any((String specialCharacter) => currentValue.contains(specialCharacter))) {
          return "Password must contain a special character";
        }
        else {
          return null;
        }
      },
    );

    _passwordConfirmField = Field(
      "Confirm password",
      Icon(Icons.lock),
      true,
      (String? currentValue) {
        if (currentValue == "") {
          return "Please enter a password confirmation";
        }
        else if (currentValue != _signupFormKey.currentState!.text(_passwordField.id)) {
          return "Passwords must match";
        }
        else {
          return null;
        }
      },
    );

    final signupForm = ValidatedForm(
      key: _signupFormKey,
      [
        _emailField,
        _passwordField,
        _passwordConfirmField
      ]
    );

    final signupButton = FilledButton(
      child: Text("Sign up"),
      onPressed: () => throttledFunc(2000, () async {
        if (_signupFormKey.currentState!.validateAll()) {
          await signup(
            _signupFormKey.currentState!.text(_emailField.id), 
            _signupFormKey.currentState!.text(_passwordField.id), 
          );
        }      
      }),
    );

    // this button redirects the user back to the login page
    final loginButton = TextButton(child: Text("Login"), onPressed: () => Navigator.of(context).pop());

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Sign up", style: TextStyle(fontSize: 30), textAlign: TextAlign.center),
          SizedBox(height: 15),
          signupForm,
          SizedBox(height: 5),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: signupButton, 
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Already have an account?"),
              loginButton
            ]
          ),
          SizedBox(height: 8),
          SwapThemeButton(),
          PrivacyPolicyButton(),
          AboutButton()
        ]
      ),
    );
  }
}
