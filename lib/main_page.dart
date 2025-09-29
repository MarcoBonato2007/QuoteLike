import 'package:flutter/material.dart';

import 'package:quotelike/explore_page.dart';
import 'package:quotelike/settings_page.dart';
import 'package:quotelike/suggestion_creation_page.dart';
import 'package:quotelike/utilities/rate_limiting.dart';

/// This is the page shown to a logged in and email verified user
/// 
/// This class wraps the settings page and explore page together
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentPageIndex = 0; // 0 means explore, 1 means settings
  
  /// Used to access the paging controller inside explore page
  final _explorePageKey = GlobalKey<ExplorePageState>();

  @override
  Widget build(BuildContext context) {  
    Widget settingsPage = Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text("Settings"),
        centerTitle: true,
      ),
      body: SettingsPage()
    );

    Widget explorePage = Scaffold(
      body: ExplorePage(_explorePageKey, key: _explorePageKey),
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text("Explore"),
        centerTitle: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton( // button to suggest a quote
            child: Icon(Icons.add),
            onPressed: () => showDialog(
              context: context, 
              builder: (context) => SuggestionCreationPage()
            ),
          ),
          FloatingActionButton( // button to refresh the list of quotes in explore_page.dart
            child: Icon(Icons.refresh),
            onPressed: () => throttledFunc(1000, () {
              _explorePageKey.currentState!.refresh();
            })
          ),
        ],
      ),
    );

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(left: 15, right: 15),
        child: IndexedStack(
          index: _currentPageIndex,
          children: [
            explorePage,
            settingsPage
          ]
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPageIndex,
        onTap: (int? newPageIndex) {
          if (newPageIndex != null) {
            setState(() => _currentPageIndex = newPageIndex);
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
