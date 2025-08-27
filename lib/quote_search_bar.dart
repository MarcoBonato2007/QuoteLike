import 'package:flutter/material.dart';
import 'package:quotebook/dropdown.dart';

class QuoteSearchBar extends StatelessWidget {
  QuoteSearchBar({super.key});

  final controller = TextEditingController();

  /// Performs the search and returns quotes as results, ranked
  Future<void> search(String input) async {
    // TODO: make this work
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> searchOptions = [
      {"value": "Author", "label": "Author"},
      {"value": "Content", "label": "Content"}
    ];

    return SearchBar(
      controller: controller,
      leading: Dropdown(context, searchOptions, "Search by", 110, trailingPadding: 5),
      trailing: [IconButton(
        icon: Icon(Icons.search),
        onPressed: () async => await search(controller.text)
      )],
      onSubmitted: (String inputtedValue) async => await search(inputtedValue),
      padding: WidgetStatePropertyAll(EdgeInsetsGeometry.only(left: 8, right: 0)),
      elevation: WidgetStateProperty.all<double>(2),
      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10))),
      textStyle: WidgetStatePropertyAll(TextStyle()),
      hintText: "Search for a quote",
    );
  }
}