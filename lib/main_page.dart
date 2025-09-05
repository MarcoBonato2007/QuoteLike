import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotebook/constants.dart';
import 'package:quotebook/explore_page.dart';
import 'package:quotebook/globals.dart';
import 'package:quotebook/settings_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentPageIndex = 0; // 0 means explore, 1 means settings
  late Future<(ErrorCode?, List<String>)> likedQuotesResult; // we put this here to avoid rebuilding constantly


  /// Gets a list of liked user quotes, this is passed into ExplorePage() in a FutureBuilder()
  Future<(ErrorCode?, List<String>)> getLikedQuotes() async {
    final log = Logger("Getting liked quotes");

    ErrorCode? error;
    List<String> likedQuotes = [];

    error = await firebaseErrorHandler(log, () async {
      await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.email)
        .collection("liked_quotes")
      .get().timeout(Duration(seconds: 5)).then((QuerySnapshot querySnapshot) {
          for (DocumentSnapshot doc in querySnapshot.docs) {
            likedQuotes.add(doc.id);
          }
      });
    });

    return (error, likedQuotes);
  }

  @override
  void initState() {
    likedQuotesResult = getLikedQuotes();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(left: 15, right: 15),
        child: IndexedStack(
          index: currentPageIndex,
          children: [
            FutureBuilder(
              future: likedQuotesResult,
              builder: (context, snapshot) {
                if (snapshot.hasError || (snapshot.hasData && snapshot.data!.$1 != null)) {
                  debugPrint("Unknown flutter error getting liked quotes: ${snapshot.error}");
                  return Center(child: Text("An unknown error occurred"));
                }
                else if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                else {
                  return ExplorePage(snapshot.data!.$2);
                }
              }
            ),
            Scaffold(
              appBar: AppBar(
                title: Text("Settings"),
                centerTitle: true,
              ),
              body: SettingsPage()
            )
          ]
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentPageIndex,
        onTap: (int? newPageIndex) {
          if (newPageIndex != null) {
            setState(() => currentPageIndex = newPageIndex);
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: "Explore"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings"
          ),
        ]
      )
    );
  }
}