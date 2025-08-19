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

// TODO: add client-side debouncing (prevent login/signup/forgot password button spam)
  // Throttle or debounce? 
  // Try making the throttler/debouncer yourself
  // Add 1 second debounce/throttle time to everything (i.e. max one click / second)
  // Experiment with what times feel good. Then implement a slightly shorter time.
  // add a password confirm box
// TODO: try to spot and make any final touches. TEST A LOT!!
  // Make it so that two-line error text doesn't move the things.

// Future todo's:
// consider adding a captcha
// Add the quotes, searchbar, like feature, sort feature
// make it all look good
// ensure safety of api keys and such. Check nothing sensitive on github.
// use appcheck to ensure no cracked clients and such
// add network error check
// code cleanup, make it better, try finding built-in alternatives to things
// tons and tons of testing. try getting every error possible.
// research and make good firebase security rules
// make it from scratch on a diff firebase project, have only this on github
