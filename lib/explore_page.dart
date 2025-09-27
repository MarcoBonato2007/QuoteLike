import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart' hide Filter;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:quotelike/utilities/db_functions.dart' as db_functions;
import 'package:quotelike/utilities/enums.dart';
import 'package:quotelike/utilities/globals.dart';
import 'package:quotelike/utilities/quote_querier.dart';
import 'package:quotelike/widgets/dropdown.dart';
import 'package:quotelike/widgets/quote_card.dart';

class ExplorePage extends StatefulWidget {
  final GlobalKey<ExplorePageState> explorePageKey;
  const ExplorePage(this.explorePageKey, {super.key});

  @override
  State<ExplorePage> createState() => ExplorePageState();
}

class ExplorePageState extends State<ExplorePage> {
  final sortKey = GlobalKey<FormFieldState>(); // passed into the sort dropdown()
  final filterKey = GlobalKey<FormFieldState>();
  Filter getFilter() => filterKey.currentState?.value ?? Filter.NONE;
  Sort getSort() => sortKey.currentState?.value ?? Sort.NONE;

  final quoteQuerier = QuoteQuerier(); // handles querying for quotes to scroll
  late Future<ErrorCode?> setLikedQuotesFuture; // used to prevent explore page refreshing after going back from settings
  late final PagingController<int, QuoteCard> pagingController;  

  bool buildError = false;

  @override
  void initState() {
    super.initState();

    setLikedQuotesFuture = db_functions.setLikedQuotes(); // this avoids rebuilding the page when swapping back from settings

    pagingController = PagingController<int, QuoteCard>(
      getNextPageKey: (state) => state.lastPageIsEmpty ? null : 0,
      fetchPage: makeQuery
    );
  }

  @override
  void dispose() {
    pagingController.dispose();
    super.dispose();
  }

  void refresh() {
    if (buildError) {
      // if there was an error with future builder, rebuild it
      setLikedQuotesFuture = db_functions.setLikedQuotes();
      setState(() {});   
    }
    else {
      // otherwise, perform a normal refresh
      quoteQuerier.refresh(getFilter(), getSort());
      pagingController.refresh();
    }
  }

  /// This is used instead of quote_querier.makeQuery()
  Future<List<QuoteCard>> makeQuery(int pageKey) async {
    ErrorCode? error;
    List<DocumentSnapshot> newQuotes;
    (error, newQuotes) = await quoteQuerier.makeQuery(getFilter(), getSort());

    List<QuoteCard> quoteCards = newQuotes.map((docSnapshot) => QuoteCard(
      docSnapshot.id, 
      docSnapshot["content"], 
      docSnapshot["author"], 
      docSnapshot["creation"], 
      docSnapshot["likes"] - (likedQuotes.contains(docSnapshot.id) ? 1 : 0)
    )).toList();

    if (error != null) {
      showToast(context, error.errorText, Duration(seconds: 3));
    }
    
    return quoteCards;
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
          buildError = true;
          ErrorCode error = asyncSnapshot.data ?? ErrorCode.UNKNOWN_ERROR;
          return Padding(
            padding: const EdgeInsets.only(left: 15, right: 15), // for some reason, i have to re-add the padding here
            child: Center(child: Text("${error.errorText} Try reloading (bottom right button).")),
          );
        }
        else {
          final scrollController = ScrollController();
          buildError = false;
          return PagingListener(
            controller: pagingController,
            builder: (context, state, fetchNextPage) => Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              thickness: 10,
              interactive: true,
              child: PagedListView(
                scrollController: scrollController,
                state: state,
                fetchNextPage: fetchNextPage,
                builderDelegate: PagedChildBuilderDelegate<QuoteCard>(
                  itemBuilder: (context, item, index) => item
                )
              ),
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
            Dropdown(context, filterKey, filterOptions, "Filter", 171, Icon(Icons.filter_list), widget.explorePageKey),
            Dropdown(context, sortKey, sortOptions, "Sort", 171, Icon(Icons.sort), widget.explorePageKey),
          ]
        ),
        SizedBox(height: 10),
        Expanded(child: quoteList),
      ]
    );
  }
}
