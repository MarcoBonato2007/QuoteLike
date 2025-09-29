import 'package:cloud_firestore/cloud_firestore.dart' hide Filter;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

import 'package:quotelike/utilities/enums.dart';
import 'package:quotelike/utilities/globals.dart';
import 'package:quotelike/utilities/rate_limiting.dart';

/// Set the liked quotes global. This is used to future build the list of quotes.
/// 
/// Only call this for logged in users
Future<ErrorCode?> setLikedQuotes() async {
  final log = Logger("setLikedQuotes() in db_functions.dart");

  ErrorCode? error = await firebaseErrorHandler(log, () async {
    await FirebaseFirestore.instance
      .collection("users")
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection("liked_quotes")
    .get().timeout(Duration(seconds: 5)).then((QuerySnapshot querySnapshot) async {
      likedQuotes = querySnapshot.docs.map((doc) => doc.id).toSet();    
    }).timeout(Duration(seconds: 5));
  });

  return error;
}

/// Adds a suggestion to the suggestions collection
/// 
/// Only call this for logged in users
Future<ErrorCode?> addSuggestion(String content, String author) async {
  final log = Logger("addSuggestion() in db_functions.dart");

  ErrorCode? error = await RateLimits.QUOTE_SUGGESTION.testCooldown(FirebaseAuth.instance.currentUser!.uid);
  error ??= await firebaseErrorHandler(log, () async {
    await FirebaseFirestore.instance.collection("suggestions").add({
      "content": content,
      "author": author,
      "user": FirebaseAuth.instance.currentUser!.uid
    }).timeout(Duration(seconds: 5));
    await logEvent(Event.ADD_SUGGESTION);
  });
  if (error == null) {
    await RateLimits.QUOTE_SUGGESTION.setTimestamp(FirebaseAuth.instance.currentUser!.uid);
  }

  return error;
}

/// Likes a quote, removes the like is isDislike is true
/// 
/// Only call this for logged in users
Future<ErrorCode?> likeQuote(String quoteId, {bool isDislike = false}) async {
  final log = Logger("likeQuote() in db_functions.dart");

  DocumentReference quoteDocRef = FirebaseFirestore.instance.collection("quotes").doc(quoteId);
  DocumentReference likeDocRef = FirebaseFirestore.instance // this doc exists if the user liked this quote
    .collection("users")
    .doc(FirebaseAuth.instance.currentUser!.uid)
    .collection("liked_quotes")
  .doc(quoteId);

  ErrorCode? error = await firebaseErrorHandler(log, () async {
    await FirebaseFirestore.instance.runTransaction(timeout: Duration(seconds: 5), (transaction) async {
      final likeDocSnapshot = await transaction.get(likeDocRef);
      transaction.update( // update the likes on the quote doc
        quoteDocRef, 
        {"likes": FieldValue.increment(isDislike ? -1 : 1)}
      );
      if (likeDocSnapshot.exists) { // create/delete the liked quote doc
        transaction.delete(likeDocRef);
      }
      else {
        Map<String, dynamic> empty = {}; // passing {} directly into transaction.set() will cause an error
        transaction.set(likeDocRef, empty);
      }
    }).timeout(Duration(seconds: 5));
  });

  if (error == null) { // if no error, we update the liked quotes global
    if (isDislike) {
      likedQuotes.remove(quoteId);
    }
    else {
      likedQuotes.add(quoteId);
    }
  }

  return error;
}

