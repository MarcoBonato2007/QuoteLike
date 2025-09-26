import 'package:flutter/material.dart';

import 'package:quotelike/utilities/enums.dart';
import 'package:quotelike/utilities/db_functions.dart' as db_functions;
import 'package:quotelike/utilities/globals.dart';
import 'package:quotelike/widgets/standard_widgets.dart';
import 'package:quotelike/widgets/validated_form.dart';

class SuggestionCreationPage extends StatefulWidget {
  const SuggestionCreationPage({super.key});

  @override
  State<SuggestionCreationPage> createState() => _SuggestionCreationPageState();
}

class _SuggestionCreationPageState extends State<SuggestionCreationPage> {
  final quoteCreationFormKey = GlobalKey<ValidatedFormState>();
  late Field contentField;
  late Field authorField;

  /// This is used instead of db_functions.addSuggestion()
  Future<void> addSuggestion() async {
    showLoadingIcon();
    
    ErrorCode? error = await db_functions.addSuggestion(
      quoteCreationFormKey.currentState!.text(contentField.id),
      quoteCreationFormKey.currentState!.text(authorField.id)
    );

    hideLoadingIcon();

    if (mounted) {
      Navigator.of(context).pop(); // remove the suggestion dialog
    }

    if (error != null && mounted) {
      showToast(context, error.errorText, Duration(seconds: 3));
    }
    else if (mounted) {
      showToast(context, "Suggestion received", Duration(seconds: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    contentField = Field(
      "Quote content",
      Icon(Icons.format_quote),
      false,
      (String? currentValue) {
        if (currentValue == null || currentValue == "") {
          return "Please enter quote content";
        }
        else if (currentValue.length > 250) {
          return "Content must be at most 250 characters";
        }
        else {
          return null;
        }
      }  
    );

    authorField = Field(
      "Author",
      Icon(Icons.person),
      false,
      (String? currentValue) {
        if (currentValue == null || currentValue == "") {
          return "Please enter an author";
        }
        else if (currentValue.length > 100) {
          return "Author must be at most 100 characters";
        }
        else {
          return null;
        }
      }   
    );

    final quoteCreationForm = ValidatedForm(
      key: quoteCreationFormKey,
      [contentField, authorField]
    );

    return AlertDialog(
      title: Text("Suggest a quote"),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        BackButton(),
        StandardElevatedButton(
          "Suggest quote",
          () async {
            if (quoteCreationFormKey.currentState!.validateAll()) {
              await addSuggestion();
            }
          }
        ),
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: quoteCreationForm
          ),
          SizedBox(height: 5),
        ]
      ),
    );
  }
}
