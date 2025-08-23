import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotebook/constants.dart';
import 'package:quotebook/globals.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>{
  ErrorCode? emailError; // put here so login() and build() can both access them\
  final emailFieldController = TextEditingController();
  final emailFieldKey = GlobalKey<FormFieldState>();

  ErrorCode? passwordError;
  final passwordFieldKey = GlobalKey<FormFieldState>();
  final passwordFieldController = TextEditingController();
  bool obscurePassword = true;

  ErrorCode? passwordConfirmError;
  final passwordConfirmFieldKey = GlobalKey<FormFieldState>();
  final passwordConfirmFieldController = TextEditingController();
  bool obscurePasswordConfirm = true;

  /// Creates a new doc for a new user in the firestore database (users collection), returns an ErrorCode?
  Future<ErrorCode?> createUserDoc(UserCredential userCredential) async {
    final log = Logger("Creating new user doc");

    ErrorCode? error; // contains errors occurred when creating the user doc

    // Create a new user doc in the firestore database
    DocumentReference userDocRef = FirebaseFirestore.instance.collection("users").doc(userCredential.user!.email);
    Map<String, dynamic> userDocData = {
      "last_verification_email": DateTime(2000), // jan 1st 2000 represents never
      "last_password_reset_email": DateTime(2000)
    };
    await userDocRef.get().then((DocumentSnapshot docSnapshot) async {
      await userDocRef.set(userDocData);
      await userDocRef.collection("liked_quotes").doc("placeholder").set({});
    }).timeout(Duration(seconds: 5)).catchError((firestoreError) {
      error = firestoreErrorHandler(log, firestoreError);
    });
    if (error != null) { // we always return the FIRST error encountered
      return error;
    }

    // send the user email verification
    error = await firebaseAuthErrorCatch(() async => await userCredential.user!.sendEmailVerification().timeout(Duration(seconds: 5)));
    if (error != null) {
      return error;
    }

    userDocData["last_verification_email"] = DateTime.timestamp();
    await userDocRef.set(userDocData).timeout(Duration(seconds: 5)).catchError((firestoreError) {
      error = firestoreErrorHandler(log, firestoreError);
    });   
    
    return error;
  }

  /// Attempts to create a user with the given details.
  /// 
  /// The user is not made aware if they are signing up an already existing user.
  /// This is to prevent an email enumeration attack.
  Future<void> signup(String email, String password) async {    
    showLoadingIcon(context);

    // new error messages (can be null)
    ErrorCode? newEmailError;
    ErrorCode? newPasswordError;

    // Attempt to signup the user and get the new user's credential (or get errors)
    UserCredential? newUserCredential;
    (newEmailError, newPasswordError) = errorsForFields(
      await firebaseAuthErrorCatch(() async {
        newUserCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password
        ).timeout(Duration(seconds: 5));
      }) 
    );

    // If a new user has been created, then create their doc in the database
    if (newUserCredential != null) {
      (newEmailError, newPasswordError) = errorsForFields(await createUserDoc(newUserCredential!));
    }
    
    // if no errors from user creation or other, show success toast and return to LoginPage()
    // NOTE: error might be equal to EMAIL_ALREADY_IN_USE, so DO NOT use error == null check below
    if (newEmailError == null && newPasswordError == null && mounted) {
      Navigator.of(context).pop();
      showToast(
        context,
        "Sign up successful (check your inbox for a verification email) or account already exists.", 
        Duration(seconds: 3),
      );        
    }

    // set error messages
    setState(() {
      passwordConfirmError = newPasswordError; // password errors should be displayed on confirm box (since it is lowest)
      emailError = newEmailError;
      if (newEmailError == ErrorCodes.HIGHLIGHT_RED) { // If email field highlighted, password field highlighted
        passwordError = ErrorCodes.HIGHLIGHT_RED;
      }
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
        passwordConfirmError = null;
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
        passwordConfirmError = null;
      }),
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
      obscureText: obscurePassword,
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

    final TextFormField passwordConfirmField = textFormField(
      passwordConfirmFieldController,
      passwordConfirmFieldKey,
      "Confirm password",
      passwordConfirmError,
      Icon(Icons.lock),
      (String? currentValue) => setState(() {
        emailError = null; 
        passwordError = null;
        passwordConfirmError = null;
      }),
      (String? currentValue) {
        if (currentValue == "") {
          return "Please enter a password confirmation";
        }
        else if (currentValue != passwordFieldController.text) {
          return "Passwords must match";
        }
        else {
          return null;
        }
      },
      obscureText: obscurePasswordConfirm,
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
          icon: obscurePasswordConfirm ? Icon(Icons.visibility_off) : Icon(Icons.visibility),
          onPressed: () => setState(() => obscurePasswordConfirm = !obscurePasswordConfirm)
        ),
      ),
    );

    final ElevatedButton signupButton = elevatedButton(
      context,
      "Sign up",
      () => throttledFunc(2000, () async {
        bool emailValid = emailFieldKey.currentState!.validate();
        bool passwordValid = passwordFieldKey.currentState!.validate();
        bool passwordConfirmValid = passwordConfirmFieldKey.currentState!.validate();
        if (emailValid && passwordValid && passwordConfirmValid) {
          await signup(emailFieldController.text, passwordFieldController.text);
        }      
      }),
    );

    final TextButton loginButton = textButton(context, "Login", () => Navigator.of(context).pop());

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Sign up", style: TextStyle(fontSize: 30)),
          SizedBox(height: 15),
          emailField,
          SizedBox(height: 5),
          passwordField,
          SizedBox(height: 5),
          passwordConfirmField,
          SizedBox(height: 10),
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
          )
        ]
      ),
    );
  }
}
