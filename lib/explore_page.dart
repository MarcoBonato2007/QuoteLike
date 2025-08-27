// Search bar on top (with selection menu for searching by author vs by content)
// Then is a filter button (random, most liked, liked by you, created by you (see bottom of comments))
// Then is the actual quotes
// Extra: a suggest quote button (adds to a firebase entry)
// Extra: each user can make their own custom quotes
  // Can be stored in their doc in a collection, e.g. "custom_quotes"
  // will need max length / max size limits

import 'package:flutter/material.dart';
import 'package:quotebook/dropdown.dart';
import 'package:quotebook/quote_card.dart';
import 'package:quotebook/quote_search_bar.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  /// Gets the next ??? quotes for the user to scroll
  Future<void> getQuotes() async {
    // Remember to take filter and sort into account
    // figure out how to best get the NEXT x quotes
      // last time u did this by storing the id of the last quote currently loaded in
    // turn them into quote card objects!
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filterOptions = [
      {"value": "None", "label": "None"},
      {"value": "Liked", "label": "Liked by you"},
      {"value": "Not liked", "label": "Not liked by you"},
    ];
    List<Map<String, String>> sortOptions = [
      {"value": "Random", "label": "Random"},
      {"value": "Most liked", "label": "Most liked"},
      {"value": "Least liked", "label": "Least liked"},
      {"value": "Recent", "label": "Recent"},
    ];

    return Column(
      children: [
        QuoteSearchBar(),
        SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: (MediaQuery.of(context).size.width-15*2-155*2)/3,
          children: [
            Dropdown(context, filterOptions, "Filter", 155, icon: Icon(Icons.filter_list)),
            Dropdown(context, sortOptions, "Sort", 155, icon: Icon(Icons.sort)),
          ]
        ),
        SizedBox(height: 15),
        // TODO: add scrollable list with async loading from database
        QuoteCard("I have no special talent. I am only passionately curious.", "Albert Einstein")
      ]
    );
  }
}

// In future:
  // Creating custom quotes
    // Put an extra filter option (created by you) on filter button
    // Put a button at the bottom to create a quote (floating action button for explore page)
  // Extend the button on the bottom to suggest a public quote
  // Extend the sort button (top this month, top today, top this year, etc.)
