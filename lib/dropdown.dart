import 'package:flutter/material.dart';

class Dropdown extends StatelessWidget {
  final BuildContext context;
  final List<Map<String, String>> options;
  final String hintText;
  final double width;
  final Icon? icon;
  final double? trailingPadding;
  const Dropdown(
    this.context,
    this.options,
    this.hintText,
    this.width,
    {
      this.icon,
      this.trailingPadding,
      super.key
    }
  );

  @override
  Widget build(BuildContext context) {
    DropdownButtonFormField mainWidget = DropdownButtonFormField(
      elevation: 2,
      hint: Text(hintText),
      onChanged: (dynamic newValue) {},
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