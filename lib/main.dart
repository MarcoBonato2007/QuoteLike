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

  // Setup error logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // Level is INFO for caught errors, WARNING for unknown auth caught errors, SEVERE for unknown firestore errors
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Get messages of user changes in the debug console
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
      builder: (BuildContext context, AsyncSnapshot<User?> userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }  
        else if (userSnapshot.hasData && userSnapshot.data!.emailVerified == true) { // go to main page
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
  // figure out the confusion with Navigator.of(context).pop(), do i need to put it in async?
  // why does it work on delete account and not login?
  // check this problem on login, logout and delete account (do this one last)

  // finish settings page
  // Add the quotes, searchbar, like feature, sort feature

// Polish
  // make it all look good
  // make all async functions work through await (to avoid issues like a stuck loading icon)
  // ensure safety of api keys and such. Check nothing sensitive on github.
  // Minimize the loading times for things like signup() and login() to prevent enumeration attack
  // use .timeout() on firestore uses to ensure it doesn't take too long
  // use appcheck to ensure no cracked clients and such
  // make a custom form class for login and signup page
  // make it so that all functions have a descriptor when you highlight them
  // add logging to all error things, add error checks everywhere (all firebase/firestore uses, use .then().catchError())
  // lots of code cleanup, make it better, try finding built-in alternatives to things
  // Don't just .catchError(), actually affect the error messages or show a snackbar, remember to use .timeout() and the stuff in globals
  // do network checks (while ur in quote)
  // USe leading underscore (_) for best practice, see where you're supposed to use it
  // Research other good practices
  // research and make good firebase security rules
  // look at earlier made files for style guides (e.g. login page or globals)
  // tons and tons of testing. try catching every error possible (firebase auth and firebase firestore).
  // research common security issues, ask chatgpt, try to find vulnerabilities
  // make it from scratch on a diff firebase project, have only this on github
