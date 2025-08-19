import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotebook/login_page.dart';
import 'firebase_options.dart';

// com.bonato.quotebook

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  FirebaseAuth.instance // https://firebase.google.com/docs/auth/flutter/start
    .authStateChanges()
    .listen((User? user) {
      if (user == null) {debugPrint("Nobody logged in");}
      else {debugPrint("${user.uid} logged in");}
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

// Next in line
  // Make sure users only access explore page when logged in.
  // Have logged in status persist (check credentials?)
  // note that both on login() and signup(), user goes logged in and then out quickly
    // so how do i see if they REMAIN logged in?
  // Add the quotes, searchbar, like feature, sort feature

// Polish
  // make it all look good
  // ensure safety of api keys and such. Check nothing sensitive on github.
  // use appcheck to ensure no cracked clients and such
  // add logging to all error things, add error checks everywhere (all firebase/firestore uses, use .then().catchError())
  // lots of code cleanup, make it better, try finding built-in alternatives to things
  // tons and tons of testing. try getting every error possible.
  // research and make good firebase security rules
  // make it from scratch on a diff firebase project, have only this on github
