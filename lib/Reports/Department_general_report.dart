// //
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import 'package:get_storage/get_storage.dart';
// //
// // Future<Map<String, dynamic>?> fetchReportData(String reportType, String token) async {
// //   final url = 'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType';
// //   final response = await http.get(
// //     Uri.parse(url),
// //     headers: {
// //       'Content-Type': 'application/json',
// //       'Authorization': 'Bearer $token',
// //     },
// //   );
// //
// //   print('Response Status: ${response.statusCode}');
// //   print('Response Body: ${response.body}');
// //
// //   if (response.statusCode == 200) {
// //     return json.decode(response.body);
// //   } else {
// //     print('Failed to load report data');
// //     return null;
// //   }
// // }
// //
// // class DepartmentGeneralReportPage extends StatefulWidget {
// //   @override
// //   _DepartmentGeneralReportPageState createState() => _DepartmentGeneralReportPageState();
// // }
// //
// // class _DepartmentGeneralReportPageState extends State<DepartmentGeneralReportPage> {
// //   late Future<Map<String, dynamic>?> _reportData;
// //   final storage = GetStorage();
// //   String? _selectedReportType; // Updated to allow null for the default option
// //   final _searchController = TextEditingController();
// //   String _searchQuery = '';
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     String token = storage.read('token') ?? '';
// //     _reportData = fetchReportData('daily', token); // Default to daily report
// //     _selectedReportType = null; // Default dropdown value
// //   }
// //
// //   void _updateReportData() {
// //     String token = storage.read('token') ?? '';
// //     if (_selectedReportType != null) {
// //       _reportData = fetchReportData(_selectedReportType!, token);
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Department General', style: TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.blueAccent,
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // DropdownButton for report types
// //             InputDecorator(
// //               decoration: InputDecoration(
// //                 labelText: 'Select Report',
// //                 border: OutlineInputBorder(),
// //               ),
// //               child: DropdownButton<String>(
// //                 value: _selectedReportType,
// //                 isExpanded: true, // Expand to fill available width
// //                 hint: Text('Select Report'), // Default hint
// //                 items: <String>['daily', 'weekly', 'monthly'].map((String value) {
// //                   return DropdownMenuItem<String>(
// //                     value: value,
// //                     child: Text(value.capitalizeFirstLetter()),
// //                   );
// //                 }).toList(),
// //                 onChanged: (String? newValue) {
// //                   setState(() {
// //                     _selectedReportType = newValue;
// //                     _updateReportData();
// //                   });
// //                 },
// //               ),
// //             ),
// //             SizedBox(height: 16),
// //             TextField(
// //               controller: _searchController,
// //               decoration: InputDecoration(
// //                 labelText: 'Search',
// //                 prefixIcon: Icon(Icons.search),
// //               ),
// //               onChanged: (value) {
// //                 setState(() {
// //                   _searchQuery = value.toLowerCase();
// //                 });
// //               },
// //             ),
// //             SizedBox(height: 16),
// //             Expanded(
// //               child: FutureBuilder<Map<String, dynamic>?>(
// //                 future: _reportData,
// //                 builder: (context, snapshot) {
// //                   if (snapshot.connectionState == ConnectionState.waiting) {
// //                     return Center(child: CircularProgressIndicator());
// //                   } else if (snapshot.hasError) {
// //                     print('Error: ${snapshot.error}');
// //                     return Center(child: Text('Error: ${snapshot.error}'));
// //                   } else if (!snapshot.hasData || snapshot.data?['status'] != 'success') {
// //                     return Center(child: Text('No data available for selected report type.'));
// //                   } else {
// //                     final reportData = snapshot.data!['data'];
// //                     final reportList = reportData['reportData'] as List<dynamic>? ?? [];
// //                     final overallTotals = reportData['overallTotals'] ?? {};
// //
// //                     // Filter report data based on the search query
// //                     final filteredReportList = reportList.expand((zone) {
// //                       final devices = zone['devices'] as List<dynamic>? ?? [];
// //                       return devices.expand((device) {
// //                         final products = device['products'] as List<dynamic>? ?? [];
// //                         return products.where((product) {
// //                           final description = product['description']?.toLowerCase() ?? '';
// //                           final upc = product['upc']?.toLowerCase() ?? '';
// //                           return description.contains(_searchQuery) || upc.contains(_searchQuery);
// //                         }).toList();
// //                       }).toList();
// //                     }).toList();
// //
// //                     // If no data is available
// //                     if (filteredReportList.isEmpty) {
// //                       return Center(child: Text('No records found for the selected report.'));
// //                     }
// //
// //                     return SingleChildScrollView(
// //                       scrollDirection: Axis.vertical,
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Padding(
// //                             padding: const EdgeInsets.symmetric(vertical: 8.0),
// //                             child: Text(
// //                               'REPORT GENERATED ON: ${DateTime.now().toLocal()}',
// //                               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
// //                             ),
// //                           ),
// //                           ...filteredReportList.asMap().entries.map((entry) {
// //                             int index = entry.key;
// //                             var product = entry.value;
// //                             return Card(
// //                               color: index % 2 == 0 ? Colors.blueAccent[50] : Colors.blueAccent[200],
// //                               margin: EdgeInsets.symmetric(vertical: 8.0),
// //                               child: ListTile(
// //                                 title: Text('UPC#: ${product['upc'] ?? 'N/A'}'),
// //                                 subtitle: Column(
// //                                   crossAxisAlignment: CrossAxisAlignment.start,
// //                                   children: [
// //                                     Text('Department Name: ${product['departmentName'] ?? 'N/A'}'),
// //                                     Text('Description: ${product['description'] ?? 'N/A'}'),
// //                                     Text('Qty: ${product['totalQty']?.toString() ?? 'N/A'}'),
// //                                     Text('Total Retail: ${product['totalRetail']?.toString() ?? 'N/A'}'),
// //                                   ],
// //                                 ),
// //                               ),
// //                             );
// //                           }).toList(),
// //                           Padding(
// //                             padding: const EdgeInsets.symmetric(vertical: 8.0),
// //                             child: Text(
// //                               'Overall Totals',
// //                               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //                             ),
// //                           ),
// //                           Card(
// //                             margin: EdgeInsets.symmetric(vertical: 8.0),
// //                             child: ListTile(
// //                               title: Text('Total Qty: ${overallTotals['totalQty']?.toString() ?? 'N/A'}'),
// //                               subtitle: Text('Total Retail: ${overallTotals['totalRetail']?.toString() ?? 'N/A'}'),
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     );
// //                   }
// //                 },
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // extension StringCasingExtension on String {
// //   String capitalizeFirstLetter() {
// //     if (this.isEmpty) {
// //       return this;
// //     }
// //     return '${this[0].toUpperCase()}${this.substring(1)}';
// //   }
// // }
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
// class DepartmentGeneralReportPage extends StatefulWidget {
//   @override
//   _DepartmentGeneralReportPageState createState() => _DepartmentGeneralReportPageState();
// }
//
// class _DepartmentGeneralReportPageState extends State<DepartmentGeneralReportPage> {
//   late Future<Map<String, dynamic>?> _reportData;
//   final storage = GetStorage();
//   String? _selectedReportType; // Updated to allow null for the default option
//   final _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _userId; // User ID for admin role
//   String? _userRole; // User role
//
//
//   @override
//   void initState() {
//     super.initState();
//     _userRole = storage.read('UserRole'); // Get user role from GetStorage
//     String token = storage.read('token') ?? '';
//     _reportData = fetchReportData('daily', token); // Default to daily report
//     _selectedReportType = null; // Default dropdown value
//   }
//
//   void _updateReportData() {
//     String token = storage.read('token') ?? '';
//     if (_selectedReportType != null) {
//       if (_userRole == 'admin' && _userId != null) {
//         _reportData = fetchReportData(_selectedReportType!, token, userId: _userId);
//       } else {
//         _reportData = fetchReportData(_selectedReportType!, token);
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
//         title: Text('Department General', style: TextStyle(color: Colors.white)),
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
//                 isExpanded: true, // Expand to fill available width
//                 hint: Text('Select Report'), // Default hint
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
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 labelText: 'Search',
//                 prefixIcon: Icon(Icons.search),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _searchQuery = value.toLowerCase();
//                 });
//               },
//             ),
//             SizedBox(height: 16),
//             Expanded(
//               child: FutureBuilder<Map<String, dynamic>?>(
//                 future: _reportData,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return Center(child: CircularProgressIndicator());
//                   } else if (snapshot.hasError) {
//                     print('Error: ${snapshot.error}');
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   } else if (!snapshot.hasData || snapshot.data?['status'] != 'success') {
//                     return Center(child: Text('No data available for selected report type.'));
//                   } else {
//                     final reportData = snapshot.data!['data'];
//                     final reportList = reportData['reportData'] as List<dynamic>? ?? [];
//                     final overallTotals = reportData['overallTotals'] ?? {};
//
//                     // Filter report data based on the search query
//                     final filteredReportList = reportList.expand((zone) {
//                       final devices = zone['devices'] as List<dynamic>? ?? [];
//                       return devices.expand((device) {
//                         final products = device['products'] as List<dynamic>? ?? [];
//                         return products.where((product) {
//                           final description = product['description']?.toLowerCase() ?? '';
//                           final upc = product['upc']?.toLowerCase() ?? '';
//                           return description.contains(_searchQuery) || upc.contains(_searchQuery);
//                         }).toList();
//                       }).toList();
//                     }).toList();
//
//                     // If no data is available
//                     if (filteredReportList.isEmpty) {
//                       return Center(child: Text('No records found for the selected report.'));
//                     }
//
//                     return SingleChildScrollView(
//                       scrollDirection: Axis.vertical,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 8.0),
//                             child: Text(
//                               'REPORT GENERATED ON: ${DateTime.now().toLocal()}',
//                               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                           ...filteredReportList.asMap().entries.map((entry) {
//                             int index = entry.key;
//                             var product = entry.value;
//                             return Card(
//                               color: index % 2 == 0 ? Colors.blue[100] : Colors.blueAccent[100],
//                               margin: EdgeInsets.symmetric(vertical: 8.0),
//                               child: ListTile(
//                                 title: Text('UPC#: ${product['upc'] ?? 'N/A'}'),
//                                 subtitle: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text('Department Name: ${product['departmentName'] ?? 'N/A'}' , style: TextStyle(color:Colors.black , fontSize: 16),),
//                                     Text('Description: ${product['description'] ?? 'N/A'}'),
//                                     Text('Qty: ${product['totalQty']?.toString() ?? 'N/A'}'),
//                                     Text('Total Retail: ${product['totalRetail']?.toString() ?? 'N/A'}'),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                           Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 8.0),
//                             child: Text(
//                               'Overall Totals',
//                               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                           Card(
//                             margin: EdgeInsets.symmetric(vertical: 8.0),
//                             child: ListTile(
//                               title: Text('Total Qty: ${overallTotals['totalQty']?.toString() ?? 'N/A'}'),
//                               subtitle: Text('Total Retail: ${overallTotals['totalRetail']?.toString() ?? 'N/A'}'),
//                             ),
//                           ),
//                         ],
//                       ),
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
//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:get_storage/get_storage.dart';
//
// Future<Map<String, dynamic>?> fetchReportData(String reportType, String token) async {
//   final url = 'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType';
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
// class DepartmentGeneralReportPage extends StatefulWidget {
//   @override
//   _DepartmentGeneralReportPageState createState() => _DepartmentGeneralReportPageState();
// }
//
// class _DepartmentGeneralReportPageState extends State<DepartmentGeneralReportPage> {
//   late Future<Map<String, dynamic>?> _reportData;
//   final storage = GetStorage();
//   String? _selectedReportType; // Updated to allow null for the default option
//   final _searchController = TextEditingController();
//   String _searchQuery = '';
//
//   @override
//   void initState() {
//     super.initState();
//     String token = storage.read('token') ?? '';
//     _reportData = fetchReportData('daily', token); // Default to daily report
//     _selectedReportType = null; // Default dropdown value
//   }
//
//   void _updateReportData() {
//     String token = storage.read('token') ?? '';
//     if (_selectedReportType != null) {
//       _reportData = fetchReportData(_selectedReportType!, token);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Department General', style: TextStyle(color: Colors.white)),
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
//                 isExpanded: true, // Expand to fill available width
//                 hint: Text('Select Report'), // Default hint
//                 items: <String>['daily', 'weekly', 'monthly'].map((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value.capitalizeFirstLetter()),
//                   );
//                 }).toList(),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _selectedReportType = newValue;
//                     _updateReportData();
//                   });
//                 },
//               ),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 labelText: 'Search',
//                 prefixIcon: Icon(Icons.search),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _searchQuery = value.toLowerCase();
//                 });
//               },
//             ),
//             SizedBox(height: 16),
//             Expanded(
//               child: FutureBuilder<Map<String, dynamic>?>(
//                 future: _reportData,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return Center(child: CircularProgressIndicator());
//                   } else if (snapshot.hasError) {
//                     print('Error: ${snapshot.error}');
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   } else if (!snapshot.hasData || snapshot.data?['status'] != 'success') {
//                     return Center(child: Text('No data available for selected report type.'));
//                   } else {
//                     final reportData = snapshot.data!['data'];
//                     final reportList = reportData['reportData'] as List<dynamic>? ?? [];
//                     final overallTotals = reportData['overallTotals'] ?? {};
//
//                     // Filter report data based on the search query
//                     final filteredReportList = reportList.expand((zone) {
//                       final devices = zone['devices'] as List<dynamic>? ?? [];
//                       return devices.expand((device) {
//                         final products = device['products'] as List<dynamic>? ?? [];
//                         return products.where((product) {
//                           final description = product['description']?.toLowerCase() ?? '';
//                           final upc = product['upc']?.toLowerCase() ?? '';
//                           return description.contains(_searchQuery) || upc.contains(_searchQuery);
//                         }).toList();
//                       }).toList();
//                     }).toList();
//
//                     // If no data is available
//                     if (filteredReportList.isEmpty) {
//                       return Center(child: Text('No records found for the selected report.'));
//                     }
//
//                     return SingleChildScrollView(
//                       scrollDirection: Axis.vertical,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 8.0),
//                             child: Text(
//                               'REPORT GENERATED ON: ${DateTime.now().toLocal()}',
//                               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                           ...filteredReportList.asMap().entries.map((entry) {
//                             int index = entry.key;
//                             var product = entry.value;
//                             return Card(
//                               color: index % 2 == 0 ? Colors.blueAccent[50] : Colors.blueAccent[200],
//                               margin: EdgeInsets.symmetric(vertical: 8.0),
//                               child: ListTile(
//                                 title: Text('UPC#: ${product['upc'] ?? 'N/A'}'),
//                                 subtitle: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text('Department Name: ${product['departmentName'] ?? 'N/A'}'),
//                                     Text('Description: ${product['description'] ?? 'N/A'}'),
//                                     Text('Qty: ${product['totalQty']?.toString() ?? 'N/A'}'),
//                                     Text('Total Retail: ${product['totalRetail']?.toString() ?? 'N/A'}'),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                           Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 8.0),
//                             child: Text(
//                               'Overall Totals',
//                               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                           Card(
//                             margin: EdgeInsets.symmetric(vertical: 8.0),
//                             child: ListTile(
//                               title: Text('Total Qty: ${overallTotals['totalQty']?.toString() ?? 'N/A'}'),
//                               subtitle: Text('Total Retail: ${overallTotals['totalRetail']?.toString() ?? 'N/A'}'),
//                             ),
//                           ),
//                         ],
//                       ),
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
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart' as xml ;

Future<Map<String, dynamic>?> fetchReportData(String reportType, String token, {String? userId}) async {
  final url = 'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType${userId != null ? '&userId=$userId' : ''}';
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

class DepartmentGeneralReportPage extends StatefulWidget {
  @override
  _DepartmentGeneralReportPageState createState() => _DepartmentGeneralReportPageState();
}

class _DepartmentGeneralReportPageState extends State<DepartmentGeneralReportPage> {
  late Future<Map<String, dynamic>?> _reportData;
  final storage = GetStorage();
  String? _selectedReportType; // Updated to allow null for the default option
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _userId; // User ID for admin role
  String? _userRole; // User role
  String? _downloadPath;

  @override
  void initState() {
    super.initState();
    _userRole = storage.read('UserRole'); // Get user role from GetStorage
    String token = storage.read('token') ?? '';
    _reportData = fetchReportData('daily', token); // Default to daily report
    _selectedReportType = null; // Default dropdown value
    _downloadPath = storage.read('downloadPath');
  }

  void _updateReportData() {
    String token = storage.read('token') ?? '';
    if (_selectedReportType != null) {
      if (_userRole == 'admin' && _userId != null) {
        _reportData = fetchReportData(_selectedReportType!, token, userId: _userId);
      } else {
        _reportData = fetchReportData(_selectedReportType!, token);
      }
    }
  }

  void _showUserIdDialog(String reportType) {
    final userIdController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter User ID'),
          content: TextField(
            controller: userIdController,
            decoration: InputDecoration(
              labelText: 'User ID',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _userId = userIdController.text;
                  _updateReportData();
                });
              },
              child: Text('Submit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  ///////////////////////////////////FILE DOWNLOAD ////////////////////////////
  Future<void> _generateAndSaveCSV(Map<String, dynamic> reportData) async {
    String csvData = 'Department Name, Zone Name, UPC, Description, Total Qty , totalRetail\n'; // CSV Header

    final reportList = reportData['data']['reportData'] as List<dynamic>;

    for (var zone in reportList) {
      for (var device in zone['devices']) {
        for (var product in device['products']) {
          csvData +=
          '${product['departmentName'] ?? ''}, '
              '${zone['zoneName'] ?? ''}, '
              '${product['upc'] ?? ''}, '
              '${product['description'] ?? ''}, '
              '${product['totalQty']?.toString() ?? '0'},'
          '${product['totalRetail']?.toString() ?? '0'}\n';
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
                  builder.element('totalRetail', nest: product['totalRetail']?.toString() ?? '0');
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
  /////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Department General', style: TextStyle(color: Colors.white)),
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
                isExpanded: true, // Expand to fill available width
                hint: Text('Select Report'), // Default hint
                items: <String>['daily', 'weekly', 'monthly'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.capitalizeFirstLetter()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedReportType = newValue;
                    if (_userRole == 'admin') {
                      _showUserIdDialog(newValue!);
                    } else {
                      _updateReportData();
                    }
                  });
                },
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
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
                  } else if (!snapshot.hasData || snapshot.data?['status'] != 'success') {
                    return Center(child: Text('No data available for selected report type.'));
                  } else {
                    final reportData = snapshot.data!['data'];
                    final reportList = reportData['reportData'] as List<dynamic>? ?? [];
                    final overallTotals = reportData['overallTotals'] ?? {};

                    // Filter report data based on the search query
                    final filteredReportList = reportList.expand((zone) {
                      final devices = zone['devices'] as List<dynamic>? ?? [];
                      return devices.expand((device) {
                        final products = device['products'] as List<dynamic>? ?? [];
                        return products.where((product) {
                          final description = product['description']?.toLowerCase() ?? '';
                          final upc = product['upc']?.toLowerCase() ?? '';
                          return description.contains(_searchQuery) || upc.contains(_searchQuery);
                        }).toList();
                      }).toList();
                    }).toList();

                    // If no data is available
                    if (filteredReportList.isEmpty) {
                      return Center(child: Text('No records found for the selected report.'));
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'REPORT GENERATED ON: ${DateTime.now().toLocal()}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...filteredReportList.asMap().entries.map((entry) {
                            int index = entry.key;
                            var product = entry.value;
                            return Card(
                              color: index % 2 == 0 ? Colors.blue[100] : Colors.blueAccent[100],
                              margin: EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                title: Text('UPC#: ${product['upc'] ?? 'N/A'}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Department Name: ${product['departmentName'] ?? 'N/A'}' , style: TextStyle(color:Colors.black , fontSize: 16),),
                                    Text('Description: ${product['description'] ?? 'N/A'}'),
                                    Text('Qty: ${product['totalQty']?.toString() ?? 'N/A'}'),
                                    Text('Total Retail: ${product['totalRetail']?.toString() ?? 'N/A'}'),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Overall Totals',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Card(
                            margin: EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              title: Text('Total Qty: ${overallTotals['totalQty']?.toString() ?? 'N/A'}'),
                              subtitle: Text('Total Retail: ${overallTotals['totalRetail']?.toString() ?? 'N/A'}'),
                            ),
                          ),
                        ],
                      ),
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