import 'package:flutter/material.dart';

import 'package:quotelike/explore_page.dart';
import 'package:quotelike/utilities/enums.dart';

/// Used to make dropdown menus (used in explore_page.dart)
class Dropdown extends StatefulWidget {
  final BuildContext context;
  final GlobalKey<FormFieldState> fieldKey;
  final List<DropdownOption> options; // see utilities/enums.dart
  final DropdownOption defaultOption; // NOT an initial option
  final String hintText;
  final double width;
  final Icon icon;
  final GlobalKey<ExplorePageState> explorePageKey; // call .refresh after changing sort or filter
  const Dropdown(
    this.context,
    this.fieldKey,
    this.options,
    this.defaultOption,
    this.hintText,
    this.width,
    this.icon,
    this.explorePageKey,
    {
      super.key
    }
  );

  @override
  State<Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> {
  /// Keeps track of the last value set to this dropdown.
  /// This is used to check if the value changed or stayed the same.
  late DropdownOption lastValue;

  @override
  void initState() {
    super.initState();
    lastValue = widget.defaultOption; // the first value in options is the default value, i.e. either Sort.NONE or Filter.NONE
  }

  @override
  Widget build(BuildContext context) {
    DropdownButtonFormField mainWidget = DropdownButtonFormField(
      key: widget.fieldKey,
      hint: Text(widget.hintText),
      onChanged: (dynamic newValue) {
        newValue ??= widget.defaultOption; // newValue can be null, this represents default option
        if (lastValue != newValue) {
          widget.explorePageKey.currentState!.checkFilterSortCompatibility(widget.options == Sort.values);
          widget.explorePageKey.currentState!.refresh();          
        }
        lastValue = newValue;
      },
      decoration: InputDecoration(
        prefixIcon: widget.icon,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsetsGeometry.zero
      ),
      selectedItemBuilder: (BuildContext context) {
        return widget.options.map((option) {
          return Text(option.labelInField);
        }).toList();
      },
      items: widget.options.map((option) {
        return DropdownMenuItem<DropdownOption>( // the value's type should be a Filter or Sort enum
          value: option,
          child: Text(option.labelInDropdown)
        );
      }).toList()
    );

    return SizedBox(
      width: widget.width,
      child: mainWidget
    );
  }
}
