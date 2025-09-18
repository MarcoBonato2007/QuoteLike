import 'package:flutter/material.dart';

// All of these are widgets with a pre-set hardcoded style, to enforce design consistency
// These are used over the default versions of their widgets

class StandardTextButton extends StatelessWidget {
  final String text;
  final void Function() onPressed;
  const StandardTextButton(this.text, this.onPressed, {super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: Size.zero, 
        padding: EdgeInsetsGeometry.only(left: 6, right: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap
      ),
      onPressed: onPressed,
      child: Text(text)
    );
  }
}

class StandardElevatedButton extends StatelessWidget {
  final String text;
  final void Function() onPressed;
  const StandardElevatedButton(this.text, this.onPressed, {super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorScheme.of(context).primary,
        foregroundColor: ColorScheme.of(context).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10))  
      ),
      child: Text(text)
    );
  }
}

class StandardSettingsButton extends StatelessWidget {
  final String text;
  final Icon icon;
  final void Function() onPressed;
  const StandardSettingsButton(this.text, this.icon, this.onPressed, {super.key});

  @override
  Widget build(BuildContext context) {
    ElevatedButton mainButton = ElevatedButton.icon(
      label: Text(text),
      icon: icon,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10)) 
      ),
      onPressed: onPressed
    );

    return Row(children: [Expanded(child: mainButton)]);
  }
}
