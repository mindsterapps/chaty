/// User model representing a user in the chat system.
class User {
  /// Unique user identifier.
  final String userId;

  /// Name of the user.
  final String name;

  /// Role of the user (e.g., "customer" or "nutritionist").
  final String role; // "customer" or "nutritionist"

  /// Firebase token for push notifications.
  final String? firebaseToken; // Firebase token for push notifications

  /// Creates a new [User] instance.
  User({
    required this.userId,
    required this.name,
    required this.role,
    this.firebaseToken,
  });

  /// Convert User to a Map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'role': role,
      'firebaseToken': firebaseToken,
    };
  }

  /// Convert Firestore document to User.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['userId'],
      name: map['name'],
      role: map['role'],
      firebaseToken: map['firebaseToken'],
    );
  }
}
