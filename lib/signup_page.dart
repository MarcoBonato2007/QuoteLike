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
  String? emailErrorText; // put here so login() and build() can both access them\
  final emailFieldController = TextEditingController();
  final emailFieldKey = GlobalKey<FormFieldState>();

  String? passwordErrorText;
  final passwordFieldKey = GlobalKey<FormFieldState>();
  final passwordFieldController = TextEditingController();
  bool obscurePassword = true;

  String? passwordConfirmErrorText;
  final passwordConfirmFieldKey = GlobalKey<FormFieldState>();
  final passwordConfirmFieldController = TextEditingController();
  bool obscurePasswordConfirm = true;

  Future<void> signup(String email, String password) async {
    final log = Logger("Signup function");
    
    showLoadingIcon(context);

    String? newEmailErrorText; // new error messages (can be null)
    String? newPasswordErrorText;
    String? newPasswordConfirmErrorText;

    UserCredential? newUserCredential;

    (newEmailErrorText, newPasswordErrorText) = await firebaseAuthErrorCatch(context, () async {
      newUserCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
      await FirebaseAuth.instance.signOut();
    });

    if (newEmailErrorText == HIGHLIGHT_RED) {
      newPasswordConfirmErrorText = newPasswordErrorText;
      newPasswordErrorText = HIGHLIGHT_RED;
    }

    // If no error messages, then either signup successful or account already exists
    if (newEmailErrorText == null && newPasswordErrorText == null) {
      // if a new user is being added (newUserCredential != null), add a new user document
      if (newUserCredential != null) {
        // add a document for this user in the firestore database
        DocumentReference userDoc = FirebaseFirestore.instance.collection("users").doc(newUserCredential!.user!.email);
        Map<String, dynamic> userDocData = {
          "last_verification_email": DateTime(2000), // jan 1st 2000 represents never
          "last_password_reset_email": DateTime(2000)
        };

        await userDoc.get().then((DocumentSnapshot docSnapshot) async {
          if (!docSnapshot.exists) { // the user could already exist (remember, we don't tell the user that)
            await userDoc.set(userDocData);
            await userDoc.collection("liked_quotes").doc("placeholder").set({});
          }
        }).catchError((error) {
          log.severe("${log.name}: Unkown firestore error: $error");
        }); 

        if (mounted) { // send the user a verification email and set a new timestamp
          await firebaseAuthErrorCatch(context, () async {
            await newUserCredential!.user!.sendEmailVerification();
            userDocData["last_verification_email"] = DateTime.timestamp();
            await userDoc.set(userDocData).catchError((error) {
              log.severe("${log.name}: Unkown firestore error: $error");
            });          
          });           
        }
      }

      // Go back to login screen and show success snackbar
      if (mounted) {
        Navigator.of(context).pop(); // go back to loginPage()
        showToast(
          context, 
          "Sign up successful (check your inbox for a verification email) or account already exists.", 
          Duration(seconds: 3),
        );        
      }
    }
    else { // set error messages
      setState(() {
        emailErrorText = newEmailErrorText;
        passwordErrorText = newPasswordErrorText;
        passwordConfirmErrorText = newPasswordConfirmErrorText;
      });
      if (mounted) {
        hideLoadingIcon(context);
      }
    }

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
        passwordConfirmErrorText = null;
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
        passwordConfirmErrorText = null;
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
      obscureText: obscurePassword,
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
            icon: obscurePassword ? Icon(Icons.visibility_off) : Icon(Icons.visibility),
            onPressed: () => setState(() => obscurePassword = !obscurePassword)
          ),
        ),
      ),
    );

    final TextFormField passwordConfirmField = TextFormField(
      controller: passwordConfirmFieldController,
      key: passwordConfirmFieldKey,
      onChanged: (String? currentValue) => setState(() {
        emailErrorText = null; 
        passwordErrorText = null;
        passwordConfirmErrorText = null;
      }),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (String? currentValue) {
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
      decoration: InputDecoration(
        helperText: "",
        errorMaxLines: 3,
        border: OutlineInputBorder(),
        hintText: "Password",
        errorText: passwordConfirmErrorText,
        prefixIcon: Icon(Icons.lock),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(5),
          child: IconButton.outlined(
            color: passwordConfirmErrorText == null ? ColorScheme.of(context).primary : ColorScheme.of(context).error, // ColorScheme.of(context).onSurfaceVariant
            style: IconButton.styleFrom(
              side: BorderSide(
                width: 2.0, 
                color: passwordConfirmErrorText == null ? ColorScheme.of(context).primary : ColorScheme.of(context).error
              ), 
            ),
            icon: obscurePasswordConfirm ? Icon(Icons.visibility_off) : Icon(Icons.visibility),
            onPressed: () => setState(() => obscurePasswordConfirm = !obscurePasswordConfirm)
          ),
        ),
      ),
    );

    final ElevatedButton signupButton = ElevatedButton(
      onPressed: () => throttledFunc(2000, () async {
        bool emailValid = emailFieldKey.currentState!.validate();
        bool passwordValid = passwordFieldKey.currentState!.validate();
        bool passwordConfirmValid = passwordConfirmFieldKey.currentState!.validate();
        if (emailValid && passwordValid && passwordConfirmValid) {
          await signup(emailFieldController.text, passwordFieldController.text);
        }      
      }),
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
      onPressed: () => Navigator.of(context).pop()
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
