import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a media file (image/video) and return its download URL
  Future<String?> uploadMedia(File file, String path) async {
    try {
      // Create a reference with a unique file name
      Reference ref = _storage
          .ref()
          .child('$path/${DateTime.now().millisecondsSinceEpoch}');

      // Upload file
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading media: $e');
      return null;
    }
  }

  /// Delete a media file from Firebase Storage
  Future<void> deleteMedia(String url) async {
    try {
      // Convert URL to storage reference
      Reference ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Error deleting media: $e');
    }
  }
}
