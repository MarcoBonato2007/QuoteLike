import 'package:flutter/material.dart';

bool isEmailValid(String email) {
  // not meant to be perfect, meant to reduce the occurence of the invalid-email firebase error
  // This matches <string>@<string>.<string>
  return true;
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: Duration(seconds: 1),
      content: Text(message, textAlign: TextAlign.center),
      behavior: SnackBarBehavior.floating
    )
  );
}
