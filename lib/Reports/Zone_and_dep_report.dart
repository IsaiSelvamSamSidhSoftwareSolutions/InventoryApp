// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import 'package:get_storage/get_storage.dart';
// // import 'package:xml/xml.dart' as xml;
// // import 'dart:io';
// // import 'package:file_picker/file_picker.dart';
// // import 'package:permission_handler/permission_handler.dart';
// // Future<Map<String, dynamic>> fetchReportData(String reportType, String token, {String? userId}) async {
// //   final url = 'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType${userId != null ? '&userId=$userId' : ''}';
// //   final response = await http.get(
// //     Uri.parse(url),
// //     headers: {
// //       'Content-Type': 'application/json',
// //       'Authorization': 'Bearer $token',
// //     },
// //   );
// //
// //   if (response.statusCode == 200) {
// //     return json.decode(response.body);
// //   } else if (response.statusCode == 401) {
// //     throw Exception('Unauthorized'); // Handle unauthorized access
// //   } else {
// //     throw Exception('Failed to load report data');
// //   }
// // }
// //
// // class DetailedZoneReportPage extends StatefulWidget {
// //   @override
// //   _ReportPageState createState() => _ReportPageState();
// // }
// //
// // class _ReportPageState extends State<DetailedZoneReportPage> {
// //   late Future<Map<String, dynamic>> _reportData;
// //   final storage = GetStorage();
// //   String _selectedReportType = 'daily'; // Default report type
// //   List<dynamic> _reportList = [];
// //   String? _userId; // User ID for admin role
// //   String? _userRole; // User role
// //   String? _downloadPath;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _userRole = storage.read('UserRole'); // Get user role from GetStorage
// //     _fetchReportData(); // Fetch data initially
// //     _downloadPath = storage.read('downloadPath');
// //   }
// //
// //   Future<void> _fetchReportData() async {
// //     try {
// //       String token = storage.read('token') ?? '';
// //       if (_userRole == 'admin' && _userId != null) {
// //         _reportData = fetchReportData(_selectedReportType, token, userId: _userId);
// //       } else {
// //         _reportData = fetchReportData(_selectedReportType, token);
// //       }
// //
// //       _reportData.then((data) {
// //         setState(() {
// //           _reportList = data['data']['reportData'] ?? []; // Set report list
// //         });
// //       }).catchError((error) {
// //         if (error.toString() == 'Unauthorized') {
// //           // Redirect to login page on 401
// //           Navigator.of(context).pushReplacementNamed('/login');
// //         } else {
// //           print('Error fetching report data: $error');
// //         }
// //       });
// //     } catch (e) {
// //       print('Error fetching report data: $e');
// //     }
// //   }
// //   void _onReportTypeChanged(String? newValue) {
// //     if (newValue != null) {
// //       setState(() {
// //         _selectedReportType = newValue;
// //       });
// //       if (_userRole == 'admin') {
// //         _showUserIdDialog(newValue);
// //       } else {
// //         _fetchReportData(); // Fetch new data based on report type selection
// //       }
// //     }
// //   }
// //   void _showUserIdDialog(String reportType) {
// //     final userIdController = TextEditingController();
// //     showDialog(
// //       context: context,
// //       builder: (context) {
// //         return AlertDialog(
// //           title: Text('Enter User ID'),
// //           content: TextField(
// //             controller: userIdController,
// //             decoration: InputDecoration(
// //               labelText: 'User ID',
// //               border: OutlineInputBorder(),
// //             ),
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () {
// //                 Navigator.of(context).pop();
// //                 setState(() {
// //                   _userId = userIdController.text;
// //                   _fetchReportData();
// //                 });
// //               },
// //               child: Text('Submit'),
// //             ),
// //             TextButton(
// //               onPressed: () {
// //                 Navigator.of(context).pop();
// //               },
// //               child: Text('Cancel'),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //
// //   Future<void> _generateAndSaveCSV(Map<String, dynamic> reportData) async {
// //     String csvData = 'Zone#,Department Name,Total Qty,Total Retail\n'; // CSV Header
// //
// //     final reportList = reportData['data']['reportData'] as List<dynamic>;
// //
// //     for (var zone in reportList) {
// //       for (var device in zone['devices']) {
// //         for (var product in device['products']) {
// //           csvData +=
// //           '${zone['zoneName'] ?? ''}, '
// //               '${product['departmentName'] ?? ''}, '
// //               '${product['totalQty']?.toString() ?? '0'},'
// //               '${(product['totalRetail'] as num?)?.toStringAsFixed(2) ?? '0.00'}\n';
// //         }
// //       }
// //     }
// //
// //     await _saveFile(csvData, 'csv');
// //   }
// //
// //   Future<void> _generateAndSaveXML(Map<String, dynamic> reportData) async {
// //     final builder = xml.XmlBuilder();
// //     builder.processing('xml', 'version="1.0"');
// //     builder.element('Report', nest: () {
// //       final reportList = reportData['data']['reportData'] as List<dynamic>;
// //
// //       for (var zone in reportList) {
// //         builder.element('Zone', nest: () {
// //           builder.element('zoneName', nest: zone['zoneName'] ?? 'Unknown Zone');
// //           for (var device in zone['devices'] ?? []) {
// //             builder.element('Device', nest: () {
// //               for (var product in device['products'] ?? []) {
// //                 builder.element('Product', nest: () {
// //                   builder.element('departmentName', nest: product['departmentName'] ?? 'Unknown Department');
// //                   builder.element('totalQty', nest: product['totalQty']?.toString() ?? '0');
// //                   builder.element('totalRetail', nest: (product['totalRetail'] as num?)?.toStringAsFixed(2) ?? '0.00');
// //                 });
// //               }
// //             });
// //           }
// //         });
// //       }
// //     });
// //
// //     final xmlData = builder.buildDocument().toString();
// //     await _saveFile(xmlData, 'xml');
// //   }
// //   Future<void> _saveFile(String data, String extension) async {
// //     String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
// //     if (selectedDirectory == null) {
// //       print('No directory selected. File not saved.');
// //       return;
// //     }
// //
// //     try {
// //       final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.$extension';
// //       final filePath = '$selectedDirectory/$fileName';
// //       final file = File(filePath);
// //       await file.writeAsString(data);
// //
// //       // Store the selected path in GetStorage
// //       storage.write('downloadPath', selectedDirectory);
// //
// //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //         content: Text('$extension file saved to $filePath'),
// //         backgroundColor: Colors.green,
// //       ));
// //     } catch (e) {
// //       print('Error saving file: $e'); // Log error to console
// //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //         content: Text('Cant use this folder . Instead of this ! Choose Document Folder'),
// //         backgroundColor: Colors.red,
// //       ));
// //     }
// //   }
// //   void _showDownloadOptions() {
// //     showModalBottomSheet(
// //       context: context,
// //       builder: (BuildContext context) {
// //         return Container(
// //           height: 250,
// //           child: Column(
// //             children: [
// //               ListTile(
// //                 leading: Icon(Icons.file_download),
// //                 title: Text('Download as CSV'),
// //                 onTap: () async {
// //                   Navigator.pop(context);
// //                   final report = await _reportData;
// //                   if (report != null) await _generateAndSaveCSV(report);
// //                 },
// //               ),
// //               ListTile(
// //                 leading: Icon(Icons.file_download),
// //                 title: Text('Download as XML'),
// //                 onTap: () async {
// //                   Navigator.pop(context);
// //                   final report = await _reportData;
// //                   if (report != null) await _generateAndSaveXML(report);
// //                 },
// //               ),
// //               ListTile(
// //                 leading: Icon(Icons.folder),
// //                 title: Text('Change Download Location'),
// //                 onTap: () async {
// //                   Navigator.pop(context);
// //                   String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
// //                   if (selectedDirectory != null) {
// //                     setState(() {
// //                       _downloadPath = selectedDirectory;
// //                       storage.write('downloadPath', selectedDirectory); // Cache the new path
// //                     });
// //                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// //                       content: Text('Download path changed to $selectedDirectory'),
// //                     ));
// //                   }
// //                 },
// //               ),
// //
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// //   /////////////////////////////////////////////////////////
// //
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Detailed Zone General Report'),
// //         backgroundColor: Colors.blueAccent,
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // Label for report type selection
// //             Text(
// //               'Select Report Type',
// //               style: TextStyle(fontSize: 16, color: Colors.black),
// //             ),
// //             // Dropdown to select report type
// //             Container(
// //               decoration: BoxDecoration(
// //                 border: Border.all(color: Colors.blueAccent),
// //                 borderRadius: BorderRadius.circular(8.0),
// //               ),
// //               padding: EdgeInsets.symmetric(horizontal: 12.0),
// //               child: DropdownButton<String>(
// //                 value: _selectedReportType,
// //                 isExpanded: true,
// //                 hint: Text('Select Report Type', style: TextStyle(color: Colors.grey)),
// //                 items: <String>['daily', 'weekly', 'monthly']
// //                     .map<DropdownMenuItem<String>>((String value) {
// //                   return DropdownMenuItem<String>(
// //                     value: value,
// //                     child: Text(value.capitalizeFirstOfEach()),
// //                   );
// //                 }).toList(),
// //                 onChanged: _onReportTypeChanged,
// //                 style: TextStyle(fontSize: 16, color: Colors.black),
// //                 dropdownColor: Colors.white,
// //                 underline: Container(
// //                   height: 2,
// //                   color: Colors.blueAccent,
// //                 ),
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
// //                     return Center(child: Text('No report found'));
// //                   } else if (!snapshot.hasData || snapshot.data?['data']['reportData'].isEmpty) {
// //                     return Center(child: Text('No data available for selected report type.'));
// //                   } else {
// //                     final reportData = snapshot.data!['data'] ?? [];
// //                     List<dynamic> reportList = (reportData['reportData'] as List<dynamic>?) ?? [];
// //
// //                     return SingleChildScrollView(
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: reportList.map<Widget>((zone) {
// //                           final zoneName = zone['zoneName'] ?? 'N/A';
// //                           final devices = zone['devices'] as List<dynamic>? ?? [];
// //
// //                           return Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Text('Zone#: $zoneName', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// //                               ...devices.map<Widget>((device) {
// //                                 final products = device['products'] as List<dynamic>? ?? [];
// //                                 return Column(
// //                                   crossAxisAlignment: CrossAxisAlignment.start,
// //                                   children: products.map<Widget>((product) {
// //                                     final departmentName = product['departmentName'] ?? 'N/A';
// //                                     final totalQty = product['totalQty']?.toString() ?? '0';
// //                                     final totalRetail = (product['totalRetail'] as num?)?.toStringAsFixed(2) ?? '0.00';
// //
// //                                     Color cardColor = products.indexOf(product) % 2 == 0 ? Colors.blueAccent[100]! : Colors.lightBlueAccent[200]!;
// //
// //                                     return Container(
// //                                       width: double.infinity,
// //                                       margin: EdgeInsets.symmetric(vertical: 8.0),
// //                                       child: Card(
// //                                         color: cardColor,
// //                                         shape: RoundedRectangleBorder(
// //                                           borderRadius: BorderRadius.circular(16.0),
// //                                         ),
// //                                         child: Padding(
// //                                           padding: const EdgeInsets.all(16.0),
// //                                           child: Column(
// //                                             mainAxisSize: MainAxisSize.max,
// //                                             crossAxisAlignment: CrossAxisAlignment.start,
// //                                             children: [
// //                                               Text(
// //                                                 'Department: $departmentName',
// //                                                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
// //                                               ),
// //                                               SizedBox(height: 8.0),
// //                                               Text(
// //                                                 'Total Quantity: $totalQty',
// //                                                 style: TextStyle(fontSize: 14),
// //                                               ),
// //                                               SizedBox(height: 4.0),
// //                                               Text(
// //                                                 'Total Retail: \$${totalRetail}',
// //                                                 style: TextStyle(fontSize: 14),
// //                                               ),
// //                                             ],
// //                                           ),
// //                                         ),
// //                                       ),
// //                                     );
// //                                   }).toList(),
// //                                 );
// //                               }).toList(),
// //                               SizedBox(height: 16),
// //                             ],
// //                           );
// //                         }).toList(),
// //                       ),
// //                     );
// //                   }
// //                 },
// //               ),
// //             ),
// //           ],
// //         ),
// //
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //         onPressed: _showDownloadOptions,
// //         child: Icon(Icons.download),
// //       ),
// //
// //     );
// //   }
// // }
// //
// // // Extension to capitalize the first letter of each word
// // extension StringCasingExtension on String {
// //   String capitalizeFirstOfEach() {
// //     return this.split(' ').map((str) => str[0].toUpperCase() + str.substring(1)).join(' ');
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:get_storage/get_storage.dart';
// import 'package:intl/intl.dart';
//
// Future<Map<String, dynamic>> fetchReportData(String startDateTime, String endDateTime, String token) async {
//   final url =
//       'https://iscandata.com/api/v1/reports/generate-report?startDate=$startDateTime&endDate=$endDateTime&reportType=custom';
//   final response = await http.get(
//     Uri.parse(url),
//     headers: {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token',
//     },
//   );
//
//   if (response.statusCode == 200) {
//     return json.decode(response.body);
//   } else if (response.statusCode == 401) {
//     throw Exception('Unauthorized'); // Trigger 401 handling
//   } else {
//     throw Exception('Failed to load report data');
//   }
// }
//
// class DetailedZoneReportPage extends StatefulWidget {
//   @override
//   _ReportPageState createState() => _ReportPageState();
// }
//
// class _ReportPageState extends State<DetailedZoneReportPage> {
//   late Future<Map<String, dynamic>> _reportData;
//   final storage = GetStorage();
//   DateTimeRange? _selectedDateRange;
//   TimeOfDay? _selectedStartTime;
//   TimeOfDay? _selectedEndTime;
//   final _startDateController = TextEditingController();
//   final _endDateController = TextEditingController();
//   final _startTimeController = TextEditingController();
//   final _endTimeController = TextEditingController();
//   final _searchController = TextEditingController();
//
//   List<dynamic> _filteredReportList = [];
//   List<dynamic> _reportList = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _startDateController.text = '2024-09-01'; // default start date
//     _endDateController.text = '2024-09-17'; // default end date
//     _startTimeController.text = '00:00'; // default start time
//     _endTimeController.text = '23:59'; // default end time
//     _searchController.addListener(_filterSearchResults);
//     _fetchReportData();
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _fetchReportData() async {
//     try {
//       String token = storage.read('token') ?? '';
//       _reportData = fetchReportData(
//         '${_startDateController.text}T${_startTimeController.text}:00',
//         '${_endDateController.text}T${_endTimeController.text}:00',
//         token,
//       );
//
//       _reportData.then((data) {
//         setState(() {
//           _reportList = data['data']['reportData'] ?? [];
//           _filteredReportList = _reportList; // Initialize with all data
//         });
//       }).catchError((error) {
//         if (error.toString() == 'Unauthorized') {
//           // Redirect to login page on 401
//           Navigator.of(context).pushReplacementNamed('/login');
//         } else {
//           print('Error fetching report data: $error');
//         }
//       });
//     } catch (e) {
//       print('Error fetching report data: $e');
//     }
//   }
//
//   Future<void> _selectDateTimeRange(BuildContext context) async {
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//       initialDateRange: _selectedDateRange,
//     );
//
//     if (picked != null && picked != _selectedDateRange) {
//       setState(() {
//         _selectedDateRange = picked;
//         _startDateController.text = DateFormat('yyyy-MM-dd').format(picked.start);
//         _endDateController.text = DateFormat('yyyy-MM-dd').format(picked.end);
//         _selectedStartTime = TimeOfDay(hour: 0, minute: 0);
//         _selectedEndTime = TimeOfDay(hour: 23, minute: 59);
//         _startTimeController.text = '00:00';
//         _endTimeController.text = '23:59';
//       });
//       _fetchReportData(); // Fetch data after date range selection
//     }
//   }
//
//   Future<void> _selectStartTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedStartTime ?? TimeOfDay(hour: 0, minute: 0),
//     );
//
//     if (picked != null && picked != _selectedStartTime) {
//       setState(() {
//         _selectedStartTime = picked;
//         _startTimeController.text = _selectedStartTime!.format(context);
//       });
//       _fetchReportData(); // Fetch data after start time selection
//     }
//   }
//
//   Future<void> _selectEndTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedEndTime ?? TimeOfDay(hour: 23, minute: 59),
//     );
//
//     if (picked != null && picked != _selectedEndTime) {
//       setState(() {
//         _selectedEndTime = picked;
//         _endTimeController.text = _selectedEndTime!.format(context);
//       });
//       _fetchReportData(); // Fetch data after end time selection
//     }
//   }
//
//   void _filterSearchResults() {
//     final query = _searchController.text.toLowerCase();
//
//     setState(() {
//       _filteredReportList = _reportList.where((zone) {
//         final zoneName = zone['zoneName']?.toString().toLowerCase() ?? '';
//         return zoneName.contains(query);
//       }).toList();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Detailed Zone General Report'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildDatePicker(context, 'Start Date', _startDateController, _selectDateTimeRange),
//             SizedBox(height: 8),
//             _buildDatePicker(context, 'End Date', _endDateController, _selectDateTimeRange),
//             SizedBox(height: 8),
//             _buildTimePicker(context, 'Start Time', _startTimeController, _selectStartTime),
//             SizedBox(height: 8),
//             _buildTimePicker(context, 'End Time', _endTimeController, _selectEndTime),
//             SizedBox(height: 16),
//             Text(
//               'REPORT GENERATED ON: ${DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now())}'
//                   '\nSelected Range: From ${_startDateController.text} ${_startTimeController.text} - To ${_endDateController.text} ${_endTimeController.text}',
//               style: TextStyle(fontSize: 16, color: Colors.blueAccent),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 labelText: 'Search by Zone Name',
//                 border: OutlineInputBorder(),
//                 suffixIcon: Icon(Icons.search),
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
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   } else if (!snapshot.hasData || snapshot.data?['data']['reportData'].isEmpty) {
//                     return Center(child: Text('No data available for selected date.'));
//                   } else {
//                     final reportData = snapshot.data!['data'] ?? [];
//                     List<dynamic> reportList = (reportData['reportData'] as List<dynamic>?) ?? [];
//
//                     return SingleChildScrollView(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: reportList.map<Widget>((zone) {
//                           final zoneName = zone['zoneName'] ?? 'N/A';
//                           final devices = zone['devices'] as List<dynamic>? ?? [];
//
//                           return Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text('Zone#: $zoneName', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                               ...devices.map<Widget>((device) {
//                                 final products = device['products'] as List<dynamic>? ?? [];
//                                 return Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: products.map<Widget>((product) {
//                                     final departmentName = product['departmentName'] ?? 'N/A';
//                                     final totalQty = product['totalQty']?.toString() ?? '0';
//                                     final totalRetail = (product['totalRetail'] as num?)?.toStringAsFixed(2) ?? '0.00';
//
//                                     return Card(
//                                       margin: EdgeInsets.symmetric(vertical: 8.0),
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(8.0),
//                                         child: Column(
//                                           crossAxisAlignment: CrossAxisAlignment.start,
//                                           children: [
//                                             Text('Department: $departmentName', style: TextStyle(fontWeight: FontWeight.bold)),
//                                             Text('Total Quantity: $totalQty'),
//                                             Text('Total Retail: \$${totalRetail}'),
//                                           ],
//                                         ),
//                                       ),
//                                     );
//                                   }).toList(),
//                                 );
//                               }).toList(),
//                               SizedBox(height: 16),
//                             ],
//                           );
//                         }).toList(),
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
//
//   Widget _buildDatePicker(BuildContext context, String label, TextEditingController controller, Function onTap) {
//     return GestureDetector(
//       onTap: () => onTap(context),
//       child: AbsorbPointer(
//         child: TextField(
//           controller: controller,
//           decoration: InputDecoration(
//             labelText: label,
//             border: OutlineInputBorder(),
//             suffixIcon: Icon(Icons.calendar_today),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTimePicker(BuildContext context, String label, TextEditingController controller, Function onTap) {
//     return GestureDetector(
//       onTap: () => onTap(context),
//       child: AbsorbPointer(
//         child: TextField(
//           controller: controller,
//           decoration: InputDecoration(
//             labelText: label,
//             border: OutlineInputBorder(),
//             suffixIcon: Icon(Icons.access_time),
//           ),
//         ),
//       ),
//     );
//   }
//  }
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
class DetailedZoneReportPage extends StatefulWidget {
  @override
  _DetailedZoneReportPageState createState() => _DetailedZoneReportPageState();
}

class _DetailedZoneReportPageState extends State<DetailedZoneReportPage> {
  final storage = GetStorage();
  String _selectedReportType = 'custom';
  String? _userId;
  String token = '';
  bool _isLoading = false;
  Future<Map<String, dynamic>>? _reportData;
  String? _downloadPath;
  DateTime _startDate = DateTime.now().subtract(Duration(days: 10));
  DateTime _endDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 23, minute: 59);

  @override
  void initState() {
    super.initState();
    token = storage.read('token') ?? '';
  }

  Future<void> _promptUserId() async {
    final userId = await showDialog<String>(
      context: context,
      builder: (context) {
        final userIdController = TextEditingController();
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
              onPressed: () => Navigator.pop(context, null),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, userIdController.text.trim()),
              child: Text('Submit'),
            ),
          ],
        );
      },
    );

    if (userId != null && userId.isNotEmpty) {
      setState(() {
        _userId = userId;
      });
      if (_selectedReportType == 'custom') {
        await _selectDateRange(context);
      }
      _fetchReport();
    }
  }
  Future<void> _generateAndSavePDF(List<dynamic> reportList, Map<String, dynamic> overallTotals) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              // Title
              pw.Text(
                'Zones General Report',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 10),

              // Generate Table for Each Zone
              ...reportList.map((zone) {
                final zoneName = zone['zoneName'] ?? 'N/A';
                final devices = zone['devices'] as List<dynamic>? ?? [];

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Zone#: $zoneName',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                      ),
                    ),
                    pw.SizedBox(height: 5),

                    // Table for Devices and Products
                    pw.Table.fromTextArray(
                      headers: [ 'Department', 'Qty', 'Retail'],
                      data: devices.expand((device) {

                        final products = device['products'] as List<dynamic>? ?? [];
                        return products.map((product) {
                          return [

                            product['departmentName'] ?? 'N/A',
                            product['totalQty']?.toString() ?? '0',
                            '\$${(product['totalRetail'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                          ];
                        });
                      }).toList(),
                      headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                      headerDecoration: pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      cellStyle: pw.TextStyle(fontSize: 10),
                      cellAlignment: pw.Alignment.centerLeft,
                    ),
                    pw.SizedBox(height: 15),
                  ],
                );
              }),

              // Overall Totals Section
              pw.Divider(),
              pw.Text(
                'Overall Totals',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              pw.Text('Total Qty: ${overallTotals['totalQty'] ?? '0'}'),
              pw.Text('Total Retail: \$${overallTotals['totalRetail']?.toStringAsFixed(2) ?? '0.00'}'),
            ];
          },
        ),
      );

  // Save PDF to a file
      if (_downloadPath == null) {
        _downloadPath = await FilePicker.platform.getDirectoryPath();
        if (_downloadPath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No directory selected. PDF not saved.')),
          );
          return;
        }
      }

      final fileName = 'Zone_gen_report${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '$_downloadPath/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to $filePath')),
      );

      // Send the PDF via email if required
      await _sendEmailWithPDF(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PDF. Please try again.')),
      );
    }
  }

  Future<void> _sendEmailWithPDF(String filepath) async {
    try {
      final token = storage.read('token') as String?;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication token not available')),
        );
        return;
      }

      final file = File(filepath);
      if (!file.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File does not exist at the specified path.')),
        );
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://iscandata.com/api/v1/sessions/send-report'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(
        'report',
        filepath,
        contentType: MediaType('application', 'pdf'),
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email sent successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to send email: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while sending the email.')),
      );
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });

      // Allow the user to select a time range after selecting the date range
      await _selectTimeRange(context);
    }
  }

  Future<void> _selectTimeRange(BuildContext context) async {
    TimeOfDay? pickedStartTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (pickedStartTime != null) {
      setState(() {
        _startTime = pickedStartTime;
      });
    }

    TimeOfDay? pickedEndTime = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (pickedEndTime != null) {
      setState(() {
        _endTime = pickedEndTime;
      });
    }
  }

  Future<Map<String, dynamic>> fetchReportData(
      String reportType, String userId) async {
    String url;

    if (reportType == 'custom') {
      String startDateTime = _formatDateTime(_startDate, _startTime);
      String endDateTime = _formatDateTime(_endDate, _endTime);
      url =
      'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType&userId=$userId&startDate=$startDateTime&endDate=$endDateTime';
    } else {
      url =
      'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType&userId=$userId';
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Failed to load report data: ${errorData['message']}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Error fetching data: $e');
    }
  }

  void _fetchReport() {
    if (_userId == null || _userId!.isEmpty) {
      _promptUserId();
      return;
    }

    setState(() {
      _isLoading = true;
      _reportData = fetchReportData(_selectedReportType, _userId!).whenComplete(() {
        setState(() {
          _isLoading = false;
        });
      });
    });
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zones General Report'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedReportType,
              items: <String>['custom', 'daily', 'weekly', 'monthly'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) async {
                setState(() {
                  _selectedReportType = newValue!;
                });
                await _promptUserId(); // Prompt User ID on dropdown change
              },
            ),
            if (_selectedReportType == 'custom') ...[
              SizedBox(height: 8),
              Text('Selected Start: ${_formatDateTime(_startDate, _startTime)}'),
              Text('Selected End: ${_formatDateTime(_endDate, _endTime)}'),
            ],
            SizedBox(height: 16),
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _reportData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return Center(child: Text('Please select Type of report and give desired User Id'));
                    } else {
                      final reportData = snapshot.data!['data'];
                      if (reportData == null) {
                        return Center(child: Text('No report data available'));
                      }

                      final reportList = reportData['reportData'];
                      if (reportList.isEmpty) {
                        return Center(
                          child: Text(
                            'No Data Found for Selected Report Type',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        );
                      }

                      return  ListView.builder(
                        itemCount: reportList.length + 1, // Add 1 for the "Overall Totals" card
                        itemBuilder: (context, index) {
                          if (index == reportList.length) {
                            // "Overall Totals" card at the end
                            final overallTotals = reportData['overallTotals'] ?? {};
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  child: Text(
                                    'Overall Totals',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Card(
                                  color: Colors.blueGrey.shade100, // Distinct color for "Overall Totals"
                                  margin: EdgeInsets.symmetric(vertical: 8.0),
                                  elevation: 4,
                                  child: ListTile(
                                    title: Text(
                                      'Total Qty: ${overallTotals['totalQty']?.toString() ?? 'N/A'}',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      'Total Retail: \$${overallTotals['totalRetail']?.toString() ?? '0.00'}',
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          // Alternating colors for zone cards
                          final cardColor = index % 2 == 0 ? Colors.blue : Colors.blueAccent;

                          final zone = reportList[index];
                          final zoneName = zone['zoneName'] ?? 'N/A';
                          final devices = zone['devices'] as List<dynamic>? ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'Zone#: $zoneName',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black, // Ensure readability on blue backgrounds
                                  ),
                                ),
                              ),
                              Card(
                                color: cardColor, // Alternating colors
                                margin: EdgeInsets.symmetric(vertical: 8),
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Zone#: $zoneName',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      ...devices.map<Widget>((device) {
                                        final products = device['products'] as List<dynamic>? ?? [];
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: products.map<Widget>((product) {
                                            final departmentName =
                                                product['departmentName'] ?? 'N/A';
                                            final totalQty = product['totalQty']?.toString() ?? '0';
                                            final totalRetail = (product['totalRetail'] as num?)
                                                ?.toStringAsFixed(2) ??
                                                '0.00';

                                            return SizedBox(
                                              width: double.infinity,
                                              child: Card(
                                                color: Colors.white, // Inner card with white background
                                                margin: EdgeInsets.symmetric(vertical: 8.0),
                                                elevation: 4,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Department: $departmentName',
                                                        style: TextStyle(fontWeight: FontWeight.bold),
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text('Total Quantity: $totalQty'),
                                                      SizedBox(height: 4),
                                                      Text('Total Retail: \$${totalRetail}'),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final snapshot = await _reportData;
          if (snapshot?['status'] == 'success') {
            final reportList = snapshot?['data']['reportData'] ?? [];
            final overallTotals = snapshot?['data']['overallTotals'] ?? {};
            await _generateAndSavePDF(reportList, overallTotals);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to generate PDF.')),
            );
          }
        },
        label: Text('Download & Email'),
        icon: Icon(Icons.download),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
