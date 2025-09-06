import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotebook/constants.dart';
import 'package:quotebook/globals.dart';
import 'package:quotebook/standard_widgets.dart';
import 'package:quotebook/theme_settings.dart';
import 'package:quotebook/validated_form.dart';

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

  /// Creates a new doc for a new user in the firestore database (users collection), returns an ErrorCode?
  Future<ErrorCode?> createUserDoc(UserCredential userCredential) async {
    final log = Logger("Creating new user doc");
    ErrorCode? error; // contains errors occurred when creating the user doc

    // Create a new user doc in the firestore database
    DocumentReference userDocRef = FirebaseFirestore.instance.collection("users").doc(userCredential.user!.email);
    Map<String, dynamic> userDocData = {
      "last_verification_email": DateTime(2000), // jan 1st 2000 represents never
      "last_password_reset_email": DateTime(2000),
      "last_quote_suggestion": DateTime(2000)
    };
    error = await firebaseErrorHandler(log, () async {
      await userDocRef.get().then((DocumentSnapshot docSnapshot) async {
        await userDocRef.set(userDocData);
        await userDocRef.collection("liked_quotes").doc("placeholder").set({});
      }).timeout(Duration(seconds: 5));     
    });
    
    return error;
  }

  /// Attempts to create a user with the given details.
  /// 
  /// The user is not made aware if they are signing up an already existing user.
  /// This is to prevent an email enumeration attack.
  Future<void> signup(String email, String password) async {    
    final log = Logger("Sign up user");
    showLoadingIcon();

    ErrorCode? newEmailError;
    ErrorCode? newPasswordError;

    // Attempt to signup the user and get the new user's credential (or get errors)
    UserCredential? newUserCredential;
    (newEmailError, newPasswordError) = errorsForFields(
      await firebaseErrorHandler(log, () async {
        newUserCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password
        ).timeout(Duration(seconds: 5));
        await FirebaseAnalytics.instance.logSignUp(signUpMethod: "Email & Password").timeout(Duration(seconds: 5));
      }) 
    );

    // If a new user has been created, then create their doc in the database
    if (newUserCredential != null) {
      (newEmailError, newPasswordError) = errorsForFields(await createUserDoc(newUserCredential!));
    }
    
    // if no errors from user creation or other, show success toast and return to LoginPage()
    if (newEmailError == null && newPasswordError == null && mounted) {
      Navigator.of(context).pop();
      showToast(
        context,
        "Sign up successful or account already exists.", 
        Duration(seconds: 3),
      );        
    }

    // set error messages
    setState(() {
      signupFormKey.currentState!.setError(emailField.id, newEmailError);
      signupFormKey.currentState!.setError(passwordConfirmField.id, newPasswordError);
      if (newEmailError == ErrorCodes.HIGHLIGHT_RED) { // If email field highlighted, password field highlighted
        signupFormKey.currentState!.setError(passwordField.id, ErrorCodes.HIGHLIGHT_RED);
      }
    });

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
