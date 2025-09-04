
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotebook/constants.dart';
import 'package:quotebook/globals.dart';

class QuoteCreationPage extends StatefulWidget {
  const QuoteCreationPage({super.key});

  @override
  State<QuoteCreationPage> createState() => _QuoteCreationPageState();
}

class _QuoteCreationPageState extends State<QuoteCreationPage> {
  final contentController = TextEditingController();
  final contentKey = GlobalKey<FormFieldState>();
  ErrorCode? contentError;

  final authorController = TextEditingController();
  final authorKey = GlobalKey<FormFieldState>();
  ErrorCode? authorError;

  Future<ErrorCode?> attemptSuggestion() async {
    final log = Logger("Attempt to make suggestion");
    ErrorCode? error;

    DocumentReference userDocRef = FirebaseFirestore.instance
      .collection("users")
      .doc(FirebaseAuth.instance.currentUser!.email);
    await userDocRef.get().then((DocumentSnapshot userDoc) async {
      Map<String, dynamic> userDocData = userDoc.data() as Map<String, dynamic>;
      int minutesSinceLastSuggestion = DateTime.timestamp().difference(userDocData["last_quote_suggestion"].toDate()).inMinutes;
      if (minutesSinceLastSuggestion >= 60 && mounted) {
        error = await addSuggestion();
      }
      else {
        error = ErrorCodes.RECENT_SUGGESTION;
      }
    }).timeout(Duration(seconds: 5)).catchError((firestoreError) {
      error = firestoreErrorHandler(log, firestoreError);
    }); // catch any errors (ignored for now)

    return error;
  }

  Future<ErrorCode?> addSuggestion() async {
    final log = Logger("Adding a quote suggestion");
    ErrorCode? error;

    // add the suggestion to the collection
    final collectionRef = FirebaseFirestore.instance.collection("suggestions");
    await collectionRef.add({
      "content": contentController.text,
      "author": authorController.text,
    }).timeout(Duration(seconds: 5)).catchError((firestoreError) {
      error = firestoreErrorHandler(log, firestoreError);
    });
    if (error != null) { // we always return the first error encountered
      return error;
    }

    // set a new timestamp
    await FirebaseFirestore.instance
      .collection("users")
      .doc(FirebaseAuth.instance.currentUser!.email)
      .update({"last_quote_suggestion": Timestamp.now()})
      .timeout(Duration(seconds: 5))
    .catchError((firestoreError) {
      error = firestoreErrorHandler(log, firestoreError);
    });

    return error;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Suggest a quote"),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        BackButton(),
        elevatedButton(
          context,
          "Suggest quote",
          () async {
            authorKey.currentState!.validate();
            contentKey.currentState!.validate();
            if (authorKey.currentState!.validate() && contentKey.currentState!.validate()) {
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
            child: textFormField(
              contentController,
              contentKey,
              "Quote content",
              contentError,
              Icon(Icons.format_quote),
              (String? currentValue) => setState(() {
                contentError = null; 
                authorError = null;
              }),
              (String? currentValue) {
                if (currentValue == null || currentValue == "") {
                  return "Please enter quote content";
                }
                else {
                  return null;
                }
              }
            ),
          ),
          SizedBox(height: 5),
          textFormField(
            authorController,
            authorKey,
            "Author",
            authorError,
            Icon(Icons.person),
            (String? currentValue) => setState(() {
              contentError = null; 
              authorError = null;
            }),
            (String? currentValue) {
              if (currentValue == null || currentValue == "") {
                return "Please enter an author";
              }
              else {
                return null;
              }
            }
          ),
        ]
      ),
    );
  }
}
