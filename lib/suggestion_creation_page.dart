import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:quotelike/utilities/enums.dart';
import 'package:quotelike/utilities/db_functions.dart' as db_functions;
import 'package:quotelike/utilities/globals.dart';
import 'package:quotelike/widgets/validated_form.dart';

class SuggestionCreationPage extends StatefulWidget {
  const SuggestionCreationPage({super.key});

  @override
  State<SuggestionCreationPage> createState() => _SuggestionCreationPageState();
}

class _SuggestionCreationPageState extends State<SuggestionCreationPage> {
  final _suggestionFormKey = GlobalKey<ValidatedFormState>();
  late Field _contentField;
  late Field _authorField;

  /// This is used instead of db_functions.addSuggestion()
  Future<void> addSuggestion() async {
    showLoadingIcon();
    
    ErrorCode? error = await db_functions.addSuggestion(
      _suggestionFormKey.currentState!.text(_contentField.id),
      _suggestionFormKey.currentState!.text(_authorField.id)
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
    _contentField = Field(
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
      },
      inputFormatters: [
        LengthLimitingTextInputFormatter(250)
      ],
      expandsVertically: true
    );

    _authorField = Field(
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
      },
      inputFormatters: [
        LengthLimitingTextInputFormatter(100)
      ],
      expandsVertically: true
    );

    final quoteCreationForm = ValidatedForm(
      key: _suggestionFormKey,
      [_contentField, _authorField]
    );

    final suggestQuoteButton = FilledButton(
      child: Text("Suggest quote"),
      onPressed: () async {
        if (_suggestionFormKey.currentState!.validateAll()) {
          await addSuggestion();
        }
      }
    );

    return AlertDialog(
      title: Text("Suggest a quote"),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        BackButton(),
        suggestQuoteButton
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: quoteCreationForm
          ),
        ]
      ),
    );
  }
}
