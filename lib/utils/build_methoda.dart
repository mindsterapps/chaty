import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

DateTime convertTimetampToDateTime(Timestamp? timestamp) {
  if (timestamp == null) return DateTime.now();
  return timestamp.toDate();
} 