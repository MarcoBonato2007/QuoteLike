# Introduction
QuoteLike is an app where users can view and "like" a list of quotes. This list of quotes is curated by the administrators of the app.
Users can also make suggestions for new quotes to be added. The app is completely free, with no future plans to add monetization.

# Useful Information
## Open-source
All app details can be found on https://github.com/MarcoBonato2007/QuoteLike.
This explains the structure of the app and how to replicate it.
## Third party services
The app utilizes third-party services that have their own terms and conditions. 
Below are the links to the terms and conditions for these services.
- https://www.google.com/analytics/terms/
- https://firebase.google.com/terms/crashlytics
- https://cloud.google.com/terms/
  
## Contact
Current administrators & email addresses:
- Marco Bonato (Owner & Developer): marcobonato2007@gmail.com

# What data is collected?
## Data stored in a database
This data is collected using a third party service: https://firebase.google.com/docs/firestore.

This data contains:
- The quotes liked by a user, consisting of a list of id's of liked quotes.
- The suggestions made by a user, containing:
  - The suggested quote content
  - The suggested quote author
  - Their user id

## Authentication
### Login & signup
This data is collected using a third party service: https://firebase.google.com/docs/auth.

Data collected consists of:
- Email address of a signed up user
- The date a user created their account
- The id of users (this can be used to identify their email address)
- The last date a user signed in
- Whether a user has verified their account

### App check
This data is used to check whether a user is using a legitimate version of the application. This is called an "integrity check".

This is done (and data is collected using) a third party service: https://firebase.google.com/docs/app-check.

Data collected consists of:
- The date the integrity check occurred
- Whether the integrity check was successful or not

## Events
This data is collected using a third party service: https://firebase.google.com/docs/analytics.

All events contain:
- The date the event occurred
- The email of the currently logged in user (if any)
- The country the event occurred in
- The type of event

Types of events
- An email verification email being sent
- A password reset email being sent
- A user logging in
- A user signing up
- A user signing out
- A user's liked quotes being deleted from the database
- A user's account being deleted
- A user's email being changed
- The app being opened
- A user creating a suggestion

## Crash reports
This data is collected using a third party service: https://firebase.google.com/docs/crashlytics.

Each crash report contains information on the device the crash took place on, containing:
- The operating system the crash took place on (e.g. Android 16)
- Whether the device is "rooted"
- The name of the device the crash took place on
- The current orientation of the device
- The amount of free RAM on the device
- The amount of free disk space on the device
  
Crash reports also contain:
- The user id of the currently logged in user (if any).
- The date and time the crash occurred
- The country the crash occurred in
- The version of the app the crash occurred in (e.g. 1.4.2)

# Why is the data collected?
- Email addresses must be collected to allow users to create accounts
- App crash reports are collected to allow for bugs to be fixed
- Events are collected to monitor the operation of the app
- Liked quotes must be collected to allow users to keep the same liked quotes across devices
- Suggestions must be collected so they can be reviewed by an app administrator and possibly added to the list of quotes
- Any other data mentioned previously is collected automatically as part of the third party service being used.

# How is the data viewed, controlled and shared by administrators?
Please view a list of current administrators in the "Contact" section (towards the bottom).
## Data sharing
Data will only be shared, viewed, or otherwise managed by:
- The group of administrators
- Possibly by third party services used to implement the application. These are:
  - https://firebase.google.com/
  - https://firebase.google.com/docs/firestore
  - https://firebase.google.com/docs/auth
  - https://firebase.google.com/docs/analytics
  - https://firebase.google.com/docs/crashlytics
  - https://firebase.google.com/docs/app-check
    
Overall, third-parties not used to implement the application will never be given any data.
## Administrator rights
Through the app "console", an administrator may view only the data specified in the "What data is collected?" section.

Passwords are not visible to administrators.

The app administrator has the ability to perform the following actions on user data:
- Reset a user's password (usually done by the user independently)
- Disable a user's account (CANNOT be done by the user independently)
- Delete a user's account (usually done by the user independently)
- Delete from a user's liked quotes (usually done by the user independently)
- Add to a user's liked quotes (usually done by the user independently)
- Add, remove or modify a quote suggestion made by a user (CANNOT be done by the user independently)
  
## Administrator actions
Deleting or adding to a user's liked quotes, will only be done if:
- The user has requested for this by contacting an administrator via email

Approving, removing or modifying a quote suggestion made by a user, will be done only if:
- The user has requested for this by contacting an administrator via email
- An administrator wishes to do so. This is up to each administrator's discretion.
  
Resetting a user's password or disabling or deleting their account will be done only if:
- The user has requested for this by contacting an administrator via email
- Or the administrator believes the account to be toxic or compromised. For example:
  - The user has sent an email to an administrator saying that their account has been hacked
  - The user has "jailbroken" the app and is attempting to make malicious database requests
  - The user is attempting some kind of attack (e.g. DDOS)
  - Etc: This is up to the administrator's discretion.
  
# User rights
Through the app, users can:
- Create an account (via email & password)
- Sign in to an account
- Delete an account they are logged in to
- Reset the password for an account
- Change the email for an account
- Make a quote suggestion for an account
- Add or remove to their liked quotes for an account

But they CANNOT (through the app):
- Delete or modify quote suggestions they have submitted
- Disable their account

Users may delete ANY data held about them by contacting an administrator (see last section). For example:
- Liked quotes
- Suggestions made
- Accounts held

Users may additionally request the following (again by contacting an administrator (see last section)):
- A password reset email
- An email change email
- A verification email  
- Changes or additions to liked quotes or suggestions
Please note: these requests will usually be granted, but are up to the discretion of the administrators.

# Contact
Please contact an administrator via email.
  
Current administrators & email addresses:
- Marco Bonato (Owner & Developer): marcobonato2007@gmail.com
  
More administrators may be added in future at the owner's discretion.
