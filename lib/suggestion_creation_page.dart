
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotelike/utilities/constants.dart';
import 'package:quotelike/utilities/globals.dart';
import 'package:quotelike/utilities/rate_limiting.dart';
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

  Future<ErrorCode?> addSuggestion() async {
    final log = Logger("addSuggestion() in quote_creation_page.dart");
    ErrorCode? error = await RateLimits.QUOTE_SUGGESTION.testCooldown(FirebaseAuth.instance.currentUser!.uid);

    error ??= await firebaseErrorHandler(log, () async {
      await FirebaseFirestore.instance.collection("suggestions").add({
        "content": quoteCreationFormKey.currentState!.text(contentField.id),
        "author": quoteCreationFormKey.currentState!.text(authorField.id),
        "user": FirebaseAuth.instance.currentUser!.uid
      }).timeout(Duration(seconds: 5));
    });

    if (error == null) {
      await RateLimits.QUOTE_SUGGESTION.setTimestamp(FirebaseAuth.instance.currentUser!.uid);
    }

    return error;
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
        else if (currentValue.length > 500) {
          return "Content must be at most 500 characters";
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
      [
        contentField,
        authorField
      ]
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
              showLoadingIcon();
              ErrorCode? error = await addSuggestion();
              hideLoadingIcon();
              
              if (context.mounted) {
                Navigator.of(context).pop(); // remove the suggestion dialog
              }

              if (error != null && context.mounted) {
                showToast(context, error.errorText, Duration(seconds: 3));
              }
              else if (context.mounted) {
                showToast(context, "Suggestion received", Duration(seconds: 2));
              }
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
