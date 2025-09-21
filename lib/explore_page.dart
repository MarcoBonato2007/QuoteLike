import 'package:cloud_firestore/cloud_firestore.dart' hide Filter;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:logging/logging.dart';
import 'package:quotelike/utilities/enums.dart';
import 'package:quotelike/widgets/dropdown.dart';
import 'package:quotelike/utilities/globals.dart';
import 'package:quotelike/widgets/quote_card.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => ExplorePageState();
}

class ExplorePageState extends State<ExplorePage> {
  final sortKey = GlobalKey<FormFieldState>();
  final filterKey = GlobalKey<FormFieldState>();
  DocumentSnapshot? lastQuoteDoc;

  late Future<(ErrorCode?, List<String>)> likedQuotesFuture;
  List<String>? likedQuotes;
  late final PagingController<int, QuoteCard> pagingController;

  /// Gets a list of liked user quotes, this is passed into ExplorePage() in a FutureBuilder()
  Future<(ErrorCode?, List<String>)> getLikedQuotes() async {
    final log = Logger("getLikedQuotes() in main_page.dart");

    List<String> likedQuotes = [];    
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

    return (error, likedQuotes);
  }

  @override
  void initState() {
    super.initState();
    likedQuotesFuture = getLikedQuotes(); // put here to avoid explore page rebuilding if you go back to it from settings
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
    pagingController.addListener(() { // used so that lastQuoteDoc is set to null after a refresh
      if (pagingController.items == null || pagingController.items!.isEmpty) {
        setState(() {lastQuoteDoc = null;});
      }
    });
  }

  /// Gets the next 10 quotes to scroll after lastQuoteDoc
  /// 
  /// Returns any errors along with the list of new quotes
  Future<(ErrorCode?, List<QuoteCard>)> getNextQuotesToScroll() async {
    final log = Logger("getNextQuotesToScroll() in explore_page.dart");
    ErrorCode? error;

    String? filter = filterKey.currentState!.value;
    String? sort = sortKey.currentState!.value;

    Query query = FirebaseFirestore.instance.collection("quotes");
    List<QuoteCard> queryResults = [];
    
    if (filter == Filter.LIKED.name) {
      query = query.where(FieldPath.documentId, whereIn: likedQuotes);
    }
    else if (filter == Filter.NOT_LIKED.name) {
      query = query.where(FieldPath.documentId, whereNotIn: likedQuotes);
    }

    if (sort == Sort.MOST_LIKED.name) {
      query = query.orderBy("likes", descending: true);
    }
    else if (sort == Sort.LEAST_LIKED.name) {
      query = query.orderBy("likes", descending: false);
    }
    else if (sort == Sort.RECENT.name) {
      query = query.orderBy("creation", descending: true);
    }

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
            likedQuotes!.contains(doc.id)
          ));
        }
      }).timeout(Duration(seconds: 5))     
    );

    return (error, queryResults);
  }

  void refresh() {
    if (likedQuotes != null) {
      pagingController.refresh();
    }
    else {
      likedQuotes = null;
      likedQuotesFuture = getLikedQuotes();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filterOptions = [
      for (Filter filter in Filter.values) {"name": filter.name, "label": filter.label}
    ];
    List<Map<String, String>> sortOptions = [
      for (Sort sort in Sort.values) {"name": sort.name, "label": sort.label}
    ];

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
        Expanded(
          child: FutureBuilder(
            future: likedQuotesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              else if (snapshot.hasError || (snapshot.hasData && snapshot.data!.$1 != null)) {
                ErrorCode? error = snapshot.data!.$1 ?? ErrorCode.UNKNOWN_ERROR;
                return Center(child: Text("${error.errorText}. Try reloading (bottom right button)."));
              }
              else {
                likedQuotes = snapshot.data!.$2;
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
          ),
        ),
      ]
    );
  }
}
