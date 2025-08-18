import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:quotebook/login_page.dart';
import 'firebase_options.dart';

// com.bonato.quotebook

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  FirebaseAuth.instance // https://firebase.google.com/docs/auth/flutter/start
    .authStateChanges()
    .listen((User? user) {
      if (user == null) {print("Nobody logged in");}
      else {print("${user.uid} logged in");}
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoginPage()
    );
  }
}

// TODO: fully protect against enum attacks
// TODO: test a lot. What do you not like? what would you change?

// TODO: prevent login/signup and verification and password reset and signup email spam (for each user, check last time they sent it)
// TODO: consider adding a captcha
// TODO: Ensure all rate limit errors are handled (too-many-requests)
// TODO: Add the quotes, searchbar, like feature, sort feature
// TODO: make it all look good
// TODO: ensure safety of api keys and such. Check nothing sensitive on github.
