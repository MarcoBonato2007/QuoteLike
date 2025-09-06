import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotebook/constants.dart';
import 'package:quotebook/globals.dart';
import 'package:quotebook/signup_page.dart';
import 'package:quotebook/standard_widgets.dart';
import 'package:quotebook/theme_settings.dart';
import 'package:quotebook/validated_form.dart';

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

  Future<ErrorCode?> sendPasswordResetEmail(String email) async {
    final log = Logger("Sending password reset email");
    ErrorCode? error;
    
    error = await firebaseErrorHandler(log, () async {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email).timeout(Duration(seconds: 5));
    });   
    if (error != null) { // we always return the FIRST error encountered
      return error;
    }

    DocumentReference userDocRef = FirebaseFirestore.instance.collection("users").doc(email);
    error = await firebaseErrorHandler(log, () async {
      await userDocRef.update({
        "last_password_reset_email": DateTime.timestamp()
      }).timeout(Duration(seconds: 5));
    });
    
    return error;
  }

  /// Attempts to send user a password reset email, shows any relevant errors.
  /// 
  /// Some errors are not shown, to prevent an email enumeration attack.
  Future<ErrorCode?> forgotPassword(String email) async {
    final log = Logger("Forgot password function");

    ErrorCode? error;
    
    bool tooRecent = true;
    error = await firebaseErrorHandler(log, () async {
      // Get user doc, check it exists, and send email if at least an hour has passed since the last password reset
      DocumentReference userDocRef = FirebaseFirestore.instance.collection("users").doc(email);
      await userDocRef.get().then((DocumentSnapshot userDoc) async {
        if (userDoc.exists) { // we only do anything if the given email actually exists
          int minutesSinceLastPasswordResetEmail = DateTime.timestamp().difference(userDoc["last_password_reset_email"].toDate()).inMinutes;
          if (minutesSinceLastPasswordResetEmail >= 60 && mounted) {
            tooRecent = false;
          }
        }
      }).timeout(Duration(seconds: 5));
    });
    if (error != null) {
      return error;
    }

    if (!tooRecent) {
      error = await sendPasswordResetEmail(email);
    }
    else {
      // we don't let the user know if a reset email was already sent recently.
      // This prevents an email enumeration attack.
    }

    return error;
  }

  /// Attempts to send a user a verification email (if one has not been sent too recently.)
  Future<ErrorCode?> sendEmailVerification(User user) async {
    final log = Logger("Sending email verification");
    ErrorCode? error;

    // Check if a verification email was already sent recently
    bool tooRecent = true;
    DocumentReference userDocRef = FirebaseFirestore.instance.collection("users").doc(user.email);
    error = await firebaseErrorHandler(log, () async {
      await userDocRef.get().then((DocumentSnapshot userDoc) async {
        int hoursSinceLastVerificationEmail = DateTime.timestamp().difference(userDoc["last_verification_email"].toDate()).inHours;
        if (hoursSinceLastVerificationEmail >= 72) {
          tooRecent = false;
        }
      }).timeout(Duration(seconds: 5));
    });
    if (error != null) { // we always return the FIRST error encountered
      return error;
    }

    if (tooRecent) {
      error = ErrorCodes.VERIFICATION_EMAIL_SENT_RECENTLY;         
    }
    else {
      // send email verification
      error = await firebaseErrorHandler(log, () async {
        await FirebaseAuth.instance.currentUser!.sendEmailVerification().timeout(Duration(seconds: 5));      
      });
      if (error != null) { // we always return the FIRST error encountered
        return error;
      }

      // set new verificationemail timestamp
      error = await firebaseErrorHandler(log, () async {
        await userDocRef.update({
          "last_verification_email": DateTime.timestamp()
        }).timeout(Duration(seconds: 5));
      });
    }

    return error;
  }

  /// Attempts to sign a user in with the given credentials, shows any relevant errors
  /// 
  /// If user successfully logs in but is not verified, then a verification email is sent
  /// if another wasn't sent too recently.
  Future<void> login(String email, String password) async {
    final log = Logger("Login");
    showLoadingIcon();

    ErrorCode? newEmailError;
    ErrorCode? newPasswordError;

    // Attempt to log the user in
    (newEmailError, newPasswordError) = errorsForFields(await firebaseErrorHandler(log, () async {
      await FirebaseAuth.instance.signOut().timeout(Duration(seconds: 5));
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password
      ).timeout(Duration(seconds: 5));
      await FirebaseAnalytics.instance.logLogin().timeout(Duration(seconds: 5));
    }));

    // If an unverified user logged in, tell them to verify / send them a verification email
    if (FirebaseAuth.instance.currentUser != null && !FirebaseAuth.instance.currentUser!.emailVerified) {
      newEmailError = ErrorCodes.EMAIL_NOT_VERIFIED;
      ErrorCode? error = await sendEmailVerification(FirebaseAuth.instance.currentUser!);

      if (error != null && mounted) { // show any errors that came up trying to send email verification
        showToast(
          context,
          ErrorCodes.NO_VERIFICATION_EMAIL.errorText + error.errorText, 
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

    // Set the field errors. The if statement is necessary!
    if (newEmailError != null || newPasswordError != null) {
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
            showLoadingIcon();
            ErrorCode? error = await forgotPassword(loginFormKey.currentState!.text(emailField.id));

            // if no errors occurred, show success toast
            if (error == null && context.mounted) {
              showToast(
                context, 
                "If this account exists, and a password reset didn't take place within the last hour, then a password reset email has been sent.",
                Duration(seconds: 5),
              );
            }

            // set the errors for the email and password fields
            ErrorCode? newEmailError, newPasswordError;
            (newEmailError, newPasswordError) = errorsForFields(error);
            loginFormKey.currentState!.setError(emailField.id, newEmailError);
            loginFormKey.currentState!.setError(passwordField.id, newPasswordError);

            hideLoadingIcon();
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
