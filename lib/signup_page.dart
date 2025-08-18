import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quotebook/globals.dart';
import 'package:quotebook/login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  String? emailErrorText; // put here so login() and build() can both access them
  String? passwordErrorText;
  bool obscureText = true;

  final emailFieldController = TextEditingController();
  final passwordFieldKey = GlobalKey<FormFieldState>();
  final passwordFieldController = TextEditingController();
  final emailFieldKey = GlobalKey<FormFieldState>();

  Future<void> signup(String email, String password) async {
    showDialog( // Show loading icon
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator())
    );

    String? newEmailErrorText; // new error messages (can be null)
    String? newPasswordErrorText;

    if ((await Connectivity().checkConnectivity()).contains(ConnectivityResult.none)) {
      newEmailErrorText = ""; // blank so it will just highlight red
      newPasswordErrorText = "Network error. Check your internet connection.";
    }
    else {
      try { // attempt sign up through firebase and handle relevent errors
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password
        );
      }
      on FirebaseAuthException catch (e) { // check error code and set appropriate error message
        if (e.code == "invalid-email") {
          newEmailErrorText = "Invalid email format";
        }
        else if (e.code == "weak-password" || e.code == "unknown" || e.code == "email-already-in-use") {
          // We don't tell the user if an account already exists, this prevents an enumeration attack
        }
        else if (e.code == "too-many-requests") {
          newEmailErrorText = ""; // blank so it will just highlight red
          newPasswordErrorText = "Servers busy, try again later";
        }
        else if (e.code == "network-request-failed") {
          newEmailErrorText = ""; // blank so it will just highlight red
          newPasswordErrorText = "Network error. Check your internet connection.";
        }
        else if (e.code == "channel-error") { // email or password is blank
          newEmailErrorText = (email == "") ? "Please enter an email" : null;
          newPasswordErrorText = (password == "") ? "Please enter a password" : null;
        }
        else {
          newEmailErrorText = ""; // blank so it will just highlight red
          newPasswordErrorText = "An unknown error occurred.";
        }
      }
      catch (e) {
        newEmailErrorText = ""; // blank so it will just highlight red
        newPasswordErrorText = "An unknown error occurred.";        
      }      
    }


    setState(() {
      emailErrorText = newEmailErrorText;
      passwordErrorText = newPasswordErrorText;
    });

    if (mounted) {Navigator.of(context).pop();} // Remove loading icon

    // If no error messages, go back to login page, show success snackbar
    if (newEmailErrorText == null && newPasswordErrorText == null && mounted) {
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => Scaffold(body: LoginPage()))
      );
      showToast(context, "Sign up successful or account already exists");
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextFormField emailField = TextFormField(
      controller: emailFieldController,
      key: emailFieldKey,
      onChanged: (String? currentValue) => setState(() {
        emailErrorText = null; 
        passwordErrorText = null;
      }),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (String? currentValue) {
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
      decoration: InputDecoration(
        helperText: "", // Ensures error text space is always taken up
        errorMaxLines: 3,
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
        hintText: "Email",
        errorText: emailErrorText
      ),
    );

    final TextFormField passwordField = TextFormField(
      controller: passwordFieldController,
      key: passwordFieldKey,
      onChanged: (String? currentValue) => setState(() {
        emailErrorText = null; 
        passwordErrorText = null;
      }),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (String? currentValue) {
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
      obscureText: obscureText,
      decoration: InputDecoration(
        helperText: "",
        errorMaxLines: 3,
        border: OutlineInputBorder(),
        hintText: "Password",
        errorText: passwordErrorText,
        prefixIcon: Icon(Icons.lock),
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

    final ElevatedButton signupButton = ElevatedButton(
      onPressed: () async {
        emailFieldKey.currentState!.validate();
        passwordFieldKey.currentState!.validate();
        if (emailFieldKey.currentState!.validate() && passwordFieldKey.currentState!.validate()) {
          await signup(emailFieldController.text, passwordFieldController.text);
        }      
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorScheme.of(context).primary,
        foregroundColor: ColorScheme.of(context).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10))  
      ),
      child: Text("Sign up")
    );

    final TextButton loginButton = TextButton(
      style: TextButton.styleFrom(
        minimumSize: Size.zero, 
        padding: EdgeInsetsGeometry.only(left: 6, right: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap
      ),
      child: Text("Login"),
      onPressed: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => Scaffold(body: LoginPage()))
      )
    );

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
          SizedBox(height: 10),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: signupButton, 
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Already have an account? "),
              loginButton
            ]
          )
        ]
      ),
    );
  }
}
