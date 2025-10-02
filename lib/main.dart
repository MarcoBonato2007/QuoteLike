import 'package:flutter/foundation.dart';
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
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity
  );
  await logEvent(Event.APP_OPEN);
  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError; // report errors
  PlatformDispatcher.instance.onError = (error, stack) { // report async errors
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Setup error logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      """
      Error has been logged
      Level: ${record.level.name}
      Logger: ${record.loggerName}
      Time: ${record.time}
      Message: ${record.message}
      Error text: ${record.error}
      """
    );
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

// Note: be careful updating any packages or dependencies.
// In the past, this caused firebase to not print debug app check tokens

// Notes to myself
  // To read obfuscated crashlytics stacktraces, decode them using the .symbols files

  // In future: 
    // try to fix the failed to get service from broker and deprecation errors
    // custom quotes feature
    // add a search bar (would need to be starts with only, and has case sensitivity issues)
    // implement sorting by recent, most liked and least liked when filtering by liked quotes
    // remember to update the version in pubspec.yaml
