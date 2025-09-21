import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:quotelike/utilities/theme_settings.dart';

/// Used to make dropdown menus (used in explore_page.dart)
class Dropdown extends StatelessWidget {
  final BuildContext context;
  final GlobalKey<FormFieldState> fieldKey;
  final List<Map<String, String>> options;
  final String hintText;
  final double width;
  final Icon? icon;
  final double? trailingPadding;
  final PagingController? pagingController; // call .refresh after changing sort or filter
  final String? initialValue;
  const Dropdown(
    this.context,
    this.fieldKey,
    this.options,
    this.hintText,
    this.width,
    {
      this.icon,
      this.trailingPadding,
      this.pagingController,
      this.initialValue,
      super.key
    }
  );

  @override
  Widget build(BuildContext context) {
    DropdownButtonFormField mainWidget = DropdownButtonFormField(
      isDense: true,
      initialValue: initialValue,
      key: fieldKey,
      padding: EdgeInsetsGeometry.zero,
      elevation: Provider.of<ThemeSettings>(context, listen: false).elevation.toInt(),
      hint: Text(hintText),
      onChanged: (dynamic newValue) {
        pagingController?.refresh();
      },
      decoration: InputDecoration(
        prefixIcon: icon,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsetsGeometry.zero
      ),
      selectedItemBuilder: (BuildContext context) {
        return options.map((option) {
          return Text(option['name']!);
        }).toList();
      },
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option["name"],
          child: Text(option["label"]!)
        );
      }).toList()
    );

    return SizedBox(
      width: width + (trailingPadding ?? 0), 
      child: Padding(
        padding: EdgeInsets.only(right: trailingPadding ?? 0),
        child: mainWidget,
      )
    );
  }
}