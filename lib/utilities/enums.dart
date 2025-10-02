// ignore_for_file: constant_identifier_names

enum ErrorCode {
  NO_VERIFICATION_EMAIL("Error sending verification email: "),
  FAILED_ACCOUNT_DELETION("Your account could not be deleted: "),
  HIGHLIGHT_RED(""),
  EMAIL_ALREADY_IN_USE("This email is already in use. Please log in."),
  INVALID_EMAIL("Invalid email format."),
  EMAIL_NOT_VERIFIED("Email not verified."),
  NETWORK_ERROR("Network error. Check your connection."),
  SERVERS_BUSY("Servers busy, try again later."),
  UNKNOWN_ERROR("An unknown error occurred."),
  INCORRECT_CREDENTIALS("Incorrect email or password."),
  TIMEOUT("Request timed out. Check your connnection or try again later."),
  RECENT_PASSWORD_RESET("You have already requested a password reset for this email in the past hour."),
  RECENT_VERIFICATION_EMAIL("A verification email was already sent recently. Check your inbox and spam folder."),
  RECENT_EMAIL_CHANGE("An email change was already requested in the past day."),
  RECENT_SUGGESTION("You have already made a suggestion in the past hour."),
  REQUIRES_RECENT_LOGIN("This requires recent login. Please logout and login again.");
  
  final String errorText;
  const ErrorCode(this.errorText);
}

enum Event {
  LOGIN("login"),
  APP_OPEN("app_open"),
  SIGN_UP("sign_up"),
  ADD_SUGGESTION("add_suggestion"),
  SEND_EMAIL_VERIFICATION("send_email_verification"),
  SEND_PASSWORD_RESET("send_password_reset_email"),
  LOGOUT("log_out"),
  DELETE_LIKED_QUOTES("delete_liked_quotes"),
  DELETE_USER("delete_user"),
  CHANGE_EMAIL("send_email_change_email");

  final String eventName;
  const Event(this.eventName);
}

// Filter and Sort enums are used for the dropdown menus in explore_page.dart

sealed class DropdownOption {
  /// The text shown inside the dropdown field
  final String labelInField;
  /// The text shown in the dropdown selection menu
  final String labelInDropdown;

  const DropdownOption(this.labelInField, this.labelInDropdown);
}

enum Filter implements DropdownOption {
  NONE("None", "None"),
  // NOT_LIKED("Not liked", "Not liked by you"), // this may be implemented in future
  LIKED("Liked", "Liked by you");

  @override
  final String labelInField;
  @override
  final String labelInDropdown;
  
  const Filter(this.labelInField, this.labelInDropdown);
}

enum Sort implements DropdownOption {
  NONE("None", "None"),
  RANDOM("Random", "Random"),
  RECENT("Recent", "Recently added"),
  MOST_LIKED("Most liked", "Most liked"),
  LEAST_LIKED("Least liked", "Least liked"); 

  @override
  final String labelInField;
  @override
  final String labelInDropdown;

  const Sort(this.labelInField, this.labelInDropdown);
}
