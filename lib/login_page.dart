import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotebook/globals.dart';
import 'package:quotebook/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{
  String? emailErrorText; // put here so login() and build() can both access them
  final emailFieldController = TextEditingController();
  final emailFieldKey = GlobalKey<FormFieldState>();

  String? passwordErrorText;
  final passwordFieldController = TextEditingController();
  final passwordFieldKey = GlobalKey<FormFieldState>();

  bool obscurePassword = true;

  Future<void> forgotPassword(String email) async {
    final log = Logger("Forgot password function");

    showLoadingIcon(context);

    String? newEmailErrorText;
    String? newPasswordErrorText;

    // Get user doc, check it exists, and send email if an hour has passed since the last password reset
    DocumentReference userDocRef = FirebaseFirestore.instance.collection("users").doc(email);
    await userDocRef.get().then((DocumentSnapshot userDoc) async {
      if (userDoc.exists) { // we only do anything if the user's email exists
        Map<String, dynamic> userDocData = (await userDocRef.get()).data() as Map<String, dynamic>;
        int minutesSinceLasPasswordResetEmail = DateTime.timestamp().difference(userDocData["last_password_reset_email"].toDate()).inMinutes;
        if (minutesSinceLasPasswordResetEmail >= 60 && mounted) {
          (newEmailErrorText, newPasswordErrorText) = await firebaseAuthErrorCatch(context, () async {
            await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
            userDocData["last_password_reset_email"] = DateTime.timestamp();
            await userDocRef.set(userDocData);
          });   
        }
      }

      if (newEmailErrorText == null && newPasswordErrorText == null && mounted) { // no errors occurred, show success toast
        showToast(
          context, 
          "If this account exists, and a password reset didn't take place within the last hour, then a password reset email has been sent.",
          Duration(seconds: 5),
        );
      }
      else { // errors occurred, update error texts
        setState(() {
          emailErrorText = newEmailErrorText;
          passwordErrorText = newPasswordErrorText;
        });
      }
    }).catchError((error) {
      log.severe("${log.name}: Unknown firestore error: $error");
    }); // catch any errors (ignored for now)

    if (mounted) {
      hideLoadingIcon(context);
    }
  }

  Future<void> login(String email, String password) async {
    final log = Logger("Login function");

    showLoadingIcon(context);

    String? newEmailErrorText; // new error messages (can be null)
    String? newPasswordErrorText;

    (newEmailErrorText, newPasswordErrorText) = await firebaseAuthErrorCatch(context, () async {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password
      );
    });

    // if login successful, and email not verified, then send verification email (if not too recent), show error message and sign out
    if (FirebaseAuth.instance.currentUser != null && !FirebaseAuth.instance.currentUser!.emailVerified) {
      newEmailErrorText = "Email not verified.";

      // check if another verification email has been sent recently, limit of 1 email/user/3 days
      DocumentReference userDocRef = FirebaseFirestore.instance.collection("users").doc(email);
      await userDocRef.get().then((DocumentSnapshot userDocSnapshot) async {
        Map<String, dynamic> userDocData = userDocSnapshot.data() as Map<String, dynamic>;

        if (DateTime.timestamp().difference(userDocData["last_verification_email"].toDate()).inHours <= 72 && mounted) {
          showToast( // tell user to check their inbox if a verification email was sent recently
            context, 
            "A verification email was already sent recently. Check your inbox.",
            Duration(seconds: 3)
          );              
        }
        else if (mounted) { // send a new verification email, set new timestamp
          await firebaseAuthErrorCatch(
            isEmailVerificationSend: true,
            context, 
            () async {
              await FirebaseAuth.instance.currentUser!.sendEmailVerification();

              userDocData["last_verification_email"] = DateTime.timestamp();
              await userDocRef.set(userDocData).catchError((error) {
                log.severe("${log.name}: Unkown firestore error: $error");
              });

              if (mounted) {
                showToast(
                  context, 
                  "A new verification email has been sent. Check your inbox.",
                  Duration(seconds: 3)
                );                
              }              
            },
          );
        }
      }).catchError((error) {
        log.severe("${log.name}: Unkown firestore error: $error");
      }); // catch any errors (ignored for now)

      await FirebaseAuth.instance.signOut(); // sign out, since they are not verified
    }

    setState(() {
      emailErrorText = newEmailErrorText;
      passwordErrorText = newPasswordErrorText;
    });

    if (mounted) {
      hideLoadingIcon(context);
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
        if (currentValue == "") {
          return "Please enter a password";
        }
        else {
          return null;
        }
      },
      obscureText: obscurePassword,
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
          onPressed: () => throttledFunc(2000, () async {
            setState(() {
              emailErrorText = null;
              passwordErrorText = null;
            });
            if (emailFieldKey.currentState!.validate()) {
              await forgotPassword(emailFieldController.text);
            }
          })
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
            icon: obscurePassword ? Icon(Icons.visibility_off) : Icon(Icons.visibility),
            onPressed: () => setState(() => obscurePassword = !obscurePassword)
          ),
        ),
      ),
    );

    final ElevatedButton loginButton = ElevatedButton(
      onPressed: () => throttledFunc(2000, () async {
        bool emailValid = emailFieldKey.currentState!.validate();
        bool passwordValid = passwordFieldKey.currentState!.validate();
        if (emailValid && passwordValid) {
          await login(emailFieldController.text, passwordFieldController.text);
        }  
      }),
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
