import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:quotebook/globals.dart';
import 'package:quotebook/login_page.dart';
import 'package:quotebook/main_page.dart';
import 'package:quotebook/theme_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// com.bonato.quotebook

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  await firebaseErrorHandler(Logger("Logging app open"), useCrashlytics: true, () async {
    await FirebaseAnalytics.instance.logAppOpen();
  });
  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError; // report errors
  PlatformDispatcher.instance.onError = (error, stack) { // report async errors
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Setup error logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // Level is INFO for caught errors, WARNING for unknown auth caught errors, SEVERE for unknown firestore errors
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Get messages of user changes in the debug console
  FirebaseAuth.instance // https://firebase.google.com/docs/auth/flutter/start
    .authStateChanges()
    .listen((User? user) async {
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

  final prefs = await SharedPreferences.getInstance();
  runApp( // we wrap this in a changenotifierprovider so it updates as the theme updates
    ChangeNotifierProvider(
      create: (context) => ThemeSettings(prefs.getBool("isColorThemeLight") ?? true),
      child: Consumer<ThemeSettings>(
        builder: (BuildContext context, ThemeSettings themeSettings, child) {
          return MyApp(themeSettings);
        }
      )
    )
  );
}

class MyApp extends StatelessWidget {
  final ThemeSettings themeSettings;
  const MyApp(this.themeSettings, {super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      navigatorKey: navigatorKey,
      theme: themeSettings.themeData,
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
        // shows main page if logged in and verified, shows login page otherwsie
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }  
        else if (userSnapshot.hasData && userSnapshot.data!.emailVerified == true) {
          return MainPage();
        }
        else {
          return Scaffold(body: LoginPage());
        }
      }
    );
  }
}

// Polish
  // fix failed to get service from broker error. KEEP TRYING!

  // think how to fix data integrity issues when combining auth and firestore. Do they need fixing?
    // Think of possible issues that could arise (e.g. non-existing user doc, non-existing user in auth, etc.)

  // add folders and categorize the files
  // add triple slash comments to EVERY function, class, important variable

  // fix not seeing sign up events in analytics

  // ensure safety of api keys and such. Check nothing sensitive on github.
  // add logging to all error things, add error checks everywhere (all firebase/firestore uses, use .then().catchError())
  // lots of code cleanup, make it better, try finding built-in alternatives to things
  // test losing network connection at random times, how does the program react?
  // USe leading underscore (_) for best practice, see where you're supposed to use it
  // Research other good practices
  // add more comments
  // research and make good firebase security rules
  // check style and code consistency
  // add a lot of initial quotes
  // tons and tons of testing. try catching every error possible (firebase auth and firebase firestore).
  // research common security issues, ask chatgpt, try to find 
  // fix the failed to get service from broker error
  // add firebase app check
  // add the right github license (GNU GPLv3)
  // Just generally re-read through all the code. What can you improve? what can you not repeat?
  // get better logo, remember to run the flutter launcher icons package
  // make it from scratch on a diff firebase project, have only this on github
  // see if u can add cloud functions (if useful) by linking firestore to an acc with no money inside
