import 'package:flutter/material.dart';

import 'package:quotelike/explore_page.dart';
import 'package:quotelike/utilities/enums.dart';

/// Used to make dropdown menus (used in explore_page.dart)
class Dropdown extends StatelessWidget {
  final BuildContext context;
  final GlobalKey<FormFieldState> fieldKey;
  final List<DropdownOption> options; // see utilities/enums.dart
  final String hintText;
  final double width;
  final Icon icon;
  final GlobalKey<ExplorePageState> explorePageKey; // call .refresh after changing sort or filter
  const Dropdown(
    this.context,
    this.fieldKey,
    this.options,
    this.hintText,
    this.width,
    this.icon,
    this.explorePageKey,
    {
      super.key
    }
  );

  @override
  Widget build(BuildContext context) {
    DropdownButtonFormField mainWidget = DropdownButtonFormField(
      key: fieldKey,
      hint: Text(hintText),
      onChanged: (dynamic newValue) {
        explorePageKey.currentState!.refresh();
      },
      decoration: InputDecoration(
        prefixIcon: icon,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsetsGeometry.zero
      ),
      selectedItemBuilder: (BuildContext context) {
        return options.map((option) {
          return Text(option.labelInField);
        }).toList();
      },
      items: options.map((option) {
        return DropdownMenuItem<DropdownOption>( // the value's type should be a Filter or Sort enum
          value: option,
          child: Text(option.labelInDropdown)
        );
      }).toList()
    );

    return SizedBox(
      width: width,
      child: mainWidget
    );
  }
}
