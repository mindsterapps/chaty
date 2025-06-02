import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

/// Converts a Firestore [Timestamp] to a [DateTime] object.
///
/// If [timestamp] is null, returns the current [DateTime].
DateTime convertTimetampToDateTime(Timestamp? timestamp) {
  if (timestamp == null) return DateTime.now();
  return timestamp.toDate();
}
