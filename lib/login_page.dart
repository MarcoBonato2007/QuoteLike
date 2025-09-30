import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:quotelike/signup_page.dart';
import 'package:quotelike/utilities/auth_functions.dart' as auth_functions;
import 'package:quotelike/utilities/enums.dart';
import 'package:quotelike/utilities/globals.dart';
import 'package:quotelike/utilities/rate_limiting.dart';
import 'package:quotelike/utilities/theme_settings.dart';
import 'package:quotelike/widgets/about_buttons.dart';
import 'package:quotelike/widgets/validated_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{
  // The key used to access the form containing the email & password fields
  final _loginFormKey = GlobalKey<ValidatedFormState>();
  final Field _emailField = EmailField("Email");
  late Field _passwordField;
  
  /// This is used instead of auth_functions.forgotPassword()
  Future<void> forgotPassword(String email) async {
    ErrorCode? error = await auth_functions.forgotPassword(email);

    if (error == null && mounted) {
      showToast(
        context, 
        "If this account exists, then a password reset email has been sent.",
        Duration(seconds: 5),
      );
    }
    else if (error == RateLimits.PASSWORD_RESET_EMAIL.error && mounted) {
      showToast(
        context, 
        RateLimits.PASSWORD_RESET_EMAIL.error.errorText,
        Duration(seconds: 5),
      ); 
    }
    else if (mounted) {
      // set the errors for the email and password fields
      ErrorCode? newEmailError, newPasswordError;
      (newEmailError, newPasswordError) = errorsForFields(error);
      _loginFormKey.currentState!.setError(_emailField.id, newEmailError);
      _loginFormKey.currentState!.setError(_passwordField.id, newPasswordError);      
    }
  }

  /// This is used instead of auth_functions.login()
  Future<void> login(String email, String password) async {
    ErrorCode? error = await auth_functions.login(email, password);

    ErrorCode? newEmailError;
    ErrorCode? newPasswordError;
    (newEmailError, newPasswordError) = errorsForFields(error);
    
    // if an unverified user logged in without errors, then tell them they're not verified and send verification
    if (newEmailError == null && newPasswordError == null && FirebaseAuth.instance.currentUser != null && !FirebaseAuth.instance.currentUser!.emailVerified) {
      newEmailError = ErrorCode.EMAIL_NOT_VERIFIED;
      ErrorCode? verificationError = await auth_functions.sendEmailVerification(FirebaseAuth.instance.currentUser!);

      if (verificationError != null && mounted) { // show any errors that came up trying to send email verification
        showToast(
          context,
          ErrorCode.NO_VERIFICATION_EMAIL.errorText + verificationError.errorText, 
          Duration(seconds: 5)
        );       
      }
      else if (mounted) {
        showToast(
          context, 
          "A new verification email has been sent. Check your inbox.",
          Duration(seconds: 3)
        );   
      }   
    }

    // if a verified user logged in, there is a screen swap and current state is now invalid
    // so this if statement is needed
    if (mounted) {
      _loginFormKey.currentState!.setError(_emailField.id, newEmailError);
      _loginFormKey.currentState!.setError(_passwordField.id, newPasswordError);     
    }
  }

  @override
  Widget build(BuildContext context) {
    _passwordField = Field(
      "Password",
      Icon(Icons.lock),
      true,
      (String? currentValue) {
        if (currentValue == "" || currentValue == null) {
          return "Please enter a password";
        }
        else {
          return null;
        }
      },
      counter: TextButton(
        child: Text("Forgot password?"),
        onPressed: () => throttledFunc(2000, () async {
          _loginFormKey.currentState!.removeErrors();
          if (_loginFormKey.currentState!.validate(_emailField.id)) {
            await forgotPassword(_loginFormKey.currentState!.text(_emailField.id));
          }
        })
      ),
    );

    final loginForm = ValidatedForm(
      key: _loginFormKey, 
      [
        _emailField,
        _passwordField
      ]
    );

    final loginButton = FilledButton(
      child: Text("Login"),
      onPressed: () => throttledFunc(2000, () async {
        if (_loginFormKey.currentState!.validateAll()) {
          await login(
            _loginFormKey.currentState!.text(_emailField.id), 
            _loginFormKey.currentState!.text(_passwordField.id)
          );
        }  
      })
    );

    final signupButton = TextButton( // This button redirects the user to the signup page
      child: Text("Sign up"),
      onPressed: () {
        _loginFormKey.currentState!.removeErrors();
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => Scaffold(body: SignupPage()))
        );
      }
    );

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Log in", style: TextStyle(fontSize: 30), textAlign: TextAlign.center),
          SizedBox(height: 15),
          loginForm,
          SizedBox(height: 5),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: loginButton, 
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account?"),
              signupButton
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
