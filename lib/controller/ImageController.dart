import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../utils.dart'; // For file path

class ImageController extends GetxController {
  Rx<File?> selectedImage = Rx<File?>(null);
  Rx<File?> compressedImage = Rx<File?>(null);

  RxString imageSize = ''.obs;
  RxString compressedImageSize = ''.obs;
  RxInt compressionQuality = 80.obs; // Default quality is 40%
  RxBool isCompressing = false.obs; // Indicates if compression is in progress
  RxBool isImageLoading = false.obs; // Indicates if image is being picked

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource gallery) async {
    isImageLoading.value = true;
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      selectedImage.value = File(pickedFile.path); // Convert XFile to File
      //  imageSize.value = '${selectedImage.value!.lengthSync()} bytes';
      await compressImage(
          quality: 80); // Automatically compress the image after selection
    }

    isImageLoading.value = false;
  }

  void updateCompressionQuality(int quality) {
    compressionQuality.value = quality;
    // Trigger compression whenever quality changes
  }

  Future<void> compressImage({required int quality}) async {
    try {
      if (selectedImage.value == null) {
        Get.snackbar('Error', 'No image selected');
        return;
      } else {
        isCompressing.value = true;

        final file = selectedImage.value!;

        final result = await FlutterImageCompress.compressWithFile(file.path,
            minWidth: 800,
            minHeight: 800,
            quality: quality,
            rotate: 0,
            format: CompressFormat.jpeg);

        if (result == null) {
          Get.snackbar('Error', 'Failed to compress image');
          return;
        }

        final compressedFile = File(file.path)..writeAsBytesSync(result);
        selectedImage.value = compressedFile;

        imageSize.value = getFileSize(selectedImage.value!.lengthSync());
        Get.snackbar('Success', 'Image compressed successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    }

    try {
      // Load the image
      final bytes = selectedImage.value!.readAsBytesSync();
      final image = img.decodeImage(bytes);

      if (image != null) {
        // Compress and save to a temporary file
        final compressedBytes = img.encodeJpg(image, quality: quality);
        final tempDir = Directory.systemTemp;
        final compressedFile = File("${tempDir.path}/CompressedImages.jpg");
        print("compressedFile_compressImage:-$compressedFile");
        compressedFile.writeAsBytesSync(compressedBytes);

        // Update the compressed image and size
        compressedImage.value = compressedFile;
        compressedImageSize.value =
            "${(compressedBytes.length / 1024).toStringAsFixed(2)} KB";
      }
      isCompressing.value = false;
    } catch (e) {
      Get.snackbar("Error", "Failed to compress the image: $e");
    }
  }

  Future<XFile?> compressMethod(File imageFile, int quality) async {
    // Replace with actual compression logic (e.g., using `flutter_image_compress`)
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/compressed.jpg';

    return await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      targetPath,
      quality: quality,
    );
  }

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
}

/*Future<void> saveCompressedImage(File file) async {
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
        quality: quality,
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
      compressedImageSize.value =
      "${(compressedBytes.length / 1024).toStringAsFixed(2)} KB";
    }
  } catch (e) {
    Get.snackbar("Error", "Failed to compress the image: $e");
  }
}

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
}*/
