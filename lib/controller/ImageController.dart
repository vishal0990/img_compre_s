import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // For file path

class ImageController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  Rx<File?> selectedImage = Rx<File?>(null); // Store selected image as File
  RxString imageSize = ''.obs;
  RxBool isImageLoading = false.obs; // Loading state for image processing
  var compressedImageSize = 0.obs;
  var compressedImage = Rx<File?>(null);

  Rx<File?> previewImage = Rx<File?>(null);
  RxInt quality = RxInt(80); // Initial quality set to 80

  // Function to pick an image from gallery or camera
  Future<void> pickImage(ImageSource source) async {
    try {
      isImageLoading.value = true; // Set loading to true

      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        // Convert XFile to File
        final file = File(pickedFile.path);
        selectedImage.value = file;

        // Get image file size and update UI
        final fileSize = await file.length();
        imageSize.value =
            "${(fileSize / 1024).toStringAsFixed(2)} KB"; // Size in KB
      } else {
        Get.snackbar('No Image', 'No image selected');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
    } finally {
      isImageLoading.value = false; // Stop loading state
    }
  }

  Future<void> compressImageRealTime({required int quality}) async {
    if (selectedImage.value != null) {
      try {
        // Load the image
        final bytes = selectedImage.value!.readAsBytesSync();
        final image = img.decodeImage(bytes);

        if (image != null) {
          // Compress and save to a temporary file
          final compressedBytes = img.encodeJpg(image, quality: quality);
          final tempDir = Directory.systemTemp;
          final compressedFile = File("${tempDir.path}/compressed_image.jpg");
          compressedFile.writeAsBytesSync(compressedBytes);

          // Update the compressed image and size
          compressedImage.value = compressedFile;
          compressedImageSize.value = compressedFile.lengthSync();
        }
      } catch (e) {
        Get.snackbar("Error", "Failed to compress the image: $e");
      }
    }
  }

  // Function to compress the image
  Future<void> compressImage({required int quality}) async {
    try {
      if (selectedImage.value == null) {
        Get.snackbar('Error', 'No image selected');
        return;
      }

      final file = selectedImage.value!;

      final result = await FlutterImageCompress.compressWithFile(file.path,
          minWidth: 800,
          minHeight: 800,
          quality: 80,
          rotate: 0,
          format: CompressFormat.jpeg);

      if (result == null) {
        Get.snackbar('Error', 'Failed to compress image');
        return;
      }

      final compressedFile = File(file.path)..writeAsBytesSync(result);
      selectedImage.value = compressedFile;

      final compressedSize = result.length;
      imageSize.value =
          "Compressed Size: ${(compressedSize / 1024).toStringAsFixed(2)} KB";

      Get.snackbar('Success', 'Image compressed successfully',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    }
  }

/*
  // Function to save the compressed image
  Future<void> saveCompressedImage(File file) async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final savePath =
          '${directory.path}/compressed_image_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Save the compressed file
      await file.copy(savePath);
      Get.snackbar('Success', 'Image saved at $savePath');
    } catch (e) {
      Get.snackbar('Error', 'Failed to save image: $e');
    }
  }
*/

  Future<void> saveCompressedImage(File file) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      String savePath;

      if (Platform.isAndroid) {
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          throw Exception('External storage directory not available.');
        }

        // For Android 10+ or below, use proper folder creation
        final folderPath = '${directory.path}/CompressedImages';
        final folder = Directory(folderPath);
        if (!await folder.exists()) {
          await folder.create(recursive: true);
        }

        savePath =
            '$folderPath/compressed_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        savePath =
            '${directory.path}/compressed_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      if (!file.existsSync()) {
        throw Exception('Source file does not exist.');
      }

      final savedFile = await file.copy(savePath);

      Get.snackbar(
        'Success',
        'Image saved successfully!',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      print('Image saved at: ${savedFile.path}');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save image: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print('Failed to save image: $e');
    }
  }

  // Helper function to check if the Android version is 10 or above
  Future<bool> isAndroid10OrAbove() async {
    if (Platform.isAndroid) {
      final version = int.parse(Platform.operatingSystemVersion.split(' ')[1]);
      return version >= 29; // Android 10 corresponds to API level 29
    }
    return false;
  }

  // Load and process the selected image

  // Update the preview image based on quality
  Future<void> updatePreview() async {
    if (selectedImage.value != null) {
      final originalImage =
          img.decodeImage(selectedImage.value!.readAsBytesSync());
      if (originalImage != null) {
        final compressedImage =
            img.encodeJpg(originalImage, quality: quality.value);
        final previewFile = File("${selectedImage.value!.path}_preview.jpg")
          ..writeAsBytesSync(compressedImage);
        previewImage.value = previewFile;
      }
    }
  }

  // Update quality and refresh preview
  void setQuality(int newQuality) {
    quality.value = newQuality;
    updatePreview();
  }
}
