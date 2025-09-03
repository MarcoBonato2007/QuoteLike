import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

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
      value: initialValue,
      key: fieldKey,
      elevation: 2,
      hint: Text(hintText),
      onChanged: (dynamic newValue) {
        if (pagingController != null) {
          pagingController!.refresh();
        }
      },
      decoration: InputDecoration(
        prefixIcon: icon,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsetsGeometry.only(left: 10)
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

    return SizedBox(
      width: width + (trailingPadding ?? 0), 
      child: Padding(
        padding: EdgeInsets.only(right: trailingPadding ?? 0),
        child: mainWidget,
      )
    );
  }
}