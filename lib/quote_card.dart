
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class QuoteCard extends StatefulWidget {
  final String quote;
  final String author;
  final Timestamp creation;
  final int likes;
  const QuoteCard(this.quote, this.author, this.creation, this.likes, {super.key});

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> with TickerProviderStateMixin {
  bool userLikedQuote = false;

  /// Returns whether the logged in user liked this quote or not.
  Future<bool> didUserLikeQuote(String quoteId) async {
    // TODO: make this work.
    return false;
  }

  /// Likes the quote if already liked, or removes the like if not
  Future<void> likeQuote() async {

    setState(() => userLikedQuote = !userLikedQuote);

    // TODO: Make this work
      // Update liked in the quote doc
      // Update liked quotes in the user doc
      // set state to update the card (make a separate stateful widget for the card)
  }

  @override
  Widget build(BuildContext context) {
    final animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    Widget likeIcon = !userLikedQuote ? Icon(Icons.favorite_border, color: ColorScheme.of(context).onSurface)
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

    InkWell likeButton = InkWell( // TODO: add hover color to both text and like button (maybe do it thru the inkwell)
      borderRadius: BorderRadius.circular(10),
      onTap: () async => await likeQuote(),
      child: Padding(
        padding: EdgeInsetsGeometry.all(5),
        child: Column(
          children: [
            likeIcon,
            Text( // TODO: add shortenings (e.g. k or million, max ?? digits)
              "${widget.likes}",
              style: TextStyle(color: ColorScheme.of(context).onSurface)
            ) 
          ],
        ),
      ),
    );

    SizedBox quoteBox = SizedBox(
      width: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft, 
            child: Text(
              '“${widget.quote}”', 
              textAlign: TextAlign.start,
              style: TextStyle(fontSize: 20), 
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            quoteBox,
            likeButton
          ],
        ),
      )
    );

    return Row(children: [Expanded(child: mainCard)]);
  }
}
