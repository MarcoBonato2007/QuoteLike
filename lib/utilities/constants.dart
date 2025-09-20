// ignore_for_file: constant_identifier_names

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
