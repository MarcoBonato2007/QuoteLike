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
  bool obscureText = true;

  final emailFieldController = TextEditingController();
  final passwordFieldController = TextEditingController();

  void login(
    BuildContext context,
    String email,
    String password
  ) async {
    showDialog( // Show loading icon
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator())
    );

    String? newEmailErrorText; // new error messages (can be null)
    String? newPasswordErrorText;

    try { // attempt sign in
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password
      );

      // if email not verified, send verification email and show error message
      if (!FirebaseAuth.instance.currentUser!.emailVerified) {
        newEmailErrorText = "Email not verified. Check your inbox.";

        try {
          await FirebaseAuth.instance.currentUser!.sendEmailVerification();
        }
        on FirebaseAuthException catch (e) {
          if (e.code == "too-many-requests") {
            newEmailErrorText = "Email not verified. Servers busy, try again later.";
          } else {
            newEmailErrorText = "Email not verified. An unknown error occurred, try again later.";
          }
        }
        catch (e) {
          newEmailErrorText = "Email not verified. An unknown error occurred, try again later.";
        }

        await FirebaseAuth.instance.signOut();
      }
    }
    on FirebaseAuthException catch (e) { // check error code and set appropriate error message
      if (e.code == "invalid-email") {
        newEmailErrorText = "Invalid email format";
      }
      else if (e.code == "user-not-found" || e.code == "wrong-password" || e.code == "invalid-credential") {
        newEmailErrorText = ""; // blank so it will just highlight red
        newPasswordErrorText = "Incorrect email or password";
      }
      else if (e.code == "too-many-requests") {
        newEmailErrorText = ""; // blank so it will just highlight red
        newPasswordErrorText = "Servers busy, try again later";
      }
      else if (e.code == "network-request-failed") {
        newEmailErrorText = ""; // blank so it will just highlight red
        newPasswordErrorText = "Internet connection failed. Check your internet connection.";
      }
      else if (e.code == "channel-error") { // email or password is blank
        newEmailErrorText = (email == "") ? "Please enter an email" : null;
        newPasswordErrorText = (password == "") ? "Please enter a password" : null;
      }
      else {
        newEmailErrorText = ""; // blank so it will just highlight red
        newPasswordErrorText = "An unknown error occured.";
      }

    }
    catch (e) {
      newEmailErrorText = ""; // blank so it will just highlight red
      newPasswordErrorText = "An unknown error occured.";        
    }

    setState(() {
      emailErrorText = newEmailErrorText;
      passwordErrorText = newPasswordErrorText;
    });

    if (context.mounted) {Navigator.of(context).pop();} // Remove loading icon
  }

  @override
  Widget build(BuildContext context) {
    final TextFormField emailField = TextFormField(
      controller: emailFieldController,
      validator: (String? curValue) => emailErrorText,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
        hintText: "Email",
        errorText: emailErrorText
      ),
    );

    final TextFormField passwordField = TextFormField(
      controller: passwordFieldController,
      validator: (String? curValue) => passwordErrorText,
      obscureText: obscureText,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: "Password",
        errorText: passwordErrorText,
        prefixIcon: Icon(Icons.lock),
        counter: TextButton(
          child: Text("Forgot password?"),
          onPressed: () {}
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(5),
          child: IconButton.outlined(
            style: IconButton.styleFrom(
              side: BorderSide(
                width: 5.0, 
                color: passwordErrorText == null ? ColorScheme.of(context).onSurfaceVariant : ColorScheme.of(context).error
              ), 
            ),
            splashColor: Colors.grey,
            icon: obscureText ? Icon(Icons.visibility_off) : Icon(Icons.visibility),
            onPressed: () => setState(() => obscureText = !obscureText)
          ),
        ),
      ),
    );

    final ElevatedButton loginButton = ElevatedButton( // TODO: less padding up top
      onPressed: () => login(context, emailFieldController.text, passwordFieldController.text),
      child: Text("Login")
    );

    return Column(
      children: [
        Text("Log in to continue"),
        emailField,
        passwordField,
        loginButton
      ]
    );
  }
}

// TODO: add forgot password button
// TODO: add signup page
// TODO: prevent verification email spam (check last verification email date, if >= 48 hours)
// TODO: make it look good