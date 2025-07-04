import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUtil {
  static Future<String?> pickAndUploadProfileImage({
    required BuildContext context,
    required User user,
  }) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) return null;

      File originalFile = File(pickedFile.path);
      File? compressedFile = await compressImageToUnder100KB(originalFile);

      if (compressedFile == null) {
        throw 'Failed to compress image below 100 KB';
      }

      final storageRef = FirebaseStorage.instance.ref().child(
        'user_profiles/${user.uid}.jpg',
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Uploading image...")));

      await storageRef.putFile(compressedFile);

      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'profileImageUrl': downloadUrl},
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile picture updated!")));

      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to upload image: $e")));
      return null;
    }
  }

  /// Compresses given image to below 100 KB by reducing quality in steps.
  static Future<File?> compressImageToUnder100KB(File file) async {
    final tempDir = Directory.systemTemp;
    final targetPath =
        '${tempDir.path}/temp_profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

    int quality = 60;
    File? compressedFile;

    while (quality >= 20) {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (result == null) break;

      final sizeInKB = File(result.path).lengthSync() / 1024;
      if (sizeInKB <= 150) {
        compressedFile = File(result.path);
        break;
      }

      quality -= 10;
    }

    return compressedFile;
  }
}
