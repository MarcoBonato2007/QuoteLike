import 'package:flutter/material.dart';
import 'package:quotebook/explore_page.dart';
import 'package:quotebook/settings_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentPageIndex = 0; // 0 means explore, 1 means settings

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(left: 15, right: 15),
        child: IndexedStack(
          index: currentPageIndex,
          children: [
            Scaffold(
              appBar: AppBar(
                title: Text("Explore"),
                centerTitle: true,
              ),
              body: ExplorePage()
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