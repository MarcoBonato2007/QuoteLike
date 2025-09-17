import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotelike/constants.dart';
import 'package:quotelike/globals.dart';
import 'package:quotelike/signup_page.dart';
import 'package:quotelike/standard_widgets.dart';
import 'package:quotelike/theme_settings.dart';
import 'package:quotelike/validated_form.dart';
import 'package:quotelike/rate_limiting.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{
  // The key used to access the form containing the email & password fields
  final loginFormKey = GlobalKey<ValidatedFormState>();
  Field emailField = EmailField();
  late Field passwordField;

  /// Attempts to send user a password reset email, shows any relevant errors.
  Future<void> forgotPassword(String email) async {
    final log = Logger("forgotPassword() in login_page.dart");
    showLoadingIcon();
    
    ErrorCode? error = await RateLimits.PASSWORD_RESET_EMAIL.testCooldown(email);
    error ??= await firebaseErrorHandler(log, () async {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email).timeout(Duration(seconds: 5));
    });
    if (error == null) {
      await RateLimits.PASSWORD_RESET_EMAIL.setTimestamp(email);
    }

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
      loginFormKey.currentState!.setError(emailField.id, newEmailError);
      loginFormKey.currentState!.setError(passwordField.id, newPasswordError);      
    }

    hideLoadingIcon();
  }

  /// Attempts to send a user a verification email (if one has not been sent too recently.)
  Future<ErrorCode?> sendEmailVerification(User user) async {
    final log = Logger("sendEmailVerification() in login_page.dart");
    ErrorCode? error = await RateLimits.VERIFICATION_EMAIL.testCooldown(user.email!);
    error ??= await firebaseErrorHandler(log, () async {
      await FirebaseAuth.instance.currentUser!.sendEmailVerification().timeout(Duration(seconds: 5));
    });
    if (error == null) {
      await RateLimits.VERIFICATION_EMAIL.setTimestamp(user.email!);
    }

    return error;
  }

  /// Attempts to sign a user in with the given credentials, shows any relevant errors
  /// 
  /// If user successfully logs in but is not verified, then a verification email is sent
  /// if another wasn't sent too recently.
  Future<void> login(String email, String password) async {
    final log = Logger("login() in login_page.dart");
    showLoadingIcon();

    ErrorCode? newEmailError;
    ErrorCode? newPasswordError;

    // Attempt to log the user in
    // The sign out before is necessary, since the user may be logged into an unverified account already
    (newEmailError, newPasswordError) = errorsForFields(await firebaseErrorHandler(log, () async {
      await FirebaseAuth.instance.signOut().timeout(Duration(seconds: 5));
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password
      ).timeout(Duration(seconds: 5));
    }));

    // log the event in analytics
    // we don't tell the user about any errors here, since it's non fatal and will be logged anyway
    await firebaseErrorHandler(log, useCrashlytics: true, () async {
      await FirebaseAnalytics.instance.logLogin().timeout(Duration(seconds: 5));
    });
    
    // if an unverified user logged in without errors, then tell them they're not verified and send verification
    if (newEmailError == null && newPasswordError == null && FirebaseAuth.instance.currentUser != null && !FirebaseAuth.instance.currentUser!.emailVerified) {
      newEmailError = ErrorCodes.EMAIL_NOT_VERIFIED;
      ErrorCode? verificationError = await sendEmailVerification(FirebaseAuth.instance.currentUser!);

      if (verificationError != null && mounted) { // show any errors that came up trying to send email verification
        showToast(
          context,
          ErrorCodes.NO_VERIFICATION_EMAIL.errorText + verificationError.errorText, 
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
      loginFormKey.currentState!.setError(emailField.id, newEmailError);
      loginFormKey.currentState!.setError(passwordField.id, newPasswordError);     
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
        if (currentValue == "" || currentValue == null) {
          return "Please enter a password";
        }
        else {
          return null;
        }
      },
      counter: StandardTextButton(
        "Forgot password?",
        () => throttledFunc(2000, () async {
          loginFormKey.currentState!.removeErrors();
          if (loginFormKey.currentState!.validate(emailField.id)) {
            await forgotPassword(loginFormKey.currentState!.text(emailField.id));
          }
        })
      ),
    );

    final loginForm = ValidatedForm(
      key: loginFormKey, 
      [
        emailField,
        passwordField
      ]
    );

    final loginButton = StandardElevatedButton(
      "Login",
      () => throttledFunc(2000, () async {
        if (loginFormKey.currentState!.validateAll()) {
          await login(
            loginFormKey.currentState!.text(emailField.id), 
            loginFormKey.currentState!.text(passwordField.id)
          );
        }  
      })
    );

    final signupButton = StandardTextButton(
      "Sign up",
      () {
        loginFormKey.currentState!.removeErrors();
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => Scaffold(body: SignupPage()))
        );
      }
    );

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Log in", style: TextStyle(fontSize: 30)),
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
          SizedBox(height: 5),
          SwapThemeButton()
        ]
      ),
    );
  }
}
