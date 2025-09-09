
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotebook/constants.dart';
import 'package:quotebook/globals.dart';
import 'package:quotebook/standard_widgets.dart';
import 'package:quotebook/validated_form.dart';

class QuoteCreationPage extends StatefulWidget {
  const QuoteCreationPage({super.key});

  @override
  State<QuoteCreationPage> createState() => _QuoteCreationPageState();
}

class _QuoteCreationPageState extends State<QuoteCreationPage> {
  final quoteCreationFormKey = GlobalKey<ValidatedFormState>();
  late Field contentField;
  late Field authorField;

  Future<ErrorCode?> addSuggestion() async {
    final log = Logger("addSuggestion() in quote_creation_page.dart");
    ErrorCode? error;

    DocumentReference userDocRef = FirebaseFirestore.instance
      .collection("users")
      .doc(FirebaseAuth.instance.currentUser!.email);
    DocumentReference suggestionDocRef = FirebaseFirestore.instance
      .collection("suggestions")
      .doc();

    // using afterError instead of error = allows us to set error inside the firebaseErrorHandler()
    ErrorCode? afterError = await firebaseErrorHandler(log, () async {
      await FirebaseFirestore.instance.runTransaction(timeout: Duration(seconds: 5), (transaction) async {
        final userDocSnapshot = await transaction.get(userDocRef);
        int minutesSinceLastSuggestion = DateTime.timestamp().difference(userDocSnapshot["last_quote_suggestion"].toDate()).inMinutes;
        if (minutesSinceLastSuggestion >= 60) {
          transaction.set(
            suggestionDocRef, 
            {
              "content": quoteCreationFormKey.currentState!.text(contentField.id),
              "author": quoteCreationFormKey.currentState!.text(authorField.id),
            }
          );
          transaction.update(
            userDocRef, 
            {"last_quote_suggestion": Timestamp.now()}
          );
        }
        else {
          error = ErrorCodes.RECENT_SUGGESTION;
        }
      }).timeout(Duration(seconds: 5));  
    });
    error ??= afterError;

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
