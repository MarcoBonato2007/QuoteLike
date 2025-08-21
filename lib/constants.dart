// ignore_for_file: constant_identifier_names

class ErrorCode {
  final String errorText;
  const ErrorCode(this.errorText);
}

class ErrorCodes {
  static const ErrorCode INVALID_EMAIL = ErrorCode("Invalid email format.");
  static const ErrorCode EMAIL_NOT_VERIFIED = ErrorCode("Email not verified.");
  static const ErrorCode NETWORK_ERROR = ErrorCode("Network error. Check your connection.");
  static const ErrorCode SERVERS_BUSY = ErrorCode("Servers busy, try again later.");
  static const ErrorCode UNKNOWN_ERROR = ErrorCode("An unknown error occurred.");
  static const ErrorCode INCORRECT_CREDENTIALS = ErrorCode("Incorrect email or password.");
  static const ErrorCode NO_VERIFICATION_EMAIL = ErrorCode("A new verification email could not be sent. ");
  static const ErrorCode EMAIL_ALREADY_IN_USE = ErrorCode("This email is already in use"); // never actually shown to the user
  static const ErrorCode HIGHLIGHT_RED = ErrorCode(""); // blank error text highlights a text field red
  static const ErrorCode VERIFICATION_EMAIL_SENT_RECENTLY = ErrorCode("A verification email was already sent recently. Check your inbox.");
}
