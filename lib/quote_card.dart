
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quotebook/constants.dart';
import 'package:quotebook/globals.dart';

class QuoteCard extends StatefulWidget {
  final String id;
  final String quote;
  final String author;
  final Timestamp creation;
  final int likes;
  final bool isLiked;
  const QuoteCard(this.id, this.quote, this.author, this.creation, this.likes, this.isLiked, {super.key});

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> with TickerProviderStateMixin {
  late bool userLikedQuote;

  @override
  void initState() {
    userLikedQuote = widget.isLiked;
    super.initState();
  }

  /// Likes the quote if already liked, or removes the like if not
  Future<ErrorCode?> likeQuote() async {
    final log = Logger("likeQuote() in quote_card.dart");

    DocumentReference quoteDocRef = FirebaseFirestore.instance.collection("quotes").doc(widget.id);
    DocumentReference likeDocRef = FirebaseFirestore.instance // this doc exists if the user liked this quote
      .collection("users")
      .doc(FirebaseAuth.instance.currentUser!.email)
      .collection("liked_quotes")
    .doc(widget.id);

    ErrorCode? error = await firebaseErrorHandler(log, () async {
      await FirebaseFirestore.instance.runTransaction(timeout: Duration(seconds: 5), (transaction) async {
        final likeDocSnapshot = await transaction.get(likeDocRef);
        transaction.update( // update the likes on the quote doc
          quoteDocRef, 
          {"likes": widget.likes + (userLikedQuote ? 1 : 0) - (widget.isLiked ? 1 : 0)}
        );
        if (likeDocSnapshot.exists) { // create/delete the liked quote doc
          transaction.delete(likeDocRef);
        }
        else {
          Map<String, dynamic> newData = {}; // needed to prevent a dumb firestore error
          transaction.set(likeDocRef, newData);
        }
      }).timeout(Duration(seconds: 5));
    });

    return error;
  }

  String formatLikes() {
    int effectiveLikes = widget.likes + (userLikedQuote ? 1 : 0) - (widget.isLiked ? 1 : 0);
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

    InkWell likeButton = InkWell(
      onTap: () async => throttledFunc(1000, () async {
        showLoadingIcon();
        setState(() => userLikedQuote = !userLikedQuote);
        ErrorCode? error = await likeQuote();
        if (error != null && context.mounted) {
          showToast(
            context, 
            "${error.errorText} Your ${userLikedQuote ? "" : "dis"}like may not have registered.", 
            Duration(seconds: 5)
          );
        }
        hideLoadingIcon();
      }),
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
