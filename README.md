# QuoteLike

Lets you scroll quotes like a social media to build a collection of those you like.

## Using

Various things are .gitignored, so it is unlikely that this project will work if you just clone it and try to run it immediately. Instead, I would recommend creating your own flutter project, your own firebase project, and manually importing the files contained in lib. Remember that some things such as firebase app check, firebase auth, and firebase firestore need setup.
- Check the firebase console for instructions to enable app check. In the main() function in main.dart, remember to have androidProvider equal to AndroidProvider.debug if you want to launch the project in debug mode. When doing this, remember to input the debug token generated (this will show up in the debug console) into your appcheck debug keys in the firebase console.
- For firebase auth, make sure email/password login is allowed.
- For firestore, you must create 3 collections: one named "users", one named "quotes", and one named "suggestions". IMPORTANT: since a collection requires at least one document to be present when creating, make sure this document is called "placeholder". 
