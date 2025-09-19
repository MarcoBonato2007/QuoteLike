// ignore_for_file: constant_identifier_names

const String PRIVACY_POLICY = """

What data is collected? (exhaustive)
  - Email addresses of signed up users
  - The date a user created their account
  - Whether a user has verified their email address
  - The quotes liked by a user
  - The suggestions made by a user
  - App crash reports. This contains information such as:
    - The operating system the crash took place on (e.g. Android 16)
    - The device the crash took place on
    - The time the crash occurred
  - Events. They contain the date, and a user's email and id (if one is logged in). An exhaustive list of events logged is:
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

Why is the data collected?
  - Email addresses must be collected to allow users to create accounts
  - Liked quotes must be collected to allow users to keep the same liked quotes across devices
  - Suggestions must be collected so they can be reviewed by an app administrator
  - App crash reports are collected to allow for bugs to be fixed
  - Events are collected to monitor the operation of the app, for reasons such as:
    - Analyzing how well the app is doing
    - Analyzing how many users keep using the app
    - etc.

How is the data used and shared?
  The current administrators are (exhaustive):
    - marcobonato2007@gmail.com

  Through the app "console", an administrator may view:
    - The email addresses, account creation times and verification status of all users
    - Events and crash logs (explained in the above 2 sections)
    - A list of all the quote suggestions made by users. As a reminder, these also contain the id of the users making the suggestions.
    - A list of all the liked quotes for each user.

  The app administrator has the ability to perform the following actions:
    - Reset a user's password
    - Disable a user's account
    - Delete a user's account
    - Delete a user's liked quotes
    - Add to a user's liked quotes
    - Approve or deny or modify a suggestion for a quote

  When will actions be taken?
    - Deleting or adding to a user's liked quotes, apart from those of the administrator or test accounts, will NEVER be done.
    - A user's account will only be disabled or deleted or have their password reset if:
      - The user has requested for this
      - Or the administrator believes the account to be toxic or compromised. For example:
        - The user has sent an email to an administrator saying that their account has been hacked
        - The user is attempting to spam something (e.g. a password reset email, a verification email, etc.)
        - Etc: This is up to the administrator's discretion.

  Passwords are not visible to administrators.

User rights
  Users have all rights to their account. They may request:
    - Account deletion (note this is already possible in the app)
    - Account disabilitation (not possible in the app)
    - A password reset (possible max once per hour in the app)
    - Removal of liked quotes (possible through account deletion in the app)
    - Removal of their suggestions (not possible through the app)
    - Etc. In general, any piece of data held about the user may be requested to be removed.

  Do to this, they may contact any administrator.
    - Please contact administrators through email only (see below for a list of administrators)
    - Administrators will attempt to check their email addresses once per day.
    - A confirmation email will be sent back once the operation has been completed.

  The current administrators are (exhaustive):
    - marcobonato2007@gmail.com
""";

class ErrorCode {
  final String errorText;
  const ErrorCode(this.errorText);
}
class ErrorCodes {
  // Error codes with a trailing colon are pre-pended to other codes.
  static const ErrorCode NO_VERIFICATION_EMAIL = ErrorCode("Error sending verification email: ");
  static const ErrorCode FAILED_ACCOUNT_DELETION = ErrorCode("Your account could not be deleted: ");

  static const ErrorCode HIGHLIGHT_RED = ErrorCode(""); // blank error text highlights a text field red

  static const ErrorCode EMAIL_ALREADY_IN_USE = ErrorCode("This email is already in use. Please log in."); // for sign up
  static const ErrorCode INVALID_EMAIL = ErrorCode("Invalid email format.");
  static const ErrorCode EMAIL_NOT_VERIFIED = ErrorCode("Email not verified.");
  static const ErrorCode NETWORK_ERROR = ErrorCode("Network error. Check your connection.");
  static const ErrorCode SERVERS_BUSY = ErrorCode("Servers busy, try again later.");
  static const ErrorCode UNKNOWN_ERROR = ErrorCode("An unknown error occurred.");
  static const ErrorCode INCORRECT_CREDENTIALS = ErrorCode("Incorrect email or password.");
  static const ErrorCode TIMEOUT = ErrorCode("Request timed out. Check your connnection or try again later.");
  static const ErrorCode REQUIRES_RECENT_LOGIN = ErrorCode("This requires recent login. Please logout and login again.");
}
