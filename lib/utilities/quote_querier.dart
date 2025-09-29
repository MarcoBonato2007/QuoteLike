import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' hide Filter;
import 'package:logging/logging.dart';
import 'package:quotelike/utilities/enums.dart';
import 'package:quotelike/utilities/globals.dart';

/// Quote querier is responsible for fetching the quotes to scroll in explore_page.dart
class QuoteQuerier {
  /// This is used when filtering by liked quotes
  Set<String> _remainingLikedQuotes = {...likedQuotes};

  /// When random sort is enabled, only quotes with id's >= [_pivotPoint] are retrieved.
  /// This creates a pseudo-random sort.
  /// 
  /// Once no more quotes are found, [_afterPivot] is set to false and only quotes with
  /// id's < pivotPoint are retrieved.
  late String _pivotPoint;
  bool _afterPivot = true; // get quotes before or after the pivot?

  /// All queries get quotes only starting after lastQuoteDoc.
  /// This stops queries from repeating quotes.
  /// 
  /// This is set to null when we want to get the initial quotes.
  DocumentSnapshot? _lastQuoteDoc;

  /// a refresh() call indicates that we want to restart the quote scrolling
  /// process back from the beginning.
  /// 
  /// This is important because makeQuery() calls work in sequence.
  void refresh(Filter filter, Sort sort) {
    _lastQuoteDoc = null;
    _pivotPoint = genPivot(filter, sort);
    _afterPivot = true;
    _remainingLikedQuotes = {...likedQuotes};
  }

  /// Generate a new pivot for the random sort
  String genPivot(Filter filter, Sort sort) {
    late String newPivot;

    final random = Random();
    // if randomly sorting and filtering by liked quotes, make the pivot be a random id from one of the elements
    // we can't randomly generate a string since the pool of liked quotes id's could be very small
    if (filter == Filter.LIKED && sort == Sort.RANDOM) {
      int randomIndex = random.nextInt(likedQuotes.length);
      newPivot = likedQuotes.elementAt(randomIndex);
    }
    else {
      // generate a random pivot string, simulating choosing a random quote id
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
      newPivot = String.fromCharCodes(Iterable.generate(20, (_) => chars.codeUnitAt(random.nextInt(chars.length))));    
    }

    return newPivot;
  }

  /// Applies filters to a query
  Query applyFilter(Query query, Filter filter, Sort sort) {
    if (filter == Filter.LIKED) {
      // if filtering by liked quotes, we batch the liked quotes in grouops of 10 using whereIn
      // we need to do this since whereIn has a limit of 30 elements

      Set<String> likedQuotesBatch = _remainingLikedQuotes.where((element) {
        if (sort != Sort.RANDOM) { // if the sort isn't random, we can take any element
          return true; 
        }
        else if (_afterPivot) { // otherwise, we only take elements adhering to the pivot
          return element.compareTo(_pivotPoint) >= 0;
        }
        else {
          return element.compareTo(_pivotPoint) < 0;
        }
      })
      .take(10) // only take at most the first 10 quotes
      .toSet();

      if (likedQuotesBatch.isEmpty) {
        // we can't pass empty to whereIn, so we make a query that guarantees an empty result
        query = query.where("likes", isEqualTo: -1);
      }
      else {
        query = query.where(FieldPath.documentId, whereIn: likedQuotesBatch); 
      }
    }
    
    return query;
  }

  /// Applies sorts to a query
  Query applySort(Query query, Sort sort) {
    query = switch (sort) {
      Sort.MOST_LIKED => query.orderBy("likes", descending: true),
      Sort.LEAST_LIKED => query.orderBy("likes", descending: false),
      Sort.RECENT => query.orderBy("creation", descending: true),
      Sort.RANDOM => _afterPivot ? query.where(FieldPath.documentId, isGreaterThanOrEqualTo: _pivotPoint)
                                : query.where(FieldPath.documentId, isLessThan: _pivotPoint),
      Sort.NONE => query,
    };

    return query;
  }
  
  /// Gets the next 10 quotes to scroll along with an error code.
  /// The returned list is empty if there are no more quotes to scroll.
  Future<(ErrorCode?, List<DocumentSnapshot>)> makeQuery(Filter filter, Sort sort) async {
    final log = Logger("makeQuery() in quote_querier.dart");

    Query query = FirebaseFirestore.instance.collection("quotes");
    query = applyFilter(query, filter, sort);
    query = applySort(query, sort);      

    if (_lastQuoteDoc != null) {
      query = query.startAfterDocument(_lastQuoteDoc!);
    }
  
    query = query.limit(10);

    List<DocumentSnapshot> queryResults = [];
    ErrorCode? error = await firebaseErrorHandler(log, () async =>
      await query.get().timeout(Duration(seconds: 5)).then((QuerySnapshot querySnapshot) {
        queryResults = querySnapshot.docs;
      }).timeout(Duration(seconds: 5))
    );

    // only if the error is null and filter is liked, remove these quotes from the ones left to get
    if (error == null && filter == Filter.LIKED) {
      _remainingLikedQuotes.removeAll(queryResults.map((element) => element.id));
    }
  
    // if we've reached no more quotes after the pivot while sorting randomly, 
    // then we start querying again but this time using afterPivot = false
    if (queryResults.isEmpty && sort == Sort.RANDOM && _afterPivot) {
      _afterPivot = false; // wrap back to beginning, go to before pivot
      _lastQuoteDoc = null;
      (error, queryResults) = await makeQuery(filter, sort);
    }

    return (error, queryResults);
  }
}