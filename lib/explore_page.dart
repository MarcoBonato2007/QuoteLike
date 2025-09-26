import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart' hide Filter;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:logging/logging.dart';

import 'package:quotelike/utilities/db_functions.dart' as db_functions;
import 'package:quotelike/utilities/enums.dart';
import 'package:quotelike/utilities/globals.dart';
import 'package:quotelike/widgets/dropdown.dart';
import 'package:quotelike/widgets/quote_card.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => ExplorePageState();
}

class ExplorePageState extends State<ExplorePage> {
  final sortKey = GlobalKey<FormFieldState>(); // passed into the sort dropdown()
  final filterKey = GlobalKey<FormFieldState>();
  DocumentSnapshot? lastQuoteDoc;
  late final PagingController<int, QuoteCard> pagingController;

  late Future<ErrorCode?> setLikedQuotesFuture;

  SplayTreeSet remainingLikedQuotes = SplayTreeSet<String>((a, b) => a.compareTo(b)); // used when filtering by liked quotes

  late String pivotPoint; // used when sorting (pseudo) randomly
  bool afterPivot = true; // get quotes before or after the pivot?

  @override
  void initState() {
    super.initState();
    pivotPoint = genRandomPivot();
    setLikedQuotesFuture = db_functions.setLikedQuotes(); // this avoids rebuilding the page when swapping back from settings
    pagingController = PagingController<int, QuoteCard>(
      getNextPageKey: (state) => state.lastPageIsEmpty ? null : 0,
      fetchPage: (pageKey) async {
        ErrorCode? error;
        List<QuoteCard>? newQuotes;
        (error, newQuotes) = await getNextQuotesToScroll();
        if (error != null) {
          showToast(context, error.errorText, Duration(seconds: 3));
        }
        return newQuotes;
      }
    );
    pagingController.addListener(() { // used so that lastQuoteDoc and quoteIds are set to null after a refresh
      if (pagingController.items == null || pagingController.items!.isEmpty) {
        setState(() {
          lastQuoteDoc = null;
          pivotPoint = genRandomPivot();
          afterPivot = true;
        });
      }
    });
  }

  @override
  void dispose() {
    pagingController.dispose();
    super.dispose();
  }

  String genRandomPivot() {
    late String randomPivot;
    final random = Random();

    // if randomly sorting and filtering by liked quotes, make the pivot be a random id from one of the elements
    Filter filter = filterKey.currentState!.value ?? Filter.NONE;
    Sort sort = sortKey.currentState!.value ?? Sort.NONE;
    if (filter == Filter.LIKED && sort == Sort.RANDOM) {
      randomPivot = likedQuotes.elementAt(random.nextInt(likedQuotes.length));
    }
    else {
      // generate a random pivot string
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
      randomPivot = String.fromCharCodes(Iterable.generate(20, (_) => chars.codeUnitAt(random.nextInt(chars.length))));    
    }

    return randomPivot;
  }

  void refresh() {
    pagingController.refresh();
    setLikedQuotesFuture = db_functions.setLikedQuotes(); // do NOT put this inside setState, will cause error
    setState(() {});
  }

  /// Gets the next 10 quotes to scroll after lastQuoteDoc
  /// 
  /// Returns any errors along with the list of new quotes
  Future<(ErrorCode?, List<QuoteCard>)> getNextQuotesToScroll() async {
    final log = Logger("getNextQuotesToScroll() in explore_page.dart");

    Filter filter = filterKey.currentState!.value ?? Filter.NONE;
    Sort sort = sortKey.currentState!.value ?? Sort.NONE;

    Query query = FirebaseFirestore.instance.collection("quotes");
    List<QuoteCard> queryResults = [];

    ErrorCode? error;
    
    Set<String> likedQuotesSplice = {}; // used if the filter is Filter.LIKED
    if (filter == Filter.LIKED) {
      if (lastQuoteDoc == null && afterPivot) { // if starting out, set the remaining liked quotes to all of them
        remainingLikedQuotes = SplayTreeSet<String>.from(likedQuotes, (a, b) => a.compareTo(b));
      }
      if (remainingLikedQuotes.isEmpty) { // if no liked quotes left to get, return empty and stop the scrolling
        return (error, queryResults);
      }

      // if the filter is liked and the sort is random, we disable the default random sort behaviour and simulatae it inside the splicing
      if (sort == Sort.RANDOM) {
        for (String quoteId in remainingLikedQuotes.where((element) => afterPivot ? (element.compareTo(pivotPoint) >= 0) : element.compareTo(pivotPoint) < 0)) {
          likedQuotesSplice.add(quoteId);
          if (likedQuotesSplice.length == 10) {break;}
        }
      }
      else {
        for (String quoteId in remainingLikedQuotes) {
          likedQuotesSplice.add(quoteId);
          if (likedQuotesSplice.length == 10) {break;}
        }
      }

      remainingLikedQuotes.removeAll(likedQuotesSplice);
    }

    query = switch (filter) {
      Filter.LIKED => likedQuotesSplice.isNotEmpty ? query.where(FieldPath.documentId, whereIn: likedQuotesSplice) : query,
      Filter.NONE => query,
    };

    query = switch (sort) {
      Sort.MOST_LIKED => query.orderBy("likes", descending: true),
      Sort.LEAST_LIKED => query.orderBy("likes", descending: false),
      Sort.RECENT => query.orderBy("creation", descending: true),
      Sort.RANDOM => filter != Filter.LIKED ? (afterPivot ? query.where(FieldPath.documentId, isGreaterThanOrEqualTo: pivotPoint) : query.where(FieldPath.documentId, isLessThan: pivotPoint)) : query,
      Sort.NONE => query,
    };

    if (lastQuoteDoc != null) {
      query = query.startAfterDocument(lastQuoteDoc!);
    }
  
    query = query.limit(10);

    if (!(filter == Filter.LIKED && likedQuotesSplice.isEmpty)) {
      error ??= await firebaseErrorHandler(log, () async =>
        await query.get().timeout(Duration(seconds: 5)).then((QuerySnapshot querySnapshot) {
          for (DocumentSnapshot doc in querySnapshot.docs) {
            lastQuoteDoc = doc;
            queryResults.add(QuoteCard(
              doc.id, 
              doc["content"], 
              doc["author"], 
              doc["creation"], 
              doc["likes"],
              likedQuotes.contains(doc.id)
            ));
          }
        }).timeout(Duration(seconds: 5))     
      );

    }

    // if we've reached no more quotes after the pivot, go back to before the pivot
    if (queryResults.isEmpty && sort == Sort.RANDOM && afterPivot) {
      afterPivot = false; // wrap back to beginning, go to before pivot
      lastQuoteDoc = null;
      (error, queryResults) = await getNextQuotesToScroll();
    }

    return (error, queryResults);
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filterOptions = [
      for (Filter filter in Filter.values) {"name": filter.name, "label": filter.label, "value": filter}
    ];
    List<Map<String, dynamic>> sortOptions = [
      for (Sort sort in Sort.values) {"name": sort.name, "label": sort.label, "value": sort}
    ];

    Widget quoteList = FutureBuilder( // we future build the quote list after we set the list of liked quotes
      future: setLikedQuotesFuture,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        else if (asyncSnapshot.hasError || (asyncSnapshot.hasData && asyncSnapshot.data != null)) {
          ErrorCode error = asyncSnapshot.data ?? ErrorCode.UNKNOWN_ERROR;
          return Padding(
            padding: const EdgeInsets.only(left: 15, right: 15), // for some reason, i have to re-add the padding here
            child: Center(child: Text("${error.errorText} Try reloading (bottom right button).")),
          );
        }
        else {
          return PagingListener(
            controller: pagingController,
            builder: (context, state, fetchNextPage) => PagedListView(
              state: state,
              fetchNextPage: fetchNextPage,
              builderDelegate: PagedChildBuilderDelegate<QuoteCard>(
                itemBuilder: (context, item, index) => item
              )
            )
          );
        }
      }
    );

    return Column(
      children: [
        SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: (MediaQuery.of(context).size.width-15*2-171*2)/3,
          children: [
            Dropdown(context, filterKey, filterOptions, "Filter", 171, icon: Icon(Icons.filter_list), pagingController: pagingController),
            Dropdown(context, sortKey, sortOptions, "Sort", 171, icon: Icon(Icons.sort), pagingController: pagingController),
          ]
        ),
        SizedBox(height: 10),
        Expanded(child: quoteList),
      ]
    );
  }
}
