import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart' hide Filter;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:logging/logging.dart';

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

  @override
  void initState() {
    super.initState();
    setLikedQuotesFuture = setLikedQuotes(); // this avoids rebuilding the page when swapping back from settings
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
        });
      }
    });
  }

  @override
  void dispose() {
    pagingController.dispose();
    super.dispose();
  }

  void refresh() {
    pagingController.refresh();
    setLikedQuotesFuture = setLikedQuotes(); // do NOT put this inside setState, will cause error
    setState(() {});
  }

  /// Set the liked quotes global. This is used to future build the list of quotes.
  Future<ErrorCode?> setLikedQuotes() async {
    final log = Logger("getLikedQuotes() in main_page.dart");

    likedQuotes = {}; 
    ErrorCode? error = await firebaseErrorHandler(log, () async {
      await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("liked_quotes")
      .get().timeout(Duration(seconds: 5)).then((QuerySnapshot querySnapshot) async {
        for (DocumentSnapshot doc in querySnapshot.docs) {
          likedQuotes.add(doc.id);
        }          
      }).timeout(Duration(seconds: 5));
    });

    return error;
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

    if (filter == Filter.LIKED && likedQuotes.isEmpty) {
      return (error, queryResults);
    }

    query = switch (filter) {
      Filter.LIKED => query.where(FieldPath.documentId, whereIn: likedQuotes),
      // if liked qutoes is empty then we don't change the query (cannot pass an empty list to whereNotIn)
      Filter.NOT_LIKED => likedQuotes.isNotEmpty ? query.where(FieldPath.documentId, whereNotIn: likedQuotes): query,
      Filter.NONE => query,
    };

    query = switch (sort) {
      Sort.MOST_LIKED => query.orderBy("likes", descending: true),
      Sort.LEAST_LIKED => query.orderBy("likes", descending: false),
      Sort.RECENT => query.orderBy("creation", descending: true),
      Sort.NONE => query,
    };

    if (lastQuoteDoc != null) {
      query = query.startAfterDocument(lastQuoteDoc!);
    }
  
    query = query.limit(10);

    error = await firebaseErrorHandler(log, () async =>
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
