import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quotebook/globals.dart';
import 'package:quotebook/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{
  String? emailErrorText; // put here so login() and build() can both access them
  String? passwordErrorText;
  bool obscureText = true;
  bool passwordFieldSelected = false;

  final emailFieldController = TextEditingController();
  final emailFieldKey = GlobalKey<FormFieldState>();
  final passwordFieldController = TextEditingController();
  final passwordFieldKey = GlobalKey<FormFieldState>();

  Future<void> forgotPassword(String email) async {
    showDialog( // Show loading icon
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator())
    );

    String? newEmailErrorText;

    // check if password reset email wasn't already sent too recently
    DocumentReference userDocRef = FirebaseFirestore.instance.collection("users").doc(email);
    Map<String, dynamic> userDocData = (await userDocRef.get()).data() as Map<String, dynamic>;
    int minutesSinceLastEmail = DateTime.now().difference(userDocData["last_password_reset_email"].toDate()).inMinutes;
    if (minutesSinceLastEmail <= 59 && mounted) {
      // Unfortunately we can't tell the user that they have to wait before sending another password reset.  
      // This prevents email enumeration attacks
      showToast(
        context, 
        "If this account exists, and a password reset didn't take place within the last hour, then a password reset email has been sent.",
        Duration(seconds: 5),
      );
    }
    else {
      try { // send a password reset email, set a new timestamp in the user doc
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

        userDocData["last_password_reset_email"] = DateTime.now();
        await userDocRef.set(userDocData);

        if (mounted) {
          showToast(
            context, 
            "If this account exists, and a password reset didn't take place within the last hour, then a password reset email has been sent.",
            Duration(seconds: 5),
          );
        }
      }
      on FirebaseAuthException catch (e) { // handle possible errors
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
    }

    setState(() {
      emailErrorText = newEmailErrorText;
      passwordErrorText = null;
    });

    if (mounted) {Navigator.of(context).pop();} // Remove loading icon
  }

  Future<void> login(String email, String password) async {
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
      try { // attempt sign in through firebase and handle relevent errors
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password
        );

        // if email not verified, send verification email (if not too recent), show error message and sign out
        if (!FirebaseAuth.instance.currentUser!.emailVerified) {
          newEmailErrorText = "Email not verified.";

          // check if another verification email has been sent recently, limit of 1 email/user/70 hours
          DocumentReference userDocRef = FirebaseFirestore.instance.collection("users").doc(userCredential.user!.email);
          Map<String, dynamic> userDocData = (await userDocRef.get()).data() as Map<String, dynamic>;
          if (DateTime.now().difference(userDocData["last_verification_email"].toDate()).inHours <= 70 && mounted) {
            showToast(
              context, 
              "A verification email was already sent recently. Check your inbox.",
              Duration(seconds: 3)
            );              
          }
          else { // send a new verification email, set new timestamp
            try {
              await FirebaseAuth.instance.currentUser!.sendEmailVerification();

              userDocData["last_verification_email"] = DateTime.now();
              await userDocRef.set(userDocData);

              if (mounted) {
                showToast(
                  context, 
                  "A new verification email has been sent. Check your inbox.",
                  Duration(seconds: 3)
                );                
              }
            }
            on FirebaseAuthException catch (e) { // show error messages with snackbar
              if (e.code == "too-many-requests" && mounted) {
                showToast(
                  context, 
                  "A new verification email could not be sent, servers busy.",
                  Duration(seconds: 3)
                );                
                
              } else if (mounted) {
                showToast(
                  context, 
                  "A new verification email could not be sent, an unknown error occurred.",
                  Duration(seconds: 3)
                );       
              }
            }
            catch (e) {
              if (mounted) {
                showToast(
                  context, 
                  "A new verification email could not be sent, an unknown error occurred.",
                  Duration(seconds: 3)
                );       
              }
            }
          }

          await FirebaseAuth.instance.signOut();
        }
      }
      on FirebaseAuthException catch (e) { // check error code and set appropriate error message
        // As a failsafe in case the email_validator package fails
        if (e.code == "invalid-email") {
          newEmailErrorText = "Invalid email format";
        }
        else if (e.code == "user-not-found" || e.code == "wrong-password" || e.code == "invalid-credential") {
          newEmailErrorText = ""; // blank so it will just highlight red
          newPasswordErrorText = "Incorrect email or password";
        }
        else if (e.code == "too-many-requests") {
          newEmailErrorText = ""; // blank so it will just highlight red
          newPasswordErrorText = "Servers busy, try again later.";
        }
        else if (e.code == "network-request-failed") {
          newEmailErrorText = ""; // blank so it will just highlight red
          newPasswordErrorText = "Network error. Check your internet connection.";
        }
        else {
          print(e.code);
          newEmailErrorText = ""; // blank so it will just highlight red
          newPasswordErrorText = "An unknown error occured.";
        }
      }
      catch (e) {
        print(e);
        newEmailErrorText = ""; // blank so it will just highlight red
        newPasswordErrorText = "An unknown error occured.";        
      }     
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
        if (currentValue == "") {
          return "Please enter a password";
        }
        else {
          return null;
        }
      },
      obscureText: obscureText,
      decoration: InputDecoration(
        errorMaxLines: 3,
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
          onPressed: () async {
            if (emailFieldKey.currentState!.validate()) {
              await forgotPassword(emailFieldController.text);
            }
          }
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
      onPressed: () async {
        emailFieldKey.currentState!.validate();
        passwordFieldKey.currentState!.validate();
        if (emailFieldKey.currentState!.validate() && passwordFieldKey.currentState!.validate()) {
          await login(emailFieldController.text, passwordFieldController.text);
        }  
      },
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
