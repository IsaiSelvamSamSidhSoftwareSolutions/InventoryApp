
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:get_storage/get_storage.dart';
//
// Future<Map<String, dynamic>?> fetchReportData(String reportType, String token, {String? userId}) async {
//   final url = 'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType${userId != null ? '&userId=$userId' : ''}';
//   final response = await http.get(
//     Uri.parse(url),
//     headers: {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token',
//     },
//   );
//
//   print('Response Status: ${response.statusCode}');
//   print('Response Body: ${response.body}');
//
//   if (response.statusCode == 200) {
//     return json.decode(response.body);
//   } else {
//     print('Failed to load report data');
//     return null;
//   }
// }
//
// class Nof_ReportPage extends StatefulWidget {
//   @override
//   _NoReportPageState createState() => _NoReportPageState();
// }
//
// class _NoReportPageState extends State<Nof_ReportPage> {
//   late Future<Map<String, dynamic>?> _reportData;
//   final storage = GetStorage();
//   String? _selectedReportType = 'daily'; // Default to 'daily'
//   String? _userId; // User ID for admin role
//   String? _userRole; // User role
//
//   @override
//   void initState() {
//     super.initState();
//     _userRole = storage.read('UserRole'); // Get user role from GetStorage
//     String token = storage.read('token') ?? '';
//     _reportData = fetchReportData(_selectedReportType!, token); // Use default report type
//   }
//
//   void _updateReportData() {
//     String token = storage.read('token') ?? '';
//     if (_selectedReportType != null) {
//       if (_userRole == 'admin' && _userId != null) {
//         setState(() {
//           _reportData = fetchReportData(_selectedReportType!, token, userId: _userId);
//         });
//       } else {
//         setState(() {
//           _reportData = fetchReportData(_selectedReportType!, token);
//         });
//       }
//     }
//   }
//
//   void _showUserIdDialog(String reportType) {
//     final userIdController = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Enter User ID'),
//           content: TextField(
//             controller: userIdController,
//             decoration: InputDecoration(
//               labelText: 'User ID',
//               border: OutlineInputBorder(),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 setState(() {
//                   _userId = userIdController.text;
//                   _updateReportData();
//                 });
//               },
//               child: Text('Submit'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('Cancel'),
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
//         title: Text('No Reports', style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // DropdownButton for report types
//             InputDecorator(
//               decoration: InputDecoration(
//                 labelText: 'Select Report',
//                 border: OutlineInputBorder(),
//               ),
//               child: DropdownButton<String>(
//                 value: _selectedReportType,
//                 isExpanded: true,
//                 hint: Text('Select Report'), // Display hint if no selection
//                 items: <String>['daily', 'weekly', 'monthly'].map((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value.capitalizeFirstLetter()),
//                   );
//                 }).toList(),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _selectedReportType = newValue;
//                     if (_userRole == 'admin') {
//                       _showUserIdDialog(newValue!);
//                     } else {
//                       _updateReportData();
//                     }
//                   });
//                 },
//               ),
//             ),
//             SizedBox(height: 16),
//             Expanded(
//               child: FutureBuilder<Map<String, dynamic>?>(  // Adjust the future builder
//                 future: _reportData,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return Center(child: CircularProgressIndicator());
//                   } else if (snapshot.hasError) {
//                     print('Error: ${snapshot.error}');
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   } else if (! snapshot.hasData || snapshot.data?['status'] != 'success') {
//                     return Center(child: Text('No report data available.'));
//                   } else {
//                     final reportData = snapshot.data!['data'];
//                     // Assuming reportData has a structure you can display
//                     return Center(
//                       child: Text('No reports available at this time.'),
//                     );
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// extension StringCasingExtension on String {
//   String capitalizeFirstLetter() {
//     if (this.isEmpty) {
//       return this;
//     }
//     return '${this[0].toUpperCase()}${this.substring(1)}';
//   }
// }
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:xml/xml.dart' as xml;
import 'package:file_picker/file_picker.dart';
Future<Map<String, dynamic>?> fetchReportData(String reportType, String token) async {
  final url = 'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType';
  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  print('Response Status: ${response.statusCode}');
  print('Response Body: ${response.body}');

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    print('Failed to load report data');
    return null;
  }
}

class Nof_ReportPage extends StatefulWidget {
  @override
  _NoReportPageState createState() => _NoReportPageState();
}

class _NoReportPageState extends State<Nof_ReportPage> {
  late Future<Map<String, dynamic>?> _reportData;
  final storage = GetStorage();
  String? _selectedReportType = 'daily'; // Default to 'daily'
  String? _downloadPath;

  @override
  void initState() {
    super.initState();
    String token = storage.read('token') ?? '';
    _reportData = fetchReportData(_selectedReportType!, token);
    _downloadPath = storage.read('downloadPath'); // Use default report type
  }

  void _updateReportData() {
    String token = storage.read('token') ?? '';
    if (_selectedReportType != null) {
      setState(() {
        _reportData = fetchReportData(_selectedReportType!, token);
      });
    }
  }
  Future<void> _generateAndSaveCSV(Map<String, dynamic> reportData) async {
    String csvData = 'Department ID, Department Name, UPC, Description, Total Qty, Retail Price, Total Retail\n'; // CSV Header

    // Assuming the report data has a 'formattedReport' key as per previous structure
    final reportList = reportData['data']['formattedReport'] as List<dynamic>;

    for (var department in reportList) {
      for (var product in department['products']) {
        csvData +=
        '${department['deptId'] ?? ''}, ' // Include Department ID
            '${department['deptName'] ?? ''}, ' // Include Department Name
            '${product['upc'] ?? ''}, '
            '${product['description'] ?? ''}, '
            '${product['totalQty']?.toString() ?? '0'}, '
            '${product['retailPrice'] ?? '0.00'}, '
            '${product['totalRetail'] ?? '0.00'}\n'; // Include Retail Price and Total Retail
      }
    }

    await _saveFile(csvData, 'csv');
  }

  Future<void> _generateAndSaveXML(Map<String, dynamic> reportData) async {
    final builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('Report', nest: () {
      // Assuming the report data has a 'formattedReport' key
      final reportList = reportData['data']['formattedReport'] as List<dynamic>;

      for (var department in reportList) {
        builder.element('Department', nest: () {
          builder.element('departmentId', nest: department['deptId'] ?? 'Unknown Department ID');
          builder.element('departmentName', nest: department['deptName'] ?? 'Unknown Department Name');

          for (var product in department['products'] ?? []) {
            builder.element('Product', nest: () {
              builder.element('upc', nest: product['upc'] ?? 'Unknown UPC');
              builder.element('description', nest: product['description'] ?? 'No Description');
              builder.element('totalQty', nest: product['totalQty']?.toString() ?? '0');
              builder.element('retailPrice', nest: product['retailPrice'] ?? '0.00');
              builder.element('totalRetail', nest: product['totalRetail'] ?? '0.00');
            });
          }
        });
      }
    });

    final xmlData = builder.buildDocument().toString();
    await _saveFile(xmlData, 'xml');
  }

  Future<void> _saveFile(String data, String extension) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      print('No directory selected. File not saved.');
      return;
    }

    try {
      final fileName = 'report_${DateTime
          .now()
          .millisecondsSinceEpoch}.$extension';
      final filePath = '$selectedDirectory/$fileName';
      final file = File(filePath);
      await file.writeAsString(data);

      // Store the selected path in GetStorage
      storage.write('downloadPath', selectedDirectory);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$extension file saved to $filePath'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      print('Error saving file: $e'); // Log error to console
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Cant use this folder . Instead of this ! Choose Document Folder '),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showDownloadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.file_download),
                title: Text('Download as CSV'),
                onTap: () async {
                  Navigator.pop(context);
                  final report = await _reportData;
                  if (report != null) await _generateAndSaveCSV(report);
                },
              ),
              ListTile(
                leading: Icon(Icons.file_download),
                title: Text('Download as XML'),
                onTap: () async {
                  Navigator.pop(context);
                  final report = await _reportData;
                  if (report != null) await _generateAndSaveXML(report);
                },
              ),
              ListTile(
                leading: Icon(Icons.folder),
                title: Text('Change Download Location'),
                onTap: () async {
                  Navigator.pop(context);
                  String? selectedDirectory = await FilePicker.platform
                      .getDirectoryPath();
                  if (selectedDirectory != null) {
                    setState(() {
                      _downloadPath = selectedDirectory;
                      storage.write('downloadPath',
                          selectedDirectory); // Cache the new path
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Download path changed to $selectedDirectory'),
                    ));
                  }
                },
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
        title: Text('No Reports', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DropdownButton for report types
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Select Report',
                border: OutlineInputBorder(),
              ),
              child: DropdownButton<String>(
                value: _selectedReportType,
                isExpanded: true,
                hint: Text('Select Report'),
                // Display hint if no selection
                items: <String>['daily', 'weekly', 'monthly'].map((
                    String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.capitalizeFirstLetter()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedReportType = newValue;
                    _updateReportData();
                  });
                },
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _reportData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    print('Error: ${snapshot.error}');
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData ||
                      snapshot.data?['status'] != 'success') {
                    return Center(child: Text('No report data available.'));
                  } else {
                    final reportData = snapshot.data!['data'];
                    final formattedReport = reportData['formattedReport'];

                    return ListView.builder(
                      itemCount: formattedReport.length,
                      itemBuilder: (context, index) {
                        final department = formattedReport[index];
                        final products = department['products'];

                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dept #${department['deptId']} - ${department['deptName']}',
                                  style: TextStyle(fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                ...products.map<Widget>((product) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Text(
                                      'UPC: ${product['upc']} - ${product['description']} - Qty: ${product['totalQty']} - Retail: \$${product['retailPrice']} - Total: \$${product['totalRetail']}',
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showDownloadOptions,
        child: Icon(Icons.download),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalizeFirstLetter() {
    if (this.isEmpty) {
      return this;
    }
    return '${this[0].toUpperCase()}${this.substring(1)}';
  }
}