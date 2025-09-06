
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

  Future<ErrorCode?> attemptSuggestion() async {
    final log = Logger("Attempt to make suggestion");
    ErrorCode? error;

    DocumentReference userDocRef = FirebaseFirestore.instance
      .collection("users")
      .doc(FirebaseAuth.instance.currentUser!.email);
    bool tooRecent = true;
    error = await firebaseErrorHandler(log, () async {
      await userDocRef.get().then((DocumentSnapshot userDoc) async {
        int minutesSinceLastSuggestion = DateTime.timestamp().difference(userDoc["last_quote_suggestion"].toDate()).inMinutes;
        if (minutesSinceLastSuggestion >= 60 && mounted) {
          tooRecent = false;
        }
      }).timeout(Duration(seconds: 5));      
    });
    if (error != null) { // we always return the first error encoutnered
      return error;
    }

    if (tooRecent) {
      return ErrorCodes.RECENT_SUGGESTION;
    }
    else {
      error = await addSuggestion();
    }

    return error;
  }

  Future<ErrorCode?> addSuggestion() async {
    final log = Logger("Adding a quote suggestion");
    ErrorCode? error;

    // add the suggestion to the collection
    final collectionRef = FirebaseFirestore.instance.collection("suggestions");
    error = await firebaseErrorHandler(log, () async {
      await collectionRef.add({
        "content": quoteCreationFormKey.currentState!.text(contentField.id),
        "author": quoteCreationFormKey.currentState!.text(authorField.id),
      }).timeout(Duration(seconds: 5));      
    });
    if (error != null) { // we always return the first error encountered
      return error;
    }

    // set a new timestamp
    error = await firebaseErrorHandler(log, () async {
      await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.email)
        .update({"last_quote_suggestion": Timestamp.now()})
      .timeout(Duration(seconds: 5));      
    });


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
              ErrorCode? error = await attemptSuggestion();
              if (context.mounted) {
                Navigator.of(context).pop(); // remove the suggestion dialog
              }
              if (error != null && context.mounted) {
                showToast(context, error.errorText, Duration(seconds: 3));
              }
              else if (context.mounted) {
                showToast(context, "Suggestion received", Duration(seconds: 2));
              }
              hideLoadingIcon();
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
