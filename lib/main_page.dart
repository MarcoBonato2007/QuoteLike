import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quotelike/explore_page.dart';
import 'package:quotelike/suggestion_creation_page.dart';
import 'package:quotelike/settings_page.dart';
import 'package:quotelike/theme_settings.dart';
import 'package:quotelike/rate_limiting.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentPageIndex = 0; // 0 means explore, 1 means settings
  
  final explorePageKey = GlobalKey<ExplorePageState>(); // used to access the paging controller inside explore page

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
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FloatingActionButton( // button to suggest a quote
                    elevation: Provider.of<ThemeSettings>(context, listen: false).elevation,
                    backgroundColor: ColorScheme.of(context).primary,
                    foregroundColor: ColorScheme.of(context).surface,
                    child: Icon(Icons.add),
                    onPressed: () => showDialog(
                      context: context, 
                      builder: (context) => SuggestionCreationPage()
                    ),
                  ),
                  FloatingActionButton( // button to refresh the scrollable list of quotes
                    elevation: Provider.of<ThemeSettings>(context, listen: false).elevation,
                    backgroundColor: ColorScheme.of(context).primary,
                    foregroundColor: ColorScheme.of(context).surface,
                    child: Icon(Icons.refresh),
                    onPressed: () => throttledFunc(1000, () {
                      explorePageKey.currentState!.refresh();                  
                    })
                  ),
                ],
              ),
              body: ExplorePage(key: explorePageKey)
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