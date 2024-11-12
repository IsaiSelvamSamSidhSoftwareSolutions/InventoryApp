import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http_parser/http_parser.dart';

class Departmentxmlupload extends StatefulWidget {
  @override
  _UploadAndFetchPageState createState() => _UploadAndFetchPageState();
}

class _UploadAndFetchPageState extends State<Departmentxmlupload> {
  bool _isUploading = false;
  final GetStorage _storage = GetStorage();
  String _uploadStatus = '';
  // String _userId = ''; // User ID to be entered by the admin
  String? _userId;
  bool _isAdmin = false; // Check if the user is an admin
  bool _isUserIdProvided = false; // Check if user ID is provided for admin

  @override
  void initState() {
    super.initState();
    _checkUserRole(); // Check if the user is an admin when the widget is initialized
  }

  Future<void> _checkUserRole() async {
    String? userRole = _storage.read('userRole'); // Get User Role from storage
    if (userRole == 'admin') {
      setState(() {
        _isAdmin = true;
      });
    }
  }

  Future<void> uploadXML() async {
    if (_isAdmin && _isUserIdProvided) {
      print("Admin detected, asking for User ID..."); // Console log for admin
      await _showUserIdInputDialog(); // Show dialog for User ID input
      // After showing dialog, check if userId is provided
      if (_userId!.isEmpty) {
        print("UI Error: User ID cannot be empty for admin."); // Print UI error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ID cannot be empty.')),
        );
      } else {
        _triggerFilePicker(); // Trigger file picker after user ID is provided
      }
    }
    else {
      _triggerFilePicker(); // Trigger file picker if user is not admin or user ID is already provided
    }
  }

  Future<void> _triggerFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml']
    );

    if (result == null) {
      print("UI Error: No file selected."); // Print UI error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file selected.')),
      );
      return;
    }

    if (result.files.length > 1) {
      print("UI Error: More than one file selected."); // Print UI error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select only one XML file.')),
      );
      return;
    }

    File file = File(result.files.single.path!);
    String fileName = result.files.single.name;

    if (!fileName.endsWith('.xml')) {
      print("UI Error: Invalid file format. Please select an XML file."); // Print UI error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a valid XML file.')),
      );
      return;
    }

    String url = 'https://iscandata.com/api/v1/departments/upload-xml';
    String? token = _storage.read('token');

    if (token == null || token.isEmpty) {
      print("UI Error: No token found. Please log in."); // Print UI error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No token found. Please log in.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Uploading...';
    });

    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType('application', 'xml'),
        ),
        'userId': _userId, // Use the user ID entered by the admin
      });

      var response = await Dio().post(
        url,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 201) {
        var message = response.data['message'] ?? 'Upload failed.';
        print("API Success: $message"); // Print success message from API
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } else {
        var errorMessage = response.data['message'] ?? 'Upload failed.';
        _uploadStatus = '$errorMessage';
        print("API Error: $errorMessage"); // Print API error in console
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_uploadStatus)),
        );
      }
    } catch (e) {
      if (e is DioError) {
        _uploadStatus = 'Error uploading file: ${e.response?.data ?? e.message}';
        print("API Error: ${e.response?.data ?? e.message}"); // Print Dio error in console
      } else {
        _uploadStatus = 'Unexpected error: $e';
        print("Unexpected Error: $e"); // Print unexpected error
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_uploadStatus)),
      );
    }
  }

  Future<void> _showUserIdInputDialog() async {
    // Reset userId before showing dialog
    _userId = '';
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter User ID'),
          content: TextField(
            onChanged: (value) {
              _userId = value;
            },
            decoration: InputDecoration(hintText: "User ID"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_userId!.isNotEmpty) {
                  setState(() {
                    _isUserIdProvided = true; // Mark user ID as provided
                  });
                  Navigator.of(context).pop();
                } else {
                  print("UI Error: User ID cannot be empty."); // Print UI error in console
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a User ID')),
                  );
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Department XML'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isUploading || (_isAdmin && !_isUserIdProvided)
                    ? null
                    : uploadXML,
                icon: _isUploading
                    ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2.0,
                  ),
                )
                    : Icon(Icons.upload_file),
                label: Text(_isUploading
                    ? 'Uploading...'
                    : _isAdmin && !_isUserIdProvided
                    ? 'Enter User ID'
                    : 'Upload XML File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              SizedBox(height: 20),
              Text(
                _uploadStatus,
                style: TextStyle(
                  color: _uploadStatus.contains('successfully') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
