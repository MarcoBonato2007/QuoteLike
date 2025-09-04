import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  // TODO: change all .catchErrors to try excepts, make a unified function in globals for this
  // fix the failed to get service from broker error
  // make it all look good
  // add more pre internet checks (add in global, make an internetCheck() function or smth)
  // ensure all async functions work through await (to avoid issues like a stuck loading icon)
  // ensure safety of api keys and such. Check nothing sensitive on github.
  // Minimize the loading times for things like signup() and login() to prevent enumeration attack
  // use .timeout() on firestore uses to ensure it doesn't take too long
  // use appcheck to ensure no cracked clients and such
  // make a custom form class for login and signup page
  // try adding firestore functions to take care of corrupted / incomplete docs or collections
    // e.g. ensuring all users have a liked_quotes collection
  // make it so that all functions have a descriptor when you highlight them
  // add logging to all error things, add error checks everywhere (all firebase/firestore uses, use .then().catchError())
  // lots of code cleanup, make it better, try finding built-in alternatives to things
  // Don't just .catchError(), actually affect the error messages or show a snackbar, remember to use .timeout() and the stuff in globals
  // do network checks (while ur in quote)
  // add splash screen (use the package)
  // USe leading underscore (_) for best practice, see where you're supposed to use it
  // Research other good practices
  // do internet checks
  // try adding @override init and @override dispose (dispose controllers, keys, etc.)
  // find any screen switches, check if you need to use navigatorKey anywhere. NO USE OF CONTEXT ANYWHERE after a screen switch (setState included)
  // see if you want to customize some text style (e.g. make it bold), use richtext
  // research and make good firebase security rules
  // look at earlier made files for style guides (e.g. login page or globals)
  // tons and tons of testing. try catching every error possible (firebase auth and firebase firestore).
  // research common security issues, ask chatgpt, try to find 
  // check for consistency of things like error handling approaches between files
  // make it from scratch on a diff firebase project, have only this on github
