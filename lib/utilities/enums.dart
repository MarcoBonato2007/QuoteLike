
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
  RECENT_PASSWORD_RESET("You have already requested a password reset in the past hour."),
  RECENT_VERIFICATION_EMAIL("A verification email was already sent recently. Check your inbox and spam folder."),
  RECENT_EMAIL_CHANGE("An email change was already requested in the past day."),
  RECENT_SUGGESTION("You have already made a suggestion in the past hour."),
  REQUIRES_RECENT_LOGIN("This requires recent login. Please logout and login again.");
  
  final String errorText;
  const ErrorCode(this.errorText);
}

enum Event {
  LOGIN("Login"),
  APP_OPEN("App open"),
  SIGN_UP("Sign up"),
  ADD_SUGGESTION("Added suggestion"),
  SEND_EMAIL_VERIFICATION("Send email verification"),
  SEND_PASSWORD_RESET("Send password reset email"),
  LOGOUT("Log out"),
  DELETE_LIKED_QUOTES("Delete all liked quotes"),
  DELETE_USER("Delete user from firebase auth"),
  CHANGE_EMAIL("Send a change email request email");

  final String eventName;
  const Event(this.eventName);
}

enum Filter {
  NONE("None", "None"),
  LIKED("Liked", "Liked by you"),
  NOT_LIKED("Not liked", "Not liked by you");

  final String name; // shown inside the dropdown field
  final String label; // shown in the dropdown selection menu
  const Filter(this.name, this.label);
}

enum Sort {
  RANDOM("Random", "Random"),
  RECENT("Recent", "Recently added"),
  MOST_LIKED("Most liked", "Most liked"),
  LEAST_LIKED("Least liked", "Least liked"); 

  final String name; // shown inside the dropdown field
  final String label; // shown in the dropdown selection menu
  const Sort(this.name, this.label);
}
