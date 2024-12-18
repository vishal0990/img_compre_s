import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

import '../controller/ImageController.dart';

class ImagePickScreen extends StatefulWidget {
  @override
  _ImagePickScreenState createState() => _ImagePickScreenState();
}

class _ImagePickScreenState extends State<ImagePickScreen> {
  final ImageController controller = Get.put(ImageController());
  int _selectedIndex = 0;

  // Quality value for compression
  final RxDouble compressionQuality = 50.0.obs;

  // Function to handle Bottom Navigation selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (_selectedIndex == 0) {
      controller.pickImage(ImageSource.gallery); // Pick from gallery
    } else if (_selectedIndex == 1) {
      controller.pickImage(ImageSource.camera); // Capture with camera
    } else if (_selectedIndex == 2) {
      controller.compressImage(
          quality: compressionQuality.value.toInt()); // Compress image
    } else if (_selectedIndex == 3) {
      if (controller.selectedImage.value != null) {
        controller.saveCompressedImage(
            controller.selectedImage.value!); // Save compressed image
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title:   
            const Text("Compress Image", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSectionHeader("Selected Image"),
              const SizedBox(height: 10),
              Obx(() {
                return controller.isImageLoading.value
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
                    : controller.selectedImage.value != null
                        ? SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Display original and compressed images side by side
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Original Image
                                    Column(
                                      children: [
                                        const Text(
                                          "Original",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.file(
                                            controller.selectedImage.value!,
                                            width: 150,
                                            height: 150,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          "Size: ${controller.compressedImageSize.value}",
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 20),
                                    const Divider(),
                                    // Compressed Image
                                    Column(
                                      children: [
                                        const Text(
                                          "Compressed",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        controller.isCompressing.value
                                            ? const SizedBox(
                                                width: 150,
                                                height: 150,
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              )
                                            : GestureDetector(
                                                onTap: () {
                                                  if (controller.compressedImage
                                                          .value !=
                                                      null) {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return Scaffold(
                                                          backgroundColor:
                                                              Colors.white,
                                                          body: Center(
                                                            child: PhotoView(
                                                              imageProvider:
                                                                  FileImage(controller
                                                                      .compressedImage
                                                                      .value!),
                                                              backgroundDecoration:
                                                                  const BoxDecoration(
                                                                      color: Colors
                                                                          .black),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  }
                                                },
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: controller
                                                              .compressedImage
                                                              .value !=
                                                          null
                                                      ? Image.file(
                                                          controller
                                                              .compressedImage
                                                              .value!,
                                                          width: 150,
                                                          height: 150,
                                                          fit: BoxFit.cover,
                                                        )
                                                      : const Text(
                                                          "No Preview",
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.black45,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                        const SizedBox(height: 10),
                                        Text(
                                          controller.imageSize.value,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Quality Slider
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Quality: "),
                                    Expanded(
                                      child: Slider(
                                        value: controller
                                            .compressionQuality.value
                                            .toDouble(),
                                        min: 1,
                                        max: 100,
                                        divisions: 99,
                                        label:
                                            "${controller.compressionQuality.value}%",
                                        onChanged: (value) {
                                          print(
                                              double.tryParse(value.toString())!
                                                  .toInt());
                                          controller.updateCompressionQuality(
                                              double.tryParse(value.toString())!
                                                  .toInt());
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : const Text(
                            "No image selected",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black45,
                            ),
                          );
              }),
            ],
          ),
        ),
      ),
      // Modern Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.photo_library,
                label: 'Gallery',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.camera_alt,
                label: 'Camera',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.compress,
                label: 'Compress',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.save_alt,
                label: 'Save',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Section Header with color styling
  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  // Modern Navigation Item
  Widget _buildNavItem(
      {required IconData icon, required String label, required int index}) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Quality Slider Widget
  Widget _buildQualitySlider() {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Compression Quality: ${compressionQuality.value.toInt()}%",
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          Slider(
            value: compressionQuality.value,
            min: 10,
            max: 100,
            divisions: 9,
            label: "${compressionQuality.value.toInt()}%",
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.grey[300],
            onChanged: (value) {
              compressionQuality.value = value;
            },
          ),
        ],
      );
    });
  }
}
