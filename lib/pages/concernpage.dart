import 'dart:io';
import 'package:Laovista/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import 'custom_header.dart'; // ✅ import your custom header

class Concernpage extends StatefulWidget {
  final int barangayId;

  const Concernpage({Key? key, required this.barangayId}) : super(key: key);

  @override
  State<Concernpage> createState() => _ConcernpageState();
}

class _ConcernpageState extends State<Concernpage> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _titles = [
    'Broken Street Lights',
    'Damaged Road',
    'Flooded Area',
    'Overflowing River',
    'Loud Karaoke',
    'Others'
  ];

  String? _selectedTitle;
  final _otherTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _zoneController = TextEditingController();
  final _streetController = TextEditingController();

  File? _image;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      final compressedXFile = await compressImage(picked);
      if (compressedXFile != null) {
        setState(() => _image = File(compressedXFile.path));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Image compression failed.")),
        );
      }
    }
  }

  Future<void> _showImageSourceActionSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<XFile?> compressImage(XFile file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 15,
      format: CompressFormat.jpeg,
    );

    return result != null ? XFile(result.path) : null;
  }

  Future<void> _submitConcern() async {
    if (!_formKey.currentState!.validate()) return;

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Please select an image.")),
      );
      return;
    }

    final titleToSend = _selectedTitle == 'Others'
        ? _otherTitleController.text.trim()
        : _selectedTitle;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: 'Preview Your Concern',
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPreviewRow("Concern", titleToSend!),
              _buildPreviewRow("Description", _descriptionController.text),
              _buildPreviewRow("Zone", _zoneController.text),
              _buildPreviewRow("Street or Landmark", _streetController.text),
              if (_image != null) ...[
                const SizedBox(height: 12),
                const Text(
                  "Concern Image:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _image!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await _sendConcern(titleToSend!);
      },
    ).show();
  }

  Future<void> _sendConcern(String titleToSend) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Token not found. Please login again.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      final result = await api.sendConcern(
        token: token,
        barangayId: widget.barangayId,
        title: titleToSend,
        description: _descriptionController.text,
        zone: _zoneController.text,
        street: _streetController.text,
        image: _image != null ? XFile(_image!.path) : null,
      );

      if (result['success'] == true) {
        _showSuccessDialog();
        _formKey.currentState?.reset();
        setState(() {
          _selectedTitle = null;
          _otherTitleController.clear();
          _descriptionController.clear();
          _zoneController.clear();
          _streetController.clear();
          _image = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: ${result['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to submit concern: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.bottomSlide,
      title: 'Success',
      desc: 'Concern submitted successfully!',
      btnOkOnPress: () {
        Navigator.of(context).pop();
      },
    ).show();
  }

  @override
  void dispose() {
    _otherTitleController.dispose();
    _descriptionController.dispose();
    _zoneController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style:
              const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.transparent, // para makita ang gradient
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade200, // top
            Colors.blue.shade50,  // bottom
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Solid blue header with back button
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    "Submit a Concern",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // spacer para balance back button
              ],
            ),
          ),

          // Main form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Concern",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedTitle,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      hint: const Text('Select Concern'),
                      items: _titles.map((title) {
                        return DropdownMenuItem(
                          value: title,
                          child: Text(title),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedTitle = value),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please select a title';
                        if (value == 'Others' &&
                            _otherTitleController.text.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    if (_selectedTitle == 'Others') ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _otherTitleController,
                        decoration: InputDecoration(
                          hintText: 'Enter your concern',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (_selectedTitle == 'Others' &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text("Concern Description",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      maxLength: 250,
                      decoration: InputDecoration(
                        hintText: 'Describe the concern in detail...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return 'Required';
                        if (value.length > 250)
                          return 'Maximum 250 characters allowed';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text("Zone",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _zoneController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g. 3',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return 'Required';
                        if (int.tryParse(value.trim()) == null)
                          return 'Must be a number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text("Street or Landmark",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _streetController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Lopez Jaena Street',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value == null ||
                              value.trim().isEmpty
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    const Text("Photo (required)",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    if (_image != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _image!,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                onPressed: () => setState(() => _image = null),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_image == null)
                      OutlinedButton.icon(
                        onPressed: () => _showImageSourceActionSheet(context),
                        icon: const Icon(Icons.image_outlined),
                        label: const Text("Choose Image"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitConcern,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: const Color(0xFF483BF5),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Submit",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
       ),
    );
  }
}
