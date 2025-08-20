// Search bar on top (with selection menu for searching by author vs by content)
// Then is a filter button (random, most liked, liked by you, created by you (see bottom of comments))
// Then is the actual quotes
// Extra: a suggest quote button (adds to a firebase entry)
// Extra: each user can make their own custom quotes
  // Can be stored in their doc in a collection, e.g. "custom_quotes"
  // will need max length / max size limits

import 'package:flutter/material.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  Widget dropdownButton( // used for filter and sort buttons
    BuildContext context,
    List<Map<String, String>> options,
    String hintText,
    Icon icon,
    {double? widthOverride}
  ) {
    DropdownButtonFormField mainWidget = DropdownButtonFormField(
      elevation: 2,
      hint: Text(hintText),
      onChanged: (dynamic newValue) {},
      decoration: InputDecoration(
        prefixIcon: icon,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsetsGeometry.zero
      ),
      selectedItemBuilder: (BuildContext context) {
        return options.map((option) {
          return Text(option['value']!);
        }).toList();
      },
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option["value"],
          child: Text(option["label"]!)
        );
      }).toList()
    );

    if (widthOverride == null) {
      return IntrinsicWidth(child: mainWidget);
    }
    else {
      return SizedBox(width: widthOverride, child: mainWidget);
    }

  }

  Widget quoteCard(String quote, String author) {
    Card mainCard = Card(
      // TODO: Needs lots of formatting to make it look good
      // Check online for ideas!
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Column(
          children: [
            Text('“$quote”'),
            Text("- $author")
          ]
        ),
      )
    );

    return Row(children: [Expanded(child: mainCard)]);
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
        SearchBar(
          leading: Icon(Icons.search),
          elevation: WidgetStateProperty.all<double>(2),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10))),
          hintText: "Search for a quote",
        ),
        SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: (MediaQuery.of(context).size.width-15*2-155*2)/3,
          children: [
            dropdownButton(context, filterOptions, "Filter", Icon(Icons.filter_list), widthOverride: 155),
            dropdownButton(context, sortOptions, "Sort", Icon(Icons.sort), widthOverride: 155),
          ]
        ),
        SizedBox(height: 15),
        quoteCard("This is not a real quote", "HG wells")
      ]
    );
  }
}


// at the top: a search bar
  // left selection to choose whether to filter by author or content
// below that: a filter AND sort button
  // filter: liked by you, not liked by you, no filter
  // sort: random, most liked, least liked, recently added (quotes will need added timestamp)
// below that: a scrollable area containing the quotes.
  // use infinite_scroll_pagination
  // show a scrollbar in that area

// In future:
  // Creating custom quotes
    // Put an extra filter option (created by you) on filter button
    // Put a button at the bottom to create a quote (floating action button for explore page)
  // Extend the button on the bottom to suggest a public quote
  // Extend the sort button (top this month, top today, top this year, etc.)
