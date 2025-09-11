# QuoteLike

Lets you scroll quotes like a social media to build a collection of those you like.

## Using

I would recommend creating your own flutter project, your own firebase project, and manually importing the files contained in lib. Note that some things such as firebase app check, firebase auth, and firebase firestore need setup.
- Check the firebase console in order to enable app check. Remember to input the debug key into the console when the app launches.
- For firebase auth, make sure email/password login is allowed.
- For firestore, you must create 3 collections: one named "users", one named "quotes", and one named "suggestions". IMPORTANT: since a collection requires at least one document to be present when creating, make sure this document is called "placeholder". 
