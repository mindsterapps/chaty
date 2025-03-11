class User {
  final String userId;
  final String name;
  final String role; // "customer" or "nutritionist"
  final String? firebaseToken; // Firebase token for push notifications

  User({
    required this.userId,
    required this.name,
    required this.role,
    this.firebaseToken,
  });

  // Convert User to a Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'role': role,
      'firebaseToken': firebaseToken,
    };
  }

  // Convert Firestore document to User
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['userId'],
      name: map['name'],
      role: map['role'],
      firebaseToken: map['firebaseToken'],
    );
  }
}
