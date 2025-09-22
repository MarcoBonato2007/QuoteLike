import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quotelike/login_page.dart';
import 'package:quotelike/main_page.dart';
import 'package:quotelike/utilities/enums.dart';
import 'package:quotelike/utilities/firebase_options.dart';
import 'package:quotelike/utilities/globals.dart';
import 'package:quotelike/utilities/theme_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(androidProvider: AndroidProvider.debug);
  await logEvent(Event.APP_OPEN);
  
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
  // add logging to all error things, add error checks everywhere (all firebase/firestore uses, use .then().catchError())
  // lots of code cleanup, make it better, try finding built-in alternatives to things
  // test losing network connection at random times, how does the program react?
  // Research other good practices
  // tons and tons of testing. try catching every error possible (firebase auth and firebase firestore).
  // fix the failed to get service from broker error
  // fix failed to get service from broker error
  // Just generally re-read through all the code. What can you improve? what can you not repeat?

  // Update the readme (include info on how to get started)
  // Check https://docs.flutter.dev/deployment/android
  // change the appcheck to AndroidProvider.playIntegrity
  // use --obfuscate and --split-debug when building to make it harder to reverse engineer
  // Launch it and test there. Really try to break it.

  // In future: remember to update the version in pubspec.yaml
