import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? emailErrorText; // put here so login() and build() can both access them
  String? passwordErrorText;

  void login(
    BuildContext context,
    GlobalKey<FormFieldState> emailFieldKey,
    GlobalKey<FormFieldState> passwordFieldKey
  ) async {
    emailErrorText = null;
    passwordErrorText = null;
    String email = emailFieldKey.currentState!.value;
    String password = passwordFieldKey.currentState!.value;

    showDialog( // Show loading icon
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator())
    );

    try {
      if (email == "" || password == "") {
        emailErrorText = (email == "") ? "Please enter an email" : null;
        passwordErrorText = (password == "") ? "Please enter an password" : null;
      }
      else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password
        );

      }


      emailFieldKey.currentState!.validate();
      passwordFieldKey.currentState!.validate();
    }
    on FirebaseAuthException catch (e) {
      if (e.code == "invalid-email") {
        emailErrorText = "Invalid email format";
      }
      else if (e.code == "user-not-found" || e.code == "wrong-password" || e.code == "invalid-credential") {
        emailErrorText = ""; // blank so it will just highlight red
        passwordErrorText = "Incorrect email or password";

      }
      else if (e.code == "too-many-requests") {
        emailErrorText = ""; // blank so it will just highlight red
        passwordErrorText = "Servers busy, try again later";
      }
      else if (e.code == "network-request-failed") {
        emailErrorText = ""; // blank so it will just highlight red
        passwordErrorText = "Internet connection failed. Check your internet connection.";
        // error for network error, check your internet connection
      }
      else {
        emailErrorText = ""; // blank so it will just highlight red
        passwordErrorText = "An unknown error occured.";
      }
      emailFieldKey.currentState!.validate();
      passwordFieldKey.currentState!.validate();
    }
    catch (e) {
      emailErrorText = ""; // blank so it will just highlight red
      passwordErrorText = "An unknown error occured.";
      emailFieldKey.currentState!.validate();
      passwordFieldKey.currentState!.validate();
    }

    Navigator.of(context).pop(); // Remove loading icon
  }

  @override
  Widget build(BuildContext context) {
    final emailFieldKey = GlobalKey<FormFieldState>();
    final TextFormField emailField = TextFormField(
      key: emailFieldKey,
      validator: (String? curValue) => emailErrorText,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: "Email",
        errorText: emailErrorText
      ),
    );

    final passwordFieldKey = GlobalKey<FormFieldState>();
    final TextFormField passwordField = TextFormField(
      key: passwordFieldKey,
      validator: (String? curValue) => passwordErrorText,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: "Password",
        errorText: passwordErrorText
      ),
    );

    final ElevatedButton loginButton = ElevatedButton(
      child: Text("Login"),
      onPressed: () => login(context, emailFieldKey, passwordFieldKey)
    );

    return Column(
      children: [
        emailField,
        passwordField,
        loginButton
      ]
    );
  }
}

// TODO: prevent verification email spam
// TODO: make it look good
  // add icons on email and password boxes (lock icon and email icon)
