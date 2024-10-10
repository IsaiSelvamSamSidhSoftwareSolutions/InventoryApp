// // //
// // // import 'package:flutter/material.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'dart:convert';
// // // import 'package:get_storage/get_storage.dart';
// // //
// // // Future<Map<String, dynamic>> fetchReportData(String reportType, String token, BuildContext context) async {
// // //   final url = 'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType';
// // //
// // //   try {
// // //     final response = await http.get(
// // //       Uri.parse(url),
// // //       headers: {
// // //         'Content-Type': 'application/json',
// // //         'Authorization': 'Bearer $token',
// // //       },
// // //     );
// // //
// // //     print('Request URL: $url');
// // //     print('Response Status: ${response.statusCode}');
// // //     print('Response Body: ${response.body}');
// // //
// // //     if (response.statusCode == 200) {
// // //       return json.decode(response.body);
// // //     } else if (response.statusCode == 401) {
// // //       // Token blacklisted, navigate to login page
// // //       Navigator.pushReplacementNamed(context, '/login');
// // //       throw Exception('Token blacklisted, navigating to login page.');
// // //     } else {
// // //       final errorData = json.decode(response.body);
// // //       print('Error details: ${errorData['error']}');
// // //       throw Exception('Failed to load report data: ${errorData['message']}');
// // //     }
// // //   } catch (error) {
// // //     print('Fetch error: $error');
// // //     throw error;
// // //   }
// // // }
// // //
// // // class ReportPage extends StatefulWidget {
// // //   @override
// // //   _ReportPageState createState() => _ReportPageState();
// // // }
// // //
// // // class _ReportPageState extends State<ReportPage> {
// // //   late Future<Map<String, dynamic>> _reportData;
// // //   final storage = GetStorage();
// // //   String _selectedReportType = 'daily'; // Default report type
// // //   final _searchController = TextEditingController();
// // //   List<dynamic> _filteredReportList = [];
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _searchController.addListener(_filterReports);
// // //     _updateReportData(); // Automatically fetch the report when the page loads
// // //   }
// // //
// // //   void _updateReportData() {
// // //     String token = storage.read('token') ?? '';
// // //
// // //     setState(() {
// // //       _reportData = fetchReportData(_selectedReportType, token, context);
// // //     });
// // //   }
// // //
// // //   void _filterReports() {
// // //     final query = _searchController.text.toLowerCase();
// // //     setState(() {
// // //       _filteredReportList = _filteredReportList.where((report) {
// // //         final deptName = (report['departmentName'] as String).toLowerCase();
// // //         return deptName.contains(query);
// // //       }).toList();
// // //     });
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: Text('Reports', style: TextStyle(color: Colors.white)),
// // //         backgroundColor: Colors.blueAccent,
// // //       ),
// // //       body: Padding(
// // //         padding: const EdgeInsets.all(16.0),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             // Add a Text widget for the dropdown label
// // //             Text(
// // //               'Select Report Type',
// // //               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
// // //             ),
// // //             SizedBox(height: 8), // Add some space between the text and the dropdown
// // //             Container(
// // //               decoration: BoxDecoration(
// // //                 border: Border.all(color: Colors.blueAccent), // Border color
// // //                 borderRadius: BorderRadius.circular(8), // Rounded corners
// // //               ),
// // //               child: DropdownButton<String>(
// // //                 isExpanded: true, // Make the dropdown extend left to right
// // //                 value: _selectedReportType,
// // //                 items: <String>['daily', 'weekly', 'monthly'].map((String value) {
// // //                   return DropdownMenuItem<String>(
// // //                     value: value,
// // //                     child: Text(value),
// // //                   );
// // //                 }).toList(),
// // //                 onChanged: (String? newValue) {
// // //                   setState(() {
// // //                     _selectedReportType = newValue!;
// // //                     _updateReportData(); // Fetch new data based on the selected report type
// // //                   });
// // //                 },
// // //               ),
// // //             ),
// // //             SizedBox(height: 16),
// // //             TextField(
// // //               controller: _searchController,
// // //               decoration: InputDecoration(
// // //                 labelText: 'Search Department Name',
// // //                 prefixIcon: Icon(Icons.search),
// // //               ),
// // //             ),
// // //             SizedBox(height: 16),
// // //             Expanded(
// // //               child: FutureBuilder<Map<String, dynamic>>(
// // //                 future: _reportData,
// // //                 builder: (context, snapshot) {
// // //                   if (snapshot.connectionState == ConnectionState.waiting) {
// // //                     return Center(child: CircularProgressIndicator());
// // //                   } else if (snapshot.hasError) {
// // //                     return Center(child: Text('No Report found'));
// // //                   } else if (!snapshot.hasData || snapshot.data?['status'] != 'success') {
// // //                     return Center(child: Text('No data available or error occurred.'));
// // //                   } else {
// // //                     final reportData = snapshot.data!['data'];
// // //                     if (reportData == null || reportData['reportData'] == null) {
// // //                       return Center(child: Text('No report data available for selected type.'));
// // //                     }
// // //
// // //                     final reportList = reportData['reportData'] as List<dynamic>;
// // //                     final cards = <Widget>[];
// // //
// // //                     for (var zone in reportList) {
// // //                       for (var device in zone['devices']) {
// // //                         for (var product in device['products']) {
// // //                           cards.add(
// // //                             Card(
// // //                               elevation: 4,
// // //                               margin: EdgeInsets.symmetric(vertical: 4),
// // //                               color: Colors.blue[300],
// // //                               child: ListTile(
// // //                                 title: Container(
// // //                                   padding: EdgeInsets.all(8.0),
// // //                                   child: Column(
// // //                                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                                     children: [
// // //                                       Text(
// // //                                         'Department Name: ${product['departmentName']}',
// // //                                         style: TextStyle(
// // //                                           fontSize: 16,
// // //                                           fontWeight: FontWeight.bold,
// // //                                           color: Colors.black,
// // //                                         ),
// // //                                       ),
// // //                                       SizedBox(height: 5),
// // //                                       Text(
// // //                                         'Zone Name: ${zone['zoneName']}',
// // //                                         style: TextStyle(
// // //                                           fontSize: 14,
// // //                                           color: Colors.black87,
// // //                                         ),
// // //                                       ),
// // //                                       SizedBox(height: 5),
// // //                                       Text(
// // //                                         'UPC: ${product['upc']}',
// // //                                         style: TextStyle(
// // //                                           fontSize: 14,
// // //                                           color: Colors.black87,
// // //                                         ),
// // //                                       ),
// // //                                       SizedBox(height: 5),
// // //                                       Text(
// // //                                         'Description: ${product['description']}',
// // //                                         style: TextStyle(
// // //                                           fontSize: 14,
// // //                                           color: Colors.black87,
// // //                                         ),
// // //                                       ),
// // //                                       Text(
// // //                                         'Total Qty: ${product['totalQty']}',
// // //                                         style: TextStyle(
// // //                                           fontSize: 14,
// // //                                           color: Colors.black87,
// // //                                         ),
// // //                                       ),
// // //                                     ],
// // //                                   ),
// // //                                 ),
// // //                               ),
// // //                             ),
// // //                           );
// // //                         }
// // //                       }
// // //                     }
// // //
// // //                     return ListView(children: cards);
// // //                   }
// // //                 },
// // //               ),
// // //             ),
// // //             ElevatedButton(
// // //               onPressed: _updateReportData,
// // //               child: Text('Refresh Report'),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     _searchController.dispose();
// // //     super.dispose();
// // //   }
// // // }
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import 'dart:io'; // For file I/O
// // import 'package:get_storage/get_storage.dart';
// // import 'package:path_provider/path_provider.dart'; // For getting the path
// // import 'package:permission_handler/permission_handler.dart'; // For handling permissions
// //
// // Future<Map<String, dynamic>> fetchReportData(String reportType, String token, BuildContext context) async {
// //   final url = 'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType';
// //
// //   try {
// //     final response = await http.get(
// //       Uri.parse(url),
// //       headers: {
// //         'Content-Type': 'application/json',
// //         'Authorization': 'Bearer $token',
// //       },
// //     );
// //
// //     print('Request URL: $url');
// //     print('Response Status: ${response.statusCode}');
// //     print('Response Body: ${response.body}');
// //
// //     if (response.statusCode == 200) {
// //       return json.decode(response.body);
// //     } else if (response.statusCode == 401) {
// //       // Token blacklisted, navigate to login page
// //       Navigator.pushReplacementNamed(context, '/login');
// //       throw Exception('Token blacklisted, navigating to login page.');
// //     } else {
// //       final errorData = json.decode(response.body);
// //       print('Error details: ${errorData['error']}');
// //       throw Exception('Failed to load report data: ${errorData['message']}');
// //     }
// //   } catch (error) {
// //     print('Fetch error: $error');
// //     throw error;
// //   }
// // }
// //
// // class ReportPage extends StatefulWidget {
// //   @override
// //   _ReportPageState createState() => _ReportPageState();
// // }
// //
// // class _ReportPageState extends State<ReportPage> {
// //   late Future<Map<String, dynamic>> _reportData;
// //   final storage = GetStorage();
// //   String _selectedReportType = 'daily'; // Default report type
// //   final _searchController = TextEditingController();
// //   List<dynamic> _filteredReportList = [];
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _searchController.addListener(_filterReports);
// //     _updateReportData();
// //     _requestStoragePermission();// Automatically fetch the report when the page loads
// //   }
// //
// //   Future<void> _updateReportData() async {
// //     String token = storage.read('token') ?? '';
// //
// //     setState(() {
// //       _reportData = fetchReportData(_selectedReportType, token, context);
// //     });
// //
// //     final report = await _reportData;
// //     await _generateAndSaveCSV(report);
// //   }
// //
// //   void _filterReports() {
// //     final query = _searchController.text.toLowerCase();
// //     setState(() {
// //       _filteredReportList = _filteredReportList.where((report) {
// //         final deptName = (report['departmentName'] as String).toLowerCase();
// //         return deptName.contains(query);
// //       }).toList();
// //     });
// //   }
// //
// //   Future<void> _generateAndSaveCSV(Map<String, dynamic> reportData) async {
// //     // Create CSV data from the reportData
// //     String csvData = 'Department Name, Zone Name, UPC, Description, Total Qty\n'; // Header
// //     final reportList = reportData['data']['reportData'] as List<dynamic>;
// //
// //     for (var zone in reportList) {
// //       for (var device in zone['devices']) {
// //         for (var product in device['products']) {
// //           csvData +=
// //           '${product['departmentName']}, ${zone['zoneName']}, ${product['upc']}, ${product['description']}, ${product['totalQty']}\n';
// //         }
// //       }
// //     }
// //
// //     // Save the CSV file to a custom folder in external storage
// //     await _saveFileToLocal(csvData);
// //   }
// //   Future<void> _requestStoragePermission() async {
// //     final status = await Permission.storage.status;
// //
// //     if (status.isPermanentlyDenied) {
// //       final permissionStatus = await Permission.storage.request();
// //
// //       if (permissionStatus.isGranted) {
// //         print('Storage permission granted');
// //       } else {
// //         print('Storage permission denied');
// //         openAppSettings(); // Open app settings for the user to enable permission
// //       }
// //       // If permission is permanently denied, prompt the user to open settings
// //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //         content: Text('Storage permission is permanently denied. Please enable it from settings.'),
// //         backgroundColor: Colors.red,
// //         action: SnackBarAction(
// //           label: 'Settings',
// //           onPressed: () {
// //             openAppSettings(); // Open app settings if permission is permanently denied
// //           },
// //         ),
// //       ));
// //     } else if (status.isDenied) {
// //       // Request permission if not granted
// //       final permissionStatus = await Permission.storage.request();
// //
// //       if (permissionStatus.isGranted) {
// //         print('Storage permission granted');
// //       } else if (permissionStatus.isDenied) {
// //         print('Storage permission denied');
// //       }
// //     }
// //   }
// //
// //
// //   Future<void> _saveFileToLocal(String csvData) async {
// //     // Check if the storage permission is granted
// //     final status = await Permission.storage.status;
// //
// //     if (!status.isGranted) {
// //       // Request permission if not granted
// //       await _requestStoragePermission();
// //       // After requesting permission, check the status again
// //       final newStatus = await Permission.storage.status;
// //       print("Status $newStatus");
// //       if (newStatus.isGranted) {
// //         try {
// //           // Get external storage directory
// //           Directory? externalDir = await getExternalStorageDirectory();
// //
// //           if (externalDir != null) {
// //             // Create a Reports folder in the external directory
// //             final reportsDir = Directory('${externalDir.path}/Reports');
// //             if (!await reportsDir.exists()) {
// //               await reportsDir.create(recursive: true); // Create the Reports folder if it doesn't exist
// //             }
// //
// //             // Define the file name with the current timestamp
// //             final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.csv';
// //             final filePath = '${reportsDir.path}/$fileName';
// //
// //             // Create the file and write the CSV data
// //             final file = File(filePath);
// //             await file.writeAsString(csvData);
// //
// //             // Show a success message
// //             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //               content: Text('CSV file saved to $filePath'),
// //               backgroundColor: Colors.green,
// //             ));
// //             print('CSV saved at: $filePath');
// //           }
// //         } catch (e) {
// //           print('Error saving CSV: $e');
// //           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //             content: Text('Failed to save CSV file'),
// //             backgroundColor: Colors.red,
// //           ));
// //         }
// //       } else {
// //         // If permission is still denied after requesting, show an error
// //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //           content: Text('Storage permission denied'),
// //           backgroundColor: Colors.red,
// //         ));
// //       }
// //     } else {
// //       try {
// //         // Get external storage directory
// //         Directory? externalDir = await getExternalStorageDirectory();
// //
// //         if (externalDir != null) {
// //           // Create a Reports folder in the external directory
// //           final reportsDir = Directory('${externalDir.path}/Reports');
// //           if (!await reportsDir.exists()) {
// //             await reportsDir.create(recursive: true); // Create the Reports folder if it doesn't exist
// //           }
// //
// //           // Define the file name with the current timestamp
// //           final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.csv';
// //           final filePath = '${reportsDir.path}/$fileName';
// //
// //           // Create the file and write the CSV data
// //           final file = File(filePath);
// //           await file.writeAsString(csvData);
// //
// //           // Show a success message
// //           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //             content: Text('CSV file saved to $filePath'),
// //             backgroundColor: Colors.green,
// //           ));
// //           print('CSV saved at: $filePath');
// //         }
// //       } catch (e) {
// //         print('Error saving CSV: $e');
// //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //           content: Text('Failed to save CSV file'),
// //           backgroundColor: Colors.red,
// //         ));
// //       }
// //     }
// //   }
// //   void _onDownloadPressed() async {
// //     // Check if storage permission is granted
// //     final status = await Permission.storage.status;
// //
// //     if (status.isGranted) {
// //       // Permission is granted, proceed to fetch and download the report
// //       try {
// //         String token = storage.read('token') ?? '';
// //         final report = await fetchReportData(_selectedReportType, token, context);
// //         await _generateAndSaveCSV(report);
// //       } catch (e) {
// //         print('Error downloading report: $e');
// //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //           content: Text('Error downloading report: $e'),
// //           backgroundColor: Colors.red,
// //         ));
// //       }
// //     } else {
// //       // Permission is denied, show a Snackbar and redirect to settings
// //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //         content: Text('Storage permission is required to download the report.'),
// //         backgroundColor: Colors.red,
// //         action: SnackBarAction(
// //           label: 'Settings',
// //           onPressed: () {
// //             openAppSettings(); // Open app settings for the user to enable permission
// //           },
// //         ),
// //       ));
// //     }
// //   }
// //
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Reports', style: TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.blueAccent,
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text('Select Report Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //             SizedBox(height: 8),
// //             Container(
// //               decoration: BoxDecoration(
// //                 border: Border.all(color: Colors.blueAccent),
// //                 borderRadius: BorderRadius.circular(8),
// //               ),
// //               child: DropdownButton<String>(
// //                 isExpanded: true,
// //                 value: _selectedReportType,
// //                 items: <String>['daily', 'weekly', 'monthly'].map((String value) {
// //                   return DropdownMenuItem<String>(
// //                     value: value,
// //                     child: Text(value),
// //                   );
// //                 }).toList(),
// //                 onChanged: (String? newValue) {
// //                   setState(() {
// //                     _selectedReportType = newValue!;
// //                     _updateReportData(); // Fetch new data based on the selected report type
// //                   });
// //                 },
// //               ),
// //             ),
// //             SizedBox(height: 16),
// //             TextField(
// //               controller: _searchController,
// //               decoration: InputDecoration(
// //                 labelText: 'Search Department Name',
// //                 prefixIcon: Icon(Icons.search),
// //               ),
// //             ),
// //             SizedBox(height: 16),
// //             Expanded(
// //               child: FutureBuilder<Map<String, dynamic>>(
// //                 future: _reportData,
// //                 builder: (context, snapshot) {
// //                   if (snapshot.connectionState == ConnectionState.waiting) {
// //                     return Center(child: CircularProgressIndicator());
// //                   } else if (snapshot.hasError) {
// //                     return Center(child: Text('No Report found'));
// //                   } else if (!snapshot.hasData || snapshot.data?['status'] != 'success') {
// //                     return Center(child: Text('No data available or error occurred.'));
// //                   } else {
// //                     final reportData = snapshot.data!['data'];
// //                     if (reportData == null || reportData['reportData'] == null) {
// //                       return Center(child: Text('No report data available for selected type.'));
// //                     }
// //
// //                     final reportList = reportData['reportData'] as List<dynamic>;
// //                     final cards = <Widget>[];
// //
// //                     for (var zone in reportList) {
// //                       for (var device in zone['devices']) {
// //                         for (var product in device['products']) {
// //                           cards.add(
// //                             Card(
// //                               elevation: 4,
// //                               margin: EdgeInsets.symmetric(vertical: 4),
// //                               color: Colors.blue[300],
// //                               child: ListTile(
// //                                 title: Container(
// //                                   padding: EdgeInsets.all(8.0),
// //                                   child: Column(
// //                                     crossAxisAlignment: CrossAxisAlignment.start,
// //                                     children: [
// //                                       Text(
// //                                         'Department Name: ${product['departmentName']}',
// //                                         style: TextStyle(
// //                                           fontSize: 16,
// //                                           fontWeight: FontWeight.bold,
// //                                           color: Colors.black,
// //                                         ),
// //                                       ),
// //                                       SizedBox(height: 5),
// //                                       Text(
// //                                         'Zone Name: ${zone['zoneName']}',
// //                                         style: TextStyle(
// //                                           fontSize: 14,
// //                                           color: Colors.black87,
// //                                         ),
// //                                       ),
// //                                       SizedBox(height: 5),
// //                                       Text(
// //                                         'UPC: ${product['upc']}',
// //                                         style: TextStyle(
// //                                           fontSize: 14,
// //                                           color: Colors.black87,
// //                                         ),
// //                                       ),
// //                                       SizedBox(height: 5),
// //                                       Text(
// //                                         'Description: ${product['description']}',
// //                                         style: TextStyle(
// //                                           fontSize: 14,
// //                                           color: Colors.black87,
// //                                         ),
// //                                       ),
// //                                       SizedBox(height: 5),
// //                                       Text(
// //                                         'Total Qty: ${product['totalQty']}',
// //                                         style: TextStyle(
// //                                           fontSize: 14,
// //                                           color: Colors.black87,
// //                                         ),
// //                                       ),
// //                                     ],
// //                                   ),
// //                                 ),
// //                               ),
// //                             ),
// //                           );
// //                         }
// //                       }
// //                     }
// //                     return ListView(children: cards);
// //                   }
// //                 },
// //               ),
// //             ),
// //             SizedBox(height: 16),
// //             ElevatedButton(
// //               onPressed: _onDownloadPressed,
// //               child: Text('Download Report'),
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: Colors.green,
// //                 padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:io'; // For file I/O
// import 'package:get_storage/get_storage.dart';
// import 'package:path_provider/path_provider.dart'; // For getting the path
// //import 'package:share_plus/share_plus.dart';
// Future<Map<String, dynamic>> fetchReportData(String reportType, String token, BuildContext context) async {
//   final url = 'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType';
//
//   try {
//     final response = await http.get(
//       Uri.parse(url),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//     );
//
//     print('Request URL: $url');
//     print('Response Status: ${response.statusCode}');
//     print('Response Body: ${response.body}');
//
//     if (response.statusCode == 200) {
//       return json.decode(response.body);
//     } else if (response.statusCode == 401) {
//       // Token blacklisted, navigate to login page
//       Navigator.pushReplacementNamed(context, '/login');
//       throw Exception('Token blacklisted, navigating to login page.');
//     } else {
//       final errorData = json.decode(response.body);
//       print('Error details: ${errorData['error']}');
//       throw Exception('Failed to load report data: ${errorData['message']}');
//     }
//   } catch (error) {
//     print('Fetch error: $error');
//     throw error;
//   }
// }
//
// class ReportPage extends StatefulWidget {
//   @override
//   _ReportPageState createState() => _ReportPageState();
// }
//
// class _ReportPageState extends State<ReportPage> {
//   late Future<Map<String, dynamic>> _reportData;
//   final storage = GetStorage();
//   String _selectedReportType = 'daily'; // Default report type
//   final _searchController = TextEditingController();
//   List<dynamic> _filteredReportList = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(_filterReports);
//     _updateReportData(); // Automatically fetch the report when the page loads
//   }
//
//   Future<void> _updateReportData() async {
//     String token = storage.read('token') ?? '';
//
//     setState(() {
//       _reportData = fetchReportData(_selectedReportType, token, context);
//     });
//
//     final report = await _reportData;
//     await _generateAndSaveCSV(report);
//   }
//
//   void _filterReports() {
//     final query = _searchController.text.toLowerCase();
//     setState(() {
//       _filteredReportList = _filteredReportList.where((report) {
//         final deptName = (report['departmentName'] as String).toLowerCase();
//         return deptName.contains(query);
//       }).toList();
//     });
//   }
//
//   Future<void> _generateAndSaveCSV(Map<String, dynamic> reportData) async {
//     // Create CSV data from the reportData
//     String csvData = 'Department Name, Zone Name, UPC, Description, Total Qty\n'; // Header
//     final reportList = reportData['data']['reportData'] as List<dynamic>;
//
//     for (var zone in reportList) {
//       for (var device in zone['devices']) {
//         for (var product in device['products']) {
//           csvData +=
//           '${product['departmentName']}, ${zone['zoneName']}, ${product['upc']}, ${product['description']}, ${product['totalQty']}\n';
//         }
//       }
//     }
//
//     // Save the CSV file to local device
//     await _saveFileToLocal(csvData);
//   }
//   Future<void> _saveFileToLocal(String csvData) async {
//     try {
//       // Get the external storage directory
//       final directory = await  getApplicationDocumentsDirectory();
//       if (directory != null) {
//         final downloadsDir = directory.path + '/Download';
//
//         // Create the Download folder if it doesn't exist
//         final downloadsDirFolder = Directory(downloadsDir);
//         if (!await downloadsDirFolder.exists()) {
//           await downloadsDirFolder.create(recursive: true);
//         }
//
//         // Define the file name with the current timestamp
//         final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.csv';
//         final filePath = '$downloadsDir/$fileName';
//
//         // Create the file and write the CSV data
//         final file = File(filePath);
//         await file.writeAsString(csvData);
//
//         // Show a success message
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text('CSV file saved to $filePath'),
//           backgroundColor: Colors.green,
//         ));
//         print('CSV saved at: $filePath');
//       } else {
//         print('Failed to get external storage directory');
//       }
//     } catch (e) {
//       print('Error saving CSV: $e');
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('Failed to save CSV file'),
//         backgroundColor: Colors.red,
//       ));
//     }
//   }
//
//
//   void _onDownloadPressed() async {
//     try {
//       String token = storage.read('token') ?? '';
//       final report = await fetchReportData(_selectedReportType, token, context);
//       await _generateAndSaveCSV(report);
//
//       // Get the file path
//       final directory = await getApplicationDocumentsDirectory();
//       if (directory != null) {
//         final downloadsDir = directory.path + '/Download';
//         final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.csv';
//         final filePath = '$downloadsDir/$fileName';
//
//         // Share the file
//         //await Share.shareXFiles([XFile(filePath)], text: 'Report CSV file');
//       } else {
//         print('Failed to get external storage directory');
//       }
//     } catch (e) {
//       print('Error downloading report: $e');
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('Error downloading report: $e'),
//         backgroundColor: Colors.red,
//       ));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Reports', style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Select Report Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             SizedBox(height: 8),
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.blueAccent),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: DropdownButton<String>(
//                 isExpanded: true,
//                 value: _selectedReportType,
//                 items: <String>['daily', 'weekly', 'monthly'].map((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _selectedReportType = newValue!;
//                     _updateReportData(); // Fetch new data based on the selected report type
//                   });
//                 },
//               ),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 labelText: 'Search Department Name',
//                 prefixIcon: Icon(Icons.search),
//               ),
//             ),
//             SizedBox(height: 16),
//             Expanded(
//               child: FutureBuilder<Map<String, dynamic>>(
//                 future: _reportData,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return Center(child: CircularProgressIndicator());
//                   } else if (snapshot.hasError) {
//                     return Center(child: Text('No Report found'));
//                   } else if (!snapshot.hasData || snapshot.data?['status'] != 'success') {
//                     return Center(child: Text('No data available or error occurred.'));
//                   } else {
//                     final reportData = snapshot.data!['data'];
//                     if (reportData == null || reportData['reportData'] == null) {
//                       return Center(child: Text('No report data available for selected type.'));
//                     }
//
//                     final reportList = reportData['reportData'] as List<dynamic>;
//                     final cards = <Widget>[];
//
//                     for (var zone in reportList) {
//                       for (var device in zone['devices']) {
//                         for (var product in device['products']) {
//                           cards.add(
//                             Card(
//                               elevation: 4,
//                               margin: EdgeInsets.symmetric(vertical: 4),
//                               color: Colors.blue[300],
//                               child: ListTile(
//                                 title: Container(
//                                   padding: EdgeInsets.all(8.0),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         'Department Name: ${product['departmentName']}',
//                                         style: TextStyle(
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.black,
//                                         ),
//                                       ),
//                                       SizedBox(height: 8),
//                                       Text(
//                                         'Zone Name: ${zone['zoneName']}',
//                                         style: TextStyle(color: Colors.black),
//                                       ),
//                                       SizedBox(height: 8),
//                                       Text(
//                                         'UPC: ${product['upc']}',
//                                         style: TextStyle(color: Colors.black),
//                                       ),
//                                       SizedBox(height: 8),
//                                       Text(
//                                         'Description: ${product['description']}',
//                                         style: TextStyle(color: Colors.black),
//                                       ),
//                                       SizedBox(height: 8),
//                                       Text(
//                                         'Total Qty: ${product['totalQty']}',
//                                         style: TextStyle(color: Colors.black),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           );
//                         }
//                       }
//                     }
//
//                     return ListView(
//                       children: cards,
//                     );
//                   }
//                 },
//               ),
//             ),
//             ElevatedButton(
//               onPressed: _onDownloadPressed,
//               child: Text('Download Report as CSV'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose(); // Dispose the controller
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart' as xml;
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:url_launcher/url_launcher.dart';
Future<Map<String, dynamic>?> fetchReportData(String reportType, String token, BuildContext context) async {
  final url = 'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType';

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      Navigator.pushReplacementNamed(context, '/login');
      return null; // Navigate to login if token is blacklisted
    } else {
      final errorData = json.decode(response.body);
      throw Exception('Failed to load report data: ${errorData['message']}');
    }
  } catch (error) {
    print('Error fetching data: $error');
    return null;
  }
}

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late Future<Map<String, dynamic>?> _reportData;
  final storage = GetStorage();
  String _selectedReportType = 'daily';
  final _searchController = TextEditingController();
  List<dynamic> _filteredReportList = [];
  String? _downloadPath;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterReports);
    _downloadPath = storage.read('downloadPath'); // Read cached download path
    _updateReportData();
  }

  Future<void> _updateReportData() async {
    String token = storage.read('token') ?? '';

    setState(() {
      _reportData = fetchReportData(_selectedReportType, token, context);
    });
  }

  void _filterReports() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredReportList = _filteredReportList.where((report) {
        final deptName = (report['departmentName'] as String).toLowerCase();
        return deptName.contains(query);
      }).toList();
    });
  }

  Future<void> _generateAndSaveCSV(Map<String, dynamic> reportData) async {
    String csvData = 'Department Name, Zone Name, UPC, Description, Total Qty\n'; // CSV Header

    final reportList = reportData['data']['reportData'] as List<dynamic>;

    for (var zone in reportList) {
      for (var device in zone['devices']) {
        for (var product in device['products']) {
          csvData +=
          '${product['departmentName'] ?? ''}, '
              '${zone['zoneName'] ?? ''}, '
              '${product['upc'] ?? ''}, '
              '${product['description'] ?? ''}, '
              '${product['totalQty']?.toString() ?? '0'}\n';
        }
      }
    }

    await _saveFile(csvData, 'csv');
  }

  Future<void> _generateAndSaveXML(Map<String, dynamic> reportData) async {
    final builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('Report', nest: () {
      final reportList = reportData['data']['reportData'] as List<dynamic>;

      for (var zone in reportList) {
        builder.element('Zone', nest: () {
          builder.element('zoneName', nest: zone['zoneName'] ?? 'Unknown Zone');
          for (var device in zone['devices'] ?? []) {
            builder.element('Device', nest: () {
              for (var product in device['products'] ?? []) {
                builder.element('Product', nest: () {
                  builder.element('departmentName', nest: product['departmentName'] ?? 'Unknown Department');
                  builder.element('upc', nest: product['upc'] ?? 'Unknown UPC');
                  builder.element('description', nest: product['description'] ?? 'No Description');
                  builder.element('totalQty', nest: product['totalQty']?.toString() ?? '0');
                });
              }
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
      final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.$extension';
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
        content: Text('Cant use this folder . Instead of this ! Choose Document Folder'),
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
                  String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                  if (selectedDirectory != null) {
                    setState(() {
                      _downloadPath = selectedDirectory;
                      storage.write('downloadPath', selectedDirectory); // Cache the new path
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Download path changed to $selectedDirectory'),
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
        title: Text('Reports', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Report Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedReportType,
                items: <String>['daily', 'weekly', 'monthly'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedReportType = newValue!;
                    _updateReportData();
                  });
                },
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Department Name',
                prefixIcon: Icon(Icons.search),
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
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return Center(child: Text('No reports found'));
                  } else {
                    final reportData = snapshot.data!['data'];
                    if (reportData == null) {
                      return Center(child: Text('No report data available'));
                    }

                    final reportList = reportData['reportData'];
                    if (reportList == null) {
                      return Center(child: Text('No report data available'));
                    }

                    _filteredReportList = reportList; // Initialize the filtered list

                    return ListView.builder(
                      itemCount: _filteredReportList.length,
                      itemBuilder: (context, index) {
                        final zone = _filteredReportList[index];
                        final devices = zone['devices'];

                        return Column(
                          children: [
                            Text(
                              'Zone Name: ${zone['zoneName']}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: devices.length,
                              itemBuilder: (context, deviceIndex) {
                                final device = devices[deviceIndex];
                                final products = device['products'];

                                return Column(
                                  children: [
                                    Text(
                                      'Device Products:',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 4),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: products.length,
                                      itemBuilder: (context, productIndex) {
                                        final product = products[productIndex];

                                        return Card(
                                          elevation: 4,
                                          margin: EdgeInsets.symmetric(vertical: 4),
                                          color: Colors.blue[300],
                                          child: ListTile(
                                            title: Container(
                                              padding: EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Department Name: ${product['departmentName']}',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'UPC: ${product['upc']}',
                                                    style: TextStyle(color: Colors.black),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Description: ${product['description']}',
                                                    style: TextStyle(color: Colors.black),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Total Qty: ${product['totalQty']}',
                                                    style: TextStyle(color: Colors.black),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
              ),
            )
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

