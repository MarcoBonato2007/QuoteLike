// ignore_for_file: constant_identifier_names

class ErrorCode {
  final String errorText;
  const ErrorCode(this.errorText);
}
class ErrorCodes {
  // Error codes with a trailing space are pre-pended to other codes.
  static const ErrorCode INVALID_EMAIL = ErrorCode("Invalid email format.");
  static const ErrorCode EMAIL_NOT_VERIFIED = ErrorCode("Email not verified.");
  static const ErrorCode NETWORK_ERROR = ErrorCode("Network error. Check your connection.");
  static const ErrorCode SERVERS_BUSY = ErrorCode("Servers busy, try again later.");
  static const ErrorCode UNKNOWN_ERROR = ErrorCode("An unknown error occurred.");
  static const ErrorCode INCORRECT_CREDENTIALS = ErrorCode("Incorrect email or password.");
  static const ErrorCode NO_VERIFICATION_EMAIL = ErrorCode("Error sending verification email: "); // this is chained together with other error texts
  static const ErrorCode FAILED_ACCOUNT_DELETION = ErrorCode("Your account could not be deleted: "); // this is chained together with other error texts
  static const ErrorCode EMAIL_ALREADY_IN_USE = ErrorCode("This email is already in use"); // never actually shown to the user
  static const ErrorCode HIGHLIGHT_RED = ErrorCode(""); // blank error text highlights a text field red
  static const ErrorCode VERIFICATION_EMAIL_SENT_RECENTLY = ErrorCode("A verification email was already sent recently. Check your inbox.");
  static const ErrorCode TIMEOUT = ErrorCode("Request timed out. Check your connnection or try again later.");
  static const ErrorCode REQUIRES_RECENT_LOGIN = ErrorCode("This requires recent login. Please logout and login again.");
  static const ErrorCode RECENT_SUGGESTION = ErrorCode("You have already made a suggestion in the past hour.");
}

const String PRIVACY_POLICY = """Hello
  This is an example privacy policy  
  There is nothing here yet""";
