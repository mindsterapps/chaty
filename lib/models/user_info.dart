/// Represents the sender's information in a chat message.
class SenderInfo {
  /// The name of the sender.
  final String? name;

  /// The URL of the sender's image.
  final String? imageUrl;

  /// Creates a [SenderInfo] instance with optional name and image URL.
  SenderInfo({this.name, this.imageUrl});

  /// Converts this [SenderInfo] instance to a [Map] for Firestore storage.
  factory SenderInfo.fromMap(Map<String, dynamic> map) {
    return SenderInfo(
      name: map['name'] as String?,
      imageUrl: map['imageUrl'] as String?,
    );
  }
}
