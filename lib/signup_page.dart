import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotelike/constants.dart';
import 'package:quotelike/globals.dart';
import 'package:quotelike/standard_widgets.dart';
import 'package:quotelike/theme_settings.dart';
import 'package:quotelike/validated_form.dart';
import 'package:quotelike/rate_limiting.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>{
  final signupFormKey = GlobalKey<ValidatedFormState>();
  Field emailField = EmailField();
  late Field passwordField;
  late Field passwordConfirmField;

  /// Attempts to create a user with the given details.
  Future<void> signup(String email, String password) async {
    showLoadingIcon();
    ErrorCode? newEmailError;
    ErrorCode? newPasswordError;

    final log = Logger("signup() in signup_page.dart");

    // Create the user in firebase auth
    ErrorCode? error = await firebaseErrorHandler(log, () async {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password
      ).timeout(Duration(seconds: 5));
    });

    // log the event in analytics
    // we don't tell the user about any errors here, since it's non fatal and will be logged anyway
    await firebaseErrorHandler(log, useCrashlytics: true, () async {
      await FirebaseAnalytics.instance.logSignUp(signUpMethod: "Email & Password").timeout(Duration(seconds: 5));
    });

    if ((error == null || error == ErrorCodes.EMAIL_ALREADY_IN_USE) && mounted) {
      Navigator.of(context).pop(); // return to login page
      showToast(
        context,
        error == null ? "Sign up successful": "Account already exists. Please log in.", 
        Duration(seconds: 3),
      );        
    }
    else {
      // set error messages
      (newEmailError, newPasswordError) = errorsForFields(error);
      signupFormKey.currentState!.setError(emailField.id, newEmailError);
      signupFormKey.currentState!.setError(passwordConfirmField.id, newPasswordError);
      if (newEmailError == ErrorCodes.HIGHLIGHT_RED) { // If email field highlighted, password field highlighted
        signupFormKey.currentState!.setError(passwordField.id, ErrorCodes.HIGHLIGHT_RED);
      }      
    }

    hideLoadingIcon();
  }

  @override
  Widget build(BuildContext context) {
    passwordField = Field(
      "Password",
      Icon(Icons.lock),
      true,
      (String? currentValue) {
        List<String> specialCharacters = ["^", "\$", "*", ".", "[", "]", "{", "}", "(", ")", "?", '"', "!", "@", "#", "%", "&", "/", "\\", ",", ">", "<", "'", ":", ";", "|", "_", "~"];
        
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

    passwordConfirmField = Field(
      "Confirm password",
      Icon(Icons.lock),
      true,
      (String? currentValue) {
        if (currentValue == "") {
          return "Please enter a password confirmation";
        }
        else if (currentValue != signupFormKey.currentState!.text(passwordField.id)) {
          return "Passwords must match";
        }
        else {
          return null;
        }
      },
    );

    final signupForm = ValidatedForm(
      key: signupFormKey,
      [
        emailField,
        passwordField,
        passwordConfirmField
      ]
    );

    final signupButton = StandardElevatedButton(
      "Sign up",
      () => throttledFunc(2000, () async {
        if (signupFormKey.currentState!.validateAll()) {
          await signup(
            signupFormKey.currentState!.text(emailField.id), 
            signupFormKey.currentState!.text(passwordField.id), 
          );
        }      
      }),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Sign up", style: TextStyle(fontSize: 30)),
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
              StandardTextButton("Login", () => Navigator.of(context).pop())
            ]
          ),
          SizedBox(height: 5),
          SwapThemeButton()
        ]
      ),
    );
  }
}
