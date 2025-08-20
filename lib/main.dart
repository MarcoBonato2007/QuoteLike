import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotebook/login_page.dart';
import 'package:quotebook/main_page.dart';
import 'firebase_options.dart';

// com.bonato.quotebook

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // Level is INFO for caught errors, WARNING for unknown auth caught errors, SEVERE for unknown firestore errors
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  FirebaseAuth.instance // https://firebase.google.com/docs/auth/flutter/start
    .authStateChanges()
    .listen((User? user) {
      if (user == null) {
        debugPrint("Nobody logged in");
      }
      else if (!user.emailVerified) {
        debugPrint("${user.uid} logged in, unverified");
      }
      else {
        debugPrint("${user.uid} logged in, verified");
      }
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }  
        if (snapshot.hasData && snapshot.data!.emailVerified == true) { // go to main page
          return MainPage();
        }
        else {
          return Scaffold(body: LoginPage());
        }
      }
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
  // tons and tons of testing. try catching every error possible (firebase auth and firebase firestore).
  // Don't just .catchError(), actually affect the error messages
  // do network checks (while ur in quote)
  // research and make good firebase security rules
  // make it from scratch on a diff firebase project, have only this on github
