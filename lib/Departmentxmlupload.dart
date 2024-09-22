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

  Future<void> uploadXML() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
    );

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file selected.')),
      );
      return;
    }

    if (result.files.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select only one XML file.')),
      );
      return;
    }

    File file = File(result.files.single.path!);
    String fileName = result.files.single.name;

    if (!fileName.endsWith('.xml')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a valid XML file.')),
      );
      return;
    }

    String url = 'https://iscandata.com/api/v1/departments/upload-xml';
    String? token = _storage.read('token');
    String? userId = _storage.read('userId');

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No token found. Please log in.')),
      );
      return;
    }

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No UserId found. Please log in.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Uploading...';
    });

    // Show modal dialog
    AlertDialog alert = AlertDialog(
      title: Text('Upload Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(_uploadStatus),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Optionally handle cancellation here
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('Cancel'),
        ),
      ],
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return alert;
      },
    );

    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType('application', 'xml'),
        ),
        'userId': userId,
      });

      var response = await Dio().post(
        url,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        _uploadStatus = 'XML uploaded successfully!';
      } else {
        var errorMessage = response.data['message'] ?? 'Upload failed.';
        _uploadStatus = 'Upload failed: $errorMessage';
      }
    } catch (e) {
      if (e is DioError) {
        _uploadStatus = 'Error uploading file: ${e.response?.data ?? e.message}';
      } else {
        _uploadStatus = 'Unexpected error: $e';
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
      // Close the dialog and show a snack bar with the final status
      Navigator.of(context).pop(); // Close the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_uploadStatus)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isUploading ? null : uploadXML,
              icon: _isUploading
                  ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : Icon(Icons.upload_file),
              label: Text(_isUploading ? 'Uploading...' : 'Upload XML File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
