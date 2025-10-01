# QuoteLike

Lets you scroll quotes like a social media to build a collection of those you like.

## Copying the project for yourself
Various important things are .gitignored, so the project will NOT work for you out of the box. To copy this project, create your own flutter project, your own firebase project (set it up in flutter using flutterfire), and manually import the files contained in lib. Then, follow the instructions below.

### Auth setup
Email/password login must be enabled in Firebase auth. Please ensure that email enumeration protection is enabled, and check your password policy (ours below).

<img width="329" height="288" alt="image" src="https://github.com/user-attachments/assets/af193e66-604a-40a8-9d63-097cb0f5995f" />
  
### App check setup
If you don't want to use app check, remove the package and remove the line ```
await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity
);``` from main.dart.

Otherwise, please set up app check in the Firebase console. Remember: if you want to launch the project, input your debug token (this will show up in the debug console) into your appcheck debug tokens in the firebase console.

### Firestore setup
There are only 3 collections: quotes, suggestions and users. 

**Important**: some of the database structure is enforced by the firestore security rules. Please modify these before creating new collections, using fields with different names, etc.

#### Quotes
Shown below is example structure for a quote document.

<img width="2715" height="655" alt="image" src="https://github.com/user-attachments/assets/1a959293-557d-4c4f-bec7-11f4afaddca8" />

#### Suggestions
Shown below is an example suggestion document. The user field should match the uid of a user in firebase auth (e.g. "PyglU5gUl3ONAEs8HqFEzmVmGr52").

<img width="2712" height="625" alt="image" src="https://github.com/user-attachments/assets/a4004f1d-ddb4-4d29-a9ba-fbdb17d0cca8" />

#### Users
All document id's are equal to a user uid in firebase auth (e.g. "PyglU5gUl3ONAEs8HqFEzmVmGr52"). User documents don't actually exist (i.e. have no fields), they only contain a "liked_quotes" subcollection. Shown below is an example.

<img width="2732" height="588" alt="image" src="https://github.com/user-attachments/assets/c51dc3a3-d6ba-44e6-a458-41db8f6d6ea7" />

The liked quotes subcollection contains documents whose id's are equal to the id of a document in the quotes collection (e.g. "YIG7VJNtj7iLT6fJBxjw"). Shown below is an example.

<img width="2743" height="544" alt="image" src="https://github.com/user-attachments/assets/d102af5e-ee66-47e9-ba16-ee1bd21d981d" />

Note how documents inside the subcollection have no fields.

<img width="2725" height="589" alt="image" src="https://github.com/user-attachments/assets/151b9ef4-72d7-41f9-8927-02921b434142" />

#### Firestore rules
There are important since they directly tie in to the database structure.

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
  
  	match /quotes/{quoteDoc} {
    	// allow any logged in and verified user to get a quote
    	allow get: if 
      		request.auth != null 
      		&& request.auth.token.email_verified;
        
      	// allow any logged in, verified user to list max 20 quotes
    	allow list: if 
      		request.auth != null 
      		&& request.auth.token.email_verified
        	&& request.query.limit <= 20;
        
      	// Allow updates only if:
      		// The user is logged in and verified
        	// They are updating the likes of a quote only
        	// The likes are changing by 1 or -1 and the user hasn't or has liked the quote already
		allow update: if
		request.auth != null
		&& request.auth.token.email_verified
		&& request.resource.data.diff(resource.data).affectedKeys().hasOnly(["likes"])
		&& request.resource.data.likes is int
		&& (
			(
			request.resource.data.likes-resource.data.likes == 1
			&& !exists(/databases/$(database)/documents/users/$(request.auth.uid)/liked_quotes/$(resource.id))
			)
		|| 
			(
			request.resource.data.likes-resource.data.likes == -1
			&& exists(/databases/$(database)/documents/users/$(request.auth.uid)/liked_quotes/$(resource.id))
			)
		);
    }
    
    // for suggestions, allow creation only if:
    	// Request is made from a logged in and verified user 
    	// The format is correct (only contains the author, content and user fields)
      	// The author or content fields aren't excessively large
  	match /suggestions/{suggestionDoc} {
    	allow create: if 
      	request.auth != null 
        && request.auth.token.email_verified
        && request.resource.data.keys().hasOnly(["author", "content", "user"])
        && request.resource.data.keys().hasAll(["author", "content", "user"])
        && request.resource.data.author is string
        && request.resource.data.content is string
        && request.resource.data.user is string
        && request.resource.data.author.size() <= 100
        && request.resource.data.content.size() <= 250
        && request.resource.data.user.size() <= 128;
    }
    
  	match /users/{userDoc} {   
    	// Allow creating a user document only if:
    		// The current user is logged in and verified
      		// The document is being created for the currently logged in user
      		// There are no fields being added
    	allow create: if
      		request.auth != null
        	&& request.auth.token.email_verified
        	&& userDoc == request.auth.uid
        	&& request.resource.data.keys().size() == 0;
			
    	match /liked_quotes/{likedQuoteDoc} {        
	        // Allow listing liked quotes only if:
	        	// The current user is logged in and verified
	          	// The current user is reading their own liked quotes
	      	allow read: if 
	        	request.auth != null
	          	&& request.auth.token.email_verified
	          	&& userDoc == request.auth.uid;
	        
	      	// Allow create only if:
	        	// The current user is logged in and verified
	          	// The current user is updating their own liked quotes
	          	// The liked quote doc is the correct format (empty, no fields)
	          	// The id of the document represents an existing quote
	      	allow create: if 
	        	request.auth != null
	          	&& request.auth.token.email_verified
	          	&& userDoc == request.auth.uid
	          	&& request.resource.data.keys().size() == 0
	          	&& exists(/databases/$(database)/documents/quotes/$(request.resource.id));
	          
	        // Allow delete only if:
	        	// The current user is logged in and verified
	          	// The current user is updating their own liked quotes
	      	allow delete: if 
				request.auth != null
	          	&& request.auth.token.email_verified
	          	&& userDoc == request.auth.uid;
      }
    }
  }
}
```
