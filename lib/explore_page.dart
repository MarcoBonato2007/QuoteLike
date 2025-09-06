import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:logging/logging.dart';
import 'package:quotebook/constants.dart';
import 'package:quotebook/dropdown.dart';
import 'package:quotebook/globals.dart';
import 'package:quotebook/quote_card.dart';
import 'package:quotebook/quote_creation_page.dart';

class ExplorePage extends StatefulWidget {
  final List<String> likedQuotes;
  const ExplorePage(this.likedQuotes, {super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final sortKey = GlobalKey<FormFieldState>();
  final filterKey = GlobalKey<FormFieldState>();
  DocumentSnapshot? lastQuoteDoc;

  late final PagingController<int, QuoteCard> pagingController;

  @override
  void initState() {
    pagingController = PagingController<int, QuoteCard>(
      getNextPageKey: (state) => state.lastPageIsEmpty ? null : 0,
      fetchPage: (pageKey) async {
        ErrorCode? error;
        List<QuoteCard>? newQuotes;
        (error, newQuotes) = await getNextQuotesToScroll();
        if (error != null) {
          showToast(context, error.errorText, Duration(seconds: 3));
        }
        return newQuotes; // empty if there is an error
      }
    );
    pagingController.addListener(() {
      if (pagingController.items == null || pagingController.items!.isEmpty) {
        setState(() {lastQuoteDoc = null;});
      }
    });
    super.initState();
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

    if (filter != "None" && filter != null) {
      if (filter == "Liked") {
        query = query.where(FieldPath.documentId, whereIn: widget.likedQuotes);
      }
      else if (filter == "Not liked") {
        query = query.where(FieldPath.documentId, whereNotIn: widget.likedQuotes);
      }
    }
    
    if (sort == "Random") {
      // query = query.orderBy(FieldPath.documentId);
    }
    else if (sort == "Most liked") {
      query = query.orderBy("likes", descending: true);
    }
    else if (sort == "Least liked") {
      query = query.orderBy("likes", descending: false);
    }
    else if (sort == "Recent") {
      query = query.orderBy("creation", descending: true);
    }

    if (lastQuoteDoc != null) {
      query = query.startAfterDocument(lastQuoteDoc!);
    }
  
    query = query.limit(10);

    error = await firebaseErrorHandler(log, () async =>
      await query.get().then((QuerySnapshot querySnapshot) {
        for (DocumentSnapshot doc in querySnapshot.docs) {
          if (doc.id == "placeholder") {continue;}
          lastQuoteDoc = doc;
          queryResults.add(QuoteCard(
            doc.id, 
            doc["content"], 
            doc["author"], 
            doc["creation"], 
            doc["likes"],
            widget.likedQuotes.contains(doc.id)
          ));
        }
      }).timeout(Duration(seconds: 5))     
    );

    return (error, queryResults);
  }

  @override
  Widget build(BuildContext context) {
    // we don't actually use page key, we use lastQuoteDoc

    List<Map<String, String>> filterOptions = [
      {"value": "None", "label": "None"},
      {"value": "Liked", "label": "Liked by you"},
      {"value": "Not liked", "label": "Not liked by you"},
    ];
    List<Map<String, String>> sortOptions = [
      {"value": "Random", "label": "Random"},
      {"value": "Most liked", "label": "Most liked"},
      {"value": "Least liked", "label": "Least liked"},
      {"value": "Recent", "label": "Recent"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Explore"),
        centerTitle: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton( // button to suggest a quote
            elevation: 2,
            backgroundColor: ColorScheme.of(context).primary,
            foregroundColor: ColorScheme.of(context).surface,
            child: Icon(Icons.add),
            onPressed: () => showDialog(
              context: context, 
              builder: (context) => QuoteCreationPage()
            ),
          ),
          FloatingActionButton( // button to refresh the scrollable list of quotes
            elevation: 2,
            backgroundColor: ColorScheme.of(context).primary,
            foregroundColor: ColorScheme.of(context).surface,
            child: Icon(Icons.refresh),
            onPressed: () => throttledFunc(1000, () => pagingController.refresh())
          ),
        ],
      ),

      body: Column(
        children: [
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: (MediaQuery.of(context).size.width-15*2-155*2)/3,
            children: [
              Dropdown(context, filterKey, filterOptions, "Filter", 155, icon: Icon(Icons.filter_list), pagingController: pagingController),
              Dropdown(context, sortKey, sortOptions, "Sort", 155, icon: Icon(Icons.sort), pagingController: pagingController),
            ]
          ),
          SizedBox(height: 15),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height-300,
            child: PagingListener(
              controller: pagingController,
              builder: (context, state, fetchNextPage) => PagedListView(
                state: state,
                fetchNextPage: fetchNextPage,
                builderDelegate: PagedChildBuilderDelegate<QuoteCard>(
                  itemBuilder: (context, item, index) => item
                )
              )
            ),
          ),
        ]
      ),
    );
  }
}
