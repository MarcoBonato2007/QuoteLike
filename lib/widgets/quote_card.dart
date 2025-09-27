import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:readmore/readmore.dart';

import 'package:quotelike/utilities/db_functions.dart' as db_functions;
import 'package:quotelike/utilities/enums.dart';
import 'package:quotelike/utilities/globals.dart';
import 'package:quotelike/utilities/rate_limiting.dart';
import 'package:quotelike/utilities/theme_settings.dart';

/// A quote card is the widgets that the user scrolls in explore_page.dart
class QuoteCard extends StatefulWidget {
  final String id;
  final String quote;
  final String author;
  final Timestamp creation;
  final int likes; // this is the amount of likes excluding any user likes
  const QuoteCard(this.id, this.quote, this.author, this.creation, this.likes, {super.key});

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> with TickerProviderStateMixin {
  late final AnimationController animationController;

  @override
  void initState() {
    animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    )..forward();

    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  /// This is used instead of db_functions.likeQuote()
  Future<void> likeQuote() async {
    showLoadingIcon();
    ErrorCode? error = await db_functions.likeQuote(widget.id, isDislike: likedQuotes.contains(widget.id));

    if (error == null) {
      setState(() {});
    }
    else if (mounted) {
      showToast(
        context, 
        "${error.errorText} Your ${likedQuotes.contains(widget.id) ? "dis" : ""}like may not have registered.", 
        Duration(seconds: 5)
      );
    }

    hideLoadingIcon();
  }

  /// Formats likes into a string (e.g. 500 -> "500", 1200 -> "1.2k", 2300000 -> "2.3m")
  String formatLikes() {
    int effectiveLikes = widget.likes + (likedQuotes.contains(widget.id) ? 1 : 0);
    if (effectiveLikes >= 1000000) {
      return "${(effectiveLikes/1000000).toStringAsFixed(1)}m";
    }
    else if (effectiveLikes >= 1000) {
      return "${(effectiveLikes/1000).toStringAsFixed(1)}k";
    }
    else {
      return "$effectiveLikes";
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget likeIcon = !likedQuotes.contains(widget.id) ? Icon(Icons.favorite_border, color: ColorScheme.of(context).onSurface)
    : ScaleTransition(
      alignment: Alignment.bottomCenter,
      scale: TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.25), // Make icon bigger
          weight: 0.5,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.25, end: 1.0), // Make icon smaller
          weight: 0.5,
        ),
      ]).animate(animationController),
      child: Icon(
        Icons.favorite, 
        color: Colors.red
      ),
    );

    InkWell likeButton = InkWell(
      onTap: () async => throttledFunc(1000, () async => await likeQuote()),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsetsGeometry.all(5),
        child: Column(
          children: [
            likeIcon,
            Text(
              formatLikes(),
              style: TextStyle(color: ColorScheme.of(context).onSurface)
            ) 
          ],
        ),
      ),
    );

    SizedBox quoteBox = SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft, 
            child: ReadMoreText(
              '“${widget.quote}”', 
              trimLength: 100,
              textAlign: TextAlign.start,
              style: TextStyle(fontSize: 20), 
              moreStyle: TextStyle(color: ColorScheme.of(context).primary)
            )
          ),
          Align(
            alignment: Alignment.centerLeft, 
            child: Text(
              '- ${widget.author}', 
              textAlign: TextAlign.start,
              style: TextStyle(fontSize: 15), 
            )
          ),
        ]
      ),
    );

    Card mainCard = Card(
      elevation: Provider.of<ThemeSettings>(context, listen: false).elevation,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: quoteBox),
            SizedBox(width: 10),
            likeButton
          ],
        ),
      )
    );

    return Row(children: [Expanded(child: mainCard)]);
  }
}
