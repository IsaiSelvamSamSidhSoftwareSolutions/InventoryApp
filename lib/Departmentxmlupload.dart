//
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:dio/dio.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:http_parser/http_parser.dart';
//
// class Departmentxmlupload extends StatefulWidget {
//   @override
//   _UploadAndFetchPageState createState() => _UploadAndFetchPageState();
// }
//
// class _UploadAndFetchPageState extends State<Departmentxmlupload> {
//   bool _isUploading = false;
//   final GetStorage _storage = GetStorage();
//   String _uploadStatus = '';
//   String _userId = ''; // User ID to be entered by the admin
//
//   Future<void> uploadXML() async {
//     String? userRole = _storage.read('userRole'); // Get User Role from storage
//
//     // Check if the user is an admin
//     if (userRole == 'admin') {
//       await _showUserIdInputDialog(); // Show dialog for User ID input
//
//       // Check if userId is empty after dialog
//       if (_userId.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('User ID cannot be empty.')),
//         );
//         return; // Exit if User ID is empty
//       }
//     }
//
//     // Proceed to file selection
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['xml'],
//     );
//
//     if (result == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('No file selected.')),
//       );
//       return;
//     }
//
//     if (result.files.length > 1) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please select only one XML file.')),
//       );
//       return;
//     }
//
//     File file = File(result.files.single.path!);
//     String fileName = result.files.single.name;
//
//     if (!fileName.endsWith('.xml')) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please select a valid XML file.')),
//       );
//       return;
//     }
//
//     String url = 'https://iscandata.com/api/v1/departments/upload-xml';
//     String? token = _storage.read('token');
//
//     if (token == null || token.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('No token found. Please log in.')),
//       );
//       return;
//     }
//
//     setState(() {
//       _isUploading = true;
//       _uploadStatus = 'Uploading...';
//     });
//
//     try {
//       FormData formData = FormData.fromMap({
//         'file': await MultipartFile.fromFile(
//           file.path,
//           filename: fileName,
//           contentType: MediaType('application', 'xml'),
//         ),
//         'userId': _userId, // Use the user ID entered by the admin
//       });
//
//       var response = await Dio().post(
//         url,
//         data: formData,
//         options: Options(
//           headers: {'Authorization': 'Bearer $token'},
//           validateStatus: (status) => status! < 500,
//         ),
//       );
//
//       if (response.statusCode == 201) {
//         var message = response.data['message'] ?? 'Upload failed.';
//         Navigator.of(context).pop();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(message)),
//         );
//       } else {
//         var errorMessage = response.data['message'] ?? 'Upload failed.';
//         _uploadStatus = '$errorMessage';
//         print("Upload Succesfull $_uploadStatus");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(_uploadStatus)),
//         );
//       }
//     } catch (e) {
//       if (e is DioError) {
//         _uploadStatus = 'Error uploading file: ${e.response?.data ?? e.message}';
//       } else {
//         _uploadStatus = 'Unexpected error: $e';
//       }
//     } finally {
//       setState(() {
//         _isUploading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(_uploadStatus)),
//       );
//     }
//   }
//
//   Future<void> _showUserIdInputDialog() async {
//     // Reset userId before showing dialog
//     _userId = '';
//     return showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Enter User ID'),
//           content: TextField(
//             onChanged: (value) {
//               _userId = value;
//             },
//             decoration: InputDecoration(hintText: "User ID"),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 if (_userId.isNotEmpty) {
//                   Navigator.of(context).pop();
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a User ID')),
//                   );
//                 }
//               },
//               child: Text('Submit'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Upload Department XML'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton.icon(
//                 onPressed: _isUploading ? null : uploadXML,
//                 icon: _isUploading
//                     ? SizedBox(
//                   height: 24,
//                   width: 24,
//                   child: CircularProgressIndicator(
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     strokeWidth: 2.0,
//                   ),
//                 )
//                     : Icon(Icons.upload_file),
//                 label: Text(_isUploading ? 'Uploading...' : 'Upload XML File'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blueAccent,
//                   padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 ),
//               ),
//               SizedBox(height: 20),
//               Text(
//                 _uploadStatus,
//                 style: TextStyle(
//                   color: _uploadStatus.contains('successfully') ? Colors.green : Colors.red,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
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
  String _userId = ''; // User ID to be entered by the admin
  File? _file; // Selected file

  Future<void> uploadXML() async {
    // Show the User ID input bottom sheet first
    await _showUserIdInputBottomSheet();

    // Check if userId is empty after dialog
    if (_userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID cannot be empty.')),
      );
      return; // Exit if User ID is empty
    }

    // Proceed to file selection
    await _selectFile();
  }

  Future<void> _selectFile() async {
    // Proceed to file selection
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

    setState(() {
      _file = File(result.files.single.path!);
    });

    // Call the upload file method after file selection
    await _uploadFile();
  }

  Future<void> _uploadFile() async {
    if (_file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file selected.')),
      );
      return;
    }

    String fileName = _file!.path.split('/').last;
    if (!fileName.endsWith('.xml')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a valid XML file.')),
      );
      return;
    }

    String url = 'https://iscandata.com/api/v1/departments/upload-xml';
    String? token = _storage.read('token');

    if (token == null || token.isEmpty) {
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
          _file!.path,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } else {
        var errorMessage = response.data['message'] ?? 'Upload failed.';
        _uploadStatus = '$errorMessage';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_uploadStatus)),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_uploadStatus)),
      );
    }
  }

  Future<void> _showUserIdInputBottomSheet() async {
    // Reset userId before showing bottom sheet
    _userId = '';
    return showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter User ID',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextField(
                onChanged: (value) {
                  _userId = value;
                },
                decoration: InputDecoration(hintText: "User ID"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_userId.isNotEmpty) {
                    Navigator.of(context).pop(); // Close bottom sheet if user ID is valid
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('User ID cannot be empty.')),
                    );
                  }
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload XML'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isUploading ? null : uploadXML,
              child: Text('Upload XML'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(_uploadStatus),
          ],
        ),
      ),
    );
  }
}
