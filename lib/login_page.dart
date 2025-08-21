import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotebook/constants.dart';
import 'package:quotebook/globals.dart';
import 'package:quotebook/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{
  ErrorCode? emailError; // put here so login() and build() can both access them
  final emailFieldController = TextEditingController();
  final emailFieldKey = GlobalKey<FormFieldState>();

  ErrorCode? passwordError;
  final passwordFieldController = TextEditingController();
  final passwordFieldKey = GlobalKey<FormFieldState>();

  bool obscurePassword = true;

  /// Attempts to send user a password reset email, shows any relevant errors.
  /// 
  /// Some errors are not shown, to prevent an email enumeration attack.
  Future<void> forgotPassword(String email) async {
    final log = Logger("Forgot password function");

    showLoadingIcon(context);

    ErrorCode? newEmailError;
    ErrorCode? newPasswordError;

    // Get user doc, check it exists, and send email if at least an hour has passed since the last password reset
    DocumentReference userDocRef = FirebaseFirestore.instance.collection("users").doc(email);
    await userDocRef.get().then((DocumentSnapshot userDoc) async {
      if (userDoc.exists) { // we only do anything if the given email actually exists
        Map<String, dynamic> userDocData = (await userDocRef.get()).data() as Map<String, dynamic>;
        int minutesSinceLastPasswordResetEmail = DateTime.timestamp().difference(userDocData["last_password_reset_email"].toDate()).inMinutes;
        if (minutesSinceLastPasswordResetEmail >= 60 && mounted) {
          // attempt to send the password reset email, get any error messages
          ErrorCode? error = await firebaseAuthErrorCatch(() async {
            await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
            userDocData["last_password_reset_email"] = DateTime.timestamp();
            await userDocRef.set(userDocData);
          });   
          (newEmailError, newPasswordError) = errorsForFields(error);
        }
      }
    }).catchError((firestoreError) {
      (newEmailError, newPasswordError) = errorsForFields(ErrorCodes.UNKNOWN_ERROR);
      log.severe("${log.name}: Unknown firestore error: $firestoreError");
    }); // catch any errors (ignored for now)

    // if no errors occurred, show success toast
    if (newEmailError == null && newPasswordError == null && mounted) {
      showToast(
        context, 
        "If this account exists, and a password reset didn't take place within the last hour, then a password reset email has been sent.",
        Duration(seconds: 5),
      );
    }

    setState(() { // update error texts
      emailError = newEmailError;
      passwordError = newPasswordError;
    });

    if (mounted) {
      hideLoadingIcon(context);
    }
  }

  /// Attempts to send a user a verification email (if one has not been sent too recently.)
  Future<ErrorCode?> sendEmailVerification(User user) async {
    final log = Logger("Sending email verification");

    ErrorCode? error;

    // get the user doc
    DocumentReference userDocRef = FirebaseFirestore.instance.collection("users").doc(user.email);
    late final Map<String, dynamic> userDocData;
    await userDocRef.get().then((DocumentSnapshot userDocSnapshot) async {
      userDocData = userDocSnapshot.data() as Map<String, dynamic>;
    }).catchError((firestoreError) {
      error = ErrorCodes.UNKNOWN_ERROR;
      log.severe("${log.name}: Unkown firestore error: $firestoreError");
    });
    if (error != null) { // we always return the FIRST error encountered
      return error;
    }

    // check if another verification email has been sent recently (< 3 days is too recent)
    // if a verification email was not sent recently, a new one will be sent
    int hoursSinceLastVerificationEmail = DateTime.timestamp().difference(userDocData["last_verification_email"].toDate()).inHours;
    if (hoursSinceLastVerificationEmail <= 72 && mounted) {
      error = ErrorCodes.VERIFICATION_EMAIL_SENT_RECENTLY;         
    }
    else {
      // send email verification
      error = await firebaseAuthErrorCatch(() async {
        await FirebaseAuth.instance.currentUser!.sendEmailVerification();      
      });
      if (error != null) { // we always return the FIRST error encountered
        return error;
      }

      // set new email timestamp
      userDocData["last_verification_email"] = DateTime.timestamp();
      await userDocRef.set(userDocData).catchError((firestoreError) {
        error = ErrorCodes.UNKNOWN_ERROR;
        log.severe("${log.name}: Unkown firestore error: $firestoreError");
      });                
    }

    return error;
  }

  /// Attempts to sign a user in with the given credentials, shows any relevant errors
  /// 
  /// If user successfully logs in but is not verified, then a verification email is sent
  /// if another wasn't sent too recently.
  Future<void> login(String email, String password) async {
    showLoadingIcon(context);

    ErrorCode? newEmailError; // new error messages (can be null)
    ErrorCode? newPasswordError;

    // Attempt to log the user in
    (newEmailError, newPasswordError) = errorsForFields(
      await firebaseAuthErrorCatch(() async {
        await FirebaseAuth.instance.signOut();
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password
        );
      })
    );

    // if login successful, but email not verified, then send verification email (if not too recent), show any error message and sign out
    if (newEmailError == null && newPasswordError == null && !FirebaseAuth.instance.currentUser!.emailVerified) {
      // this error will be displayed using a snackbar, NOT a form errorText as usual
      ErrorCode? error = await sendEmailVerification(FirebaseAuth.instance.currentUser!);
      newEmailError = ErrorCodes.EMAIL_NOT_VERIFIED;

      if (error != null && mounted) {
        showToast(
          context,
          ErrorCodes.NO_VERIFICATION_EMAIL.errorText + error.errorText, 
          Duration(seconds: 3)
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

    setState(() {
      emailError = newEmailError;
      passwordError = newPasswordError;
    });

    if (mounted) {
      hideLoadingIcon(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextFormField emailField = textFormField(
      emailFieldController, 
      emailFieldKey,
      "Email",
      emailError,
      Icon(Icons.email),
      (String? currentValue) => setState(() {
        emailError = null; 
        passwordError = null;
      }),
      (String? currentValue) {
        if (currentValue == "") {
          return "Please enter an email";
        }
        if (!EmailValidator.validate(emailFieldController.text)) {
          return "Invalid email format";
        }
        else {
          return null;
        }
      },
    );

    final TextFormField passwordField = textFormField(
      passwordFieldController,
      passwordFieldKey,
      "Password",
      passwordError,
      Icon(Icons.lock),
      (String? currentValue) => setState(() {
        emailError = null; 
        passwordError = null;
      }),
      (String? currentValue) {
        if (currentValue == "") {
          return "Please enter a password";
        }
        else {
          return null;
        }
      },
      obscureText: obscurePassword,
      counter: textButton(
        context,
        "Forgot password?",
        () => throttledFunc(2000, () async {
          setState(() {
            emailError = null;
            passwordError = null;
          });
          if (emailFieldKey.currentState!.validate()) {
            await forgotPassword(emailFieldController.text);
          }
        })
      ),
      suffixIcon: Padding(
        padding: const EdgeInsets.all(5),
        child: IconButton.outlined(
          color: ColorScheme.of(context).primary,
          style: IconButton.styleFrom(
            side: BorderSide(
              width: 2.0, 
              color: ColorScheme.of(context).primary,
            ), 
          ),
          icon: obscurePassword ? Icon(Icons.visibility_off) : Icon(Icons.visibility),
          onPressed: () => setState(() => obscurePassword = !obscurePassword)
        ),
      ),
    );

    final ElevatedButton loginButton = elevatedButton(
      context, 
      "Login",
      () => throttledFunc(2000, () async {
        bool emailValid = emailFieldKey.currentState!.validate();
        bool passwordValid = passwordFieldKey.currentState!.validate();
        if (emailValid && passwordValid) {
          await login(emailFieldController.text, passwordFieldController.text);
        }  
      })
    );

    final TextButton signupButton = textButton(
      context, 
      "Sign up",
      () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => Scaffold(body: SignupPage()))
      )
    );

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Log in", style: TextStyle(fontSize: 30)),
          SizedBox(height: 15),
          emailField,
          SizedBox(height: 5),
          passwordField,
          SizedBox(height: 10),
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
          )
        ]
      ),
    );
  }
}
