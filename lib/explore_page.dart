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
  final _sortKey = GlobalKey<FormFieldState>();
  final _filterKey = GlobalKey<FormFieldState>();
  Filter getFilter() => _filterKey.currentState?.value ?? Filter.NONE;
  Sort getSort() => _sortKey.currentState?.value ?? Sort.NONE;

  final _quoteQuerier = QuoteQuerier(); // handles querying for quotes to scroll
  late Future<ErrorCode?> _setLikedQuotesFuture; // used to prevent explore page refreshing after going back from settings
  late final PagingController<int, QuoteCard> _pagingController; // initialized in initState()

  bool _buildError = false; // stores if there's an error in the future builder (see build() and refresh())

  @override
  void initState() {
    _setLikedQuotesFuture = db_functions.setLikedQuotes(); // this avoids rebuilding the page when swapping back from settings

    _pagingController = PagingController<int, QuoteCard>(
      getNextPageKey: (state) => state.lastPageIsEmpty ? null : 0,
      fetchPage: makeQuery
    );

    super.initState();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  void refresh() {
    if (_buildError) {
      // if there was an error with future builder, rebuild it
      _setLikedQuotesFuture = db_functions.setLikedQuotes();
      setState(() {});   
    }
    else {
      // otherwise, perform a normal refresh
      _quoteQuerier.refresh(getFilter(), getSort());
      _pagingController.refresh();
    }
  }

  /// Not all filters and sorts are compatible.
  /// This function resets either the filter or sort dropdown if an incompatibility is found.
  void checkFilterSortCompatibility(bool isNewSort) { // isNewSort is false if a filter is being set
    Filter filter = getFilter();
    Sort sort = getSort();

    // Filter.LIKED only supports RANDOM and NONE filters.
    if (filter == Filter.LIKED && sort != Sort.RANDOM && sort != Sort.NONE) {
      if (isNewSort) { // if the sort field has been set, reset the filter
        _filterKey.currentState!.reset();
      }
      else { // otherwise, the filter field has been set, so reset the sort
        _sortKey.currentState!.reset();
      }
    }
  }

  /// This is used instead of quote_querier.makeQuery()
  Future<List<QuoteCard>> makeQuery(int pageKey) async {
    ErrorCode? error;
    List<DocumentSnapshot> newQuotes;
    (error, newQuotes) = await _quoteQuerier.makeQuery(getFilter(), getSort());

    List<QuoteCard> quoteCards = newQuotes.map((docSnapshot) => QuoteCard(
      docSnapshot.id, 
      docSnapshot["content"], 
      docSnapshot["author"], 
      docSnapshot["creation"], 
      docSnapshot["likes"] - (likedQuotes.contains(docSnapshot.id) ? 1 : 0)
    )).toList();

    if (error != null) {
      showToast(context, "${error.errorText} Try reloading (bottom right button).", Duration(seconds: 3));
    }
    
    return quoteCards;
  }

  @override
  Widget build(BuildContext context) {    
    Widget quoteList = FutureBuilder( // we future build the quote list after we set the list of liked quotes
      future: _setLikedQuotesFuture,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        else if (asyncSnapshot.hasError || (asyncSnapshot.hasData && asyncSnapshot.data != null)) {
          _buildError = true;
          ErrorCode error = asyncSnapshot.data ?? ErrorCode.UNKNOWN_ERROR;
          return Padding(
            padding: const EdgeInsets.only(left: 15, right: 15), // for some reason, i have to re-add the padding here
            child: Center(child: Text("${error.errorText} Try reloading (bottom right button).")),
          );
        }
        else {
          final scrollController = ScrollController();
          _buildError = false;
          return PagingListener(
            controller: _pagingController,
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
            Dropdown(context, _filterKey, Filter.values, Filter.NONE, "Filter", 171, Icon(Icons.filter_list), widget.explorePageKey),
            Dropdown(context, _sortKey, Sort.values, Sort.NONE, "Sort", 171, Icon(Icons.sort), widget.explorePageKey),
          ]
        ),
        SizedBox(height: 10),
        Expanded(child: quoteList),
      ]
    );
  }
}
