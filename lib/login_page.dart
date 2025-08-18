import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quotebook/signup_page.dart';

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

  void forgotPassword() async {
    String? newEmailErrorText; // new error messages (can be null)
    String? newPasswordErrorText;

    showDialog( // Show loading icon
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator())
    );

    // try/except with email and give various error codes
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailFieldController.text);
      newEmailErrorText = "If this account exists, a password reset email has been sent.";
    }
    on FirebaseAuthException catch (e) {
      if (e.code == "invalid-email" || e.code == "channel-error") {
        newEmailErrorText = "Invalid email format";
      }
      else if (e.code == "too-many-requests") {
        newEmailErrorText = "Servers busy. Try again later.";
      }
    }
    catch (e) {
      newEmailErrorText = "An unknown error occurred";
    }

    setState(() {
      emailErrorText = newEmailErrorText;
      passwordErrorText = newPasswordErrorText;
    });

    if (mounted) {Navigator.of(context).pop();} // Remove loading icon
  }

  void login(String email, String password) async {
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
      else if (e.code == "channel-error") { // email or password is blank
        newEmailErrorText = (email == "") ? "Please enter an email" : null;
        newPasswordErrorText = (password == "") ? "Please enter a password" : null;
      }
      else if (e.code == "too-many-requests") {
        newEmailErrorText = ""; // blank so it will just highlight red
        newPasswordErrorText = "Servers busy, try again later.";
      }
      else if (e.code == "network-request-failed") {
        newEmailErrorText = ""; // blank so it will just highlight red
        newPasswordErrorText = "Internet connection failed. Check your internet connection.";
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

    if (mounted) {Navigator.of(context).pop();} // Remove loading icon
  }

  @override
  Widget build(BuildContext context) {
    final TextFormField emailField = TextFormField(
      controller: emailFieldController,
      decoration: InputDecoration(
        helperText: "", // Ensures error text space is always taken up
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
        hintText: "Email",
        errorText: emailErrorText
      ),
    );

    final TextFormField passwordField = TextFormField(
      controller: passwordFieldController,
      obscureText: obscureText,
      decoration: InputDecoration(
        helperText: "",
        border: OutlineInputBorder(),
        hintText: "Password",
        errorText: passwordErrorText,
        prefixIcon: Icon(Icons.lock),
        counter: TextButton(
          style: TextButton.styleFrom(
            minimumSize: Size.zero, 
            padding: EdgeInsetsGeometry.only(left: 6, right: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap
          ),
          child: Text("Forgot password?"),
          onPressed: () => forgotPassword()
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(5),
          child: IconButton.outlined(
            color: passwordErrorText == null ? ColorScheme.of(context).primary : ColorScheme.of(context).error, // ColorScheme.of(context).onSurfaceVariant
            style: IconButton.styleFrom(
              side: BorderSide(
                width: 2.0, 
                color: passwordErrorText == null ? ColorScheme.of(context).primary : ColorScheme.of(context).error
              ), 
            ),
            icon: obscureText ? Icon(Icons.visibility_off) : Icon(Icons.visibility),
            onPressed: () => setState(() => obscureText = !obscureText)
          ),
        ),
      ),
    );

    final ElevatedButton loginButton = ElevatedButton(
      onPressed: () => login(emailFieldController.text, passwordFieldController.text),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorScheme.of(context).primary,
        foregroundColor: ColorScheme.of(context).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10))  
      ),
      child: Text("Login")
    );

    final TextButton signupButton = TextButton(
      style: TextButton.styleFrom(
        minimumSize: Size.zero, 
        padding: EdgeInsetsGeometry.only(left: 6, right: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap
      ),
      child: Text("Sign up"),
      onPressed: () => Navigator.push(
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
