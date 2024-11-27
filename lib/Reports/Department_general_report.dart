//
//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:get_storage/get_storage.dart';
//
// Future<Map<String, dynamic>> fetchReportData(
//     String startDateTime, String endDateTime, String token, String reportType, String? userId) async {
//   final String url =
//       'https://iscandata.com/api/v1/reports/generate-report?startDate=$startDateTime&endDate=$endDateTime&reportType=$reportType${userId != null ? '&userId=$userId' : ''}';
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
//     if (response.statusCode == 200) {
//       return json.decode(response.body);
//     } else {
//       print('Error fetching report: ${response.body}');
//       throw Exception('Failed to load report data: ${response.body}');
//     }
//   } catch (error) {
//     print('API Error: $error');
//     rethrow;
//   }
// }
//
// class DepartmentGeneralReportPage extends StatefulWidget {
//   @override
//   _NofReportPageState createState() => _NofReportPageState();
// }
//
// class _NofReportPageState extends State<DepartmentGeneralReportPage> {
//   late Future<Map<String, dynamic>> _reportData;
//   final storage = GetStorage();
//   String _selectedReportType = 'custom';
//   String? _userId;
//   String token = '';
//   String _searchQuery = '';
//   bool _isLoading = false;
//   String? userRole;
//   DateTime _startDate = DateTime.now().subtract(Duration(days: 10));
//   DateTime _endDate = DateTime.now();
//   TimeOfDay _startTime = TimeOfDay(hour: 0, minute: 0);
//   TimeOfDay _endTime = TimeOfDay(hour: 23, minute: 59);
//   final _searchController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     token = storage.read('token') ?? '';
//     userRole = storage.read('userRole') ?? '';
//     if (userRole == 'admin') {
//       _promptUserId();
//     } else {
//       _fetchReport();
//     }
//   }
//
//   Future<void> _selectDateRange(BuildContext context) async {
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//       initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
//     );
//
//     if (picked != null) {
//       setState(() {
//         _startDate = picked.start;
//         _endDate = picked.end;
//       });
//
//       // Allow the user to select a time range after selecting the date range
//       await _selectTimeRange(context);
//     }
//   }
//
//   Future<void> _selectTimeRange(BuildContext context) async {
//     TimeOfDay? pickedStartTime = await showTimePicker(
//       context: context,
//       initialTime: _startTime,
//     );
//
//     if (pickedStartTime != null) {
//       setState(() {
//         _startTime = pickedStartTime;
//       });
//     }
//
//     TimeOfDay? pickedEndTime = await showTimePicker(
//       context: context,
//       initialTime: _endTime,
//     );
//
//     if (pickedEndTime != null) {
//       setState(() {
//         _endTime = pickedEndTime;
//       });
//     }
//
//     // Prompt for User ID if the user is an admin
//     _promptUserId();
//   }
//
//   void _fetchReport() {
//     if (userRole == 'admin' && (_userId == null || _userId!.isEmpty)) {
//       print('Admin must provide a userId before fetching reports.');
//       return;
//     }
//
//     String startDateTime = '${_formatDateTime(_startDate, _startTime)}';
//     String endDateTime = '${_formatDateTime(_endDate, _endTime)}';
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     _reportData = fetchReportData(
//         startDateTime, endDateTime, token, _selectedReportType, _userId)
//         .catchError((error) {
//       setState(() {
//         _isLoading = false;
//       });
//       print('Error fetching report: $error');
//     }).whenComplete(() {
//       setState(() {
//         _isLoading = false;
//       });
//     });
//   }
//
//   Future<void> _promptUserId() async {
//     if (_userId == null || _userId!.isEmpty) {
//       String? userId = await showDialog<String>(
//         context: context,
//         builder: (BuildContext context) {
//           TextEditingController userIdController = TextEditingController();
//           return AlertDialog(
//             title: Text('Enter User ID'),
//             content: TextField(
//               controller: userIdController,
//               decoration: InputDecoration(labelText: 'User ID'),
//             ),
//             actions: [
//               TextButton(
//                 child: Text('Cancel'),
//                 onPressed: () => Navigator.pop(context, null),
//               ),
//               TextButton(
//                 child: Text('Submit'),
//                 onPressed: () => Navigator.pop(context, userIdController.text),
//               ),
//             ],
//           );
//         },
//       );
//
//       if (userId != null && userId.isNotEmpty) {
//         setState(() {
//           _userId = userId;
//         });
//         _fetchReport();
//       }
//     }
//   }
//
//   String _formatDateTime(DateTime date, TimeOfDay time) {
//     return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day
//         .toString().padLeft(2, '0')}T${time.hour.toString().padLeft(
//         2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Department General Report Page'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             DropdownButton<String>(
//               isExpanded: true,
//               value: _selectedReportType,
//               items: <String>['custom', 'daily', 'weekly', 'monthly']
//                   .map((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value),
//                 );
//               }).toList(),
//               onChanged: (String? newValue) async {
//                 if (newValue == null) return;
//
//                 // Prompt User ID for all report types
//                 String? userId = await showDialog<String>(
//                   context: context,
//                   builder: (BuildContext context) {
//                     TextEditingController userIdController =
//                     TextEditingController();
//                     return AlertDialog(
//                       title: Text('Enter User ID'),
//                       content: TextField(
//                         controller: userIdController,
//                         decoration: InputDecoration(labelText: 'User ID'),
//                       ),
//                       actions: [
//                         TextButton(
//                           child: Text('Cancel'),
//                           onPressed: () => Navigator.pop(context, null),
//                         ),
//                         TextButton(
//                           child: Text('Submit'),
//                           onPressed: () =>
//                               Navigator.pop(context, userIdController.text),
//                         ),
//                       ],
//                     );
//                   },
//                 );
//
//                 if (userId == null || userId.isEmpty) {
//                   // If User ID is not provided, revert dropdown selection
//                   setState(() {
//                     _selectedReportType =
//                         _selectedReportType; // Keep the current selection
//                   });
//                   return;
//                 }
//
//                 setState(() {
//                   _userId = userId; // Save the User ID
//                   _selectedReportType =
//                       newValue; // Update the selected report type
//                   _isLoading = true; // Set loading to true
//                 });
//
//                 if (newValue == 'custom') {
//                   // For custom report, allow Date and Time selection
//                   await _selectDateRange(context);
//                 } else {
//                   // For other report types, fetch the report immediately
//                   _fetchReport();
//                 }
//               },
//             ),
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
//             if (_selectedReportType == 'custom') ...[
//               SizedBox(height: 8),
//               Text(
//                   'Selected Start: ${_formatDateTime(_startDate, _startTime)}'),
//               Text('Selected End: ${_formatDateTime(_endDate, _endTime)}'),
//             ],
//             SizedBox(height: 16),
//             Expanded(
//               child: FutureBuilder<Map<String, dynamic>>(
//                 future: _reportData,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     // Show loading indicator while waiting for data
//                     return Center(child: CircularProgressIndicator());
//                   } else if (snapshot.hasError) {
//                     return Center(
//                       child: Container(
//                         padding: const EdgeInsets.all(16.0),
//                         decoration: BoxDecoration(
//                           color: Colors.greenAccent.withOpacity(0.1), // Subtle background color
//                           borderRadius: BorderRadius.circular(8.0),
//                           border: Border.all(color: Colors.greenAccent, width: 2),
//                         ),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             SizedBox(height: 16.0),
//                             Text(
//                               'Note: Please Select a Report Type with User ID',
//                               style: TextStyle(
//                                 fontSize: 18, // Professional font size
//                                 color: Colors.blueAccent, // Harmonious font color
//                                 fontWeight: FontWeight.w600, // Semi-bold for emphasis
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   }
//                   else if (!snapshot.hasData ||
//                       snapshot.data?['status'] != 'success') {
//                     return Center(
//                       child: Text(
//                         'No data available.',
//                         style: TextStyle(fontSize: 16),
//                         textAlign: TextAlign.center,
//                       ),
//                     );
//                   } else {
//                     final reportData = snapshot.data!['data'];
//                     final reportList =
//                         reportData['reportData'] as List<dynamic>? ?? [];
//                     final overallTotals = reportData['overallTotals'] ?? {};
//
//                     // Filter report data based on the search query
//                     final filteredReportList = reportList.expand((zone) {
//                       final devices =
//                           zone['devices'] as List<dynamic>? ?? [];
//                       return devices.expand((device) {
//                         final products =
//                             device['products'] as List<dynamic>? ?? [];
//                         return products.where((product) {
//                           final description =
//                               product['description']?.toLowerCase() ?? '';
//                           final upc = product['upc']?.toLowerCase() ?? '';
//                           return description.contains(_searchQuery) ||
//                               upc.contains(_searchQuery);
//                         }).toList();
//                       }).toList();
//                     }).toList();
//
//                     // If no data is available
//                     if (filteredReportList.isEmpty) {
//                       return Center(
//                         child: Text(
//                           'No records found for the selected report.',
//                           style: TextStyle(fontSize: 16),
//                         ),
//                       );
//                     }
//
//                     return SingleChildScrollView(
//                       scrollDirection: Axis.vertical,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Padding(
//                             padding:
//                             const EdgeInsets.symmetric(vertical: 8.0),
//                             child: Text(
//                               'REPORT GENERATED ON: ${DateTime.now()
//                                   .toLocal()}',
//                               style: TextStyle(
//                                   fontSize: 16, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                           ...filteredReportList
//                               .asMap()
//                               .entries
//                               .map((entry) {
//                             int index = entry.key;
//                             var product = entry.value;
//                             return Card(
//                               color: index % 2 == 0
//                                   ? Colors.blueAccent[50]
//                                   : Colors.blueAccent[200],
//                               margin: EdgeInsets.symmetric(vertical: 8.0),
//                               child: ListTile(
//                                 title: Text(
//                                     'UPC#: ${product['upc'] ?? 'N/A'}'),
//                                 subtitle: Column(
//                                   crossAxisAlignment:
//                                   CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                         'Department Name: ${product['departmentName'] ??
//                                             'N/A'}'),
//                                     Text(
//                                         'Description: ${product['description'] ??
//                                             'N/A'}'),
//                                     Text(
//                                         'Qty: ${product['totalQty']
//                                             ?.toString() ?? 'N/A'}'),
//                                     Text(
//                                         'Total Retail: ${product['totalRetail']
//                                             ?.toString() ?? 'N/A'}'),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                           Padding(
//                             padding:
//                             const EdgeInsets.symmetric(vertical: 8.0),
//                             child: Text(
//                               'Overall Totals',
//                               style: TextStyle(
//                                   fontSize: 18, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                           Card(
//                             margin: EdgeInsets.symmetric(vertical: 8.0),
//                             child: ListTile(
//                               title: Text(
//                                   'Total Qty: ${overallTotals['totalQty']
//                                       ?.toString() ?? 'N/A'}'),
//                               subtitle: Text(
//                                   'Total Retail: ${overallTotals['totalRetail']
//                                       ?.toString() ?? 'N/A'}'),
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

class DepartmentGeneralReportPage extends StatefulWidget {
  @override
  _NofReportPageState createState() => _NofReportPageState();
}

class _NofReportPageState extends State<DepartmentGeneralReportPage> {
  late Future<Map<String, dynamic>> _reportData;
  final storage = GetStorage();
  String _selectedReportType = 'custom';
  String? _userId;
  String token = '';
  String _searchQuery = '';
  bool _isLoading = false;
  String? userRole;
  DateTime _startDate = DateTime.now().subtract(Duration(days: 10));
  DateTime _endDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 23, minute: 59);
  final _searchController = TextEditingController();
  String? _downloadPath;

  @override
  void initState() {
    super.initState();
    token = storage.read('token') ?? '';
    userRole = storage.read('userRole') ?? '';
    _downloadPath = storage.read('downloadPath');
    if (userRole == 'admin') {
      _promptUserId();
    } else {
      _fetchReport();
    }
  }

  Future<Map<String, dynamic>> fetchReportData(String startDateTime,
      String endDateTime, String token, String reportType,
      String? userId) async {
    final String url =
        'https://iscandata.com/api/v1/reports/generate-report?startDate=$startDateTime&endDate=$endDateTime&reportType=$reportType${userId !=
        null ? '&userId=$userId' : ''}';

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
      } else {
        print('Error fetching report: ${response.body}');
        throw Exception('Failed to load report data: ${response.body}');
      }
    } catch (error) {
      print('API Error: $error');
      rethrow;
    }
  }

  void _fetchReport() {
    if (userRole == 'admin' && (_userId == null || _userId!.isEmpty)) {
      print('Admin must provide a userId before fetching reports.');
      return;
    }

    String startDateTime = _formatDateTime(_startDate, _startTime);
    String endDateTime = _formatDateTime(_endDate, _endTime);

    setState(() {
      _isLoading = true;
    });

    _reportData = fetchReportData(
      startDateTime, endDateTime, token, _selectedReportType, _userId,
    ).catchError((error) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching report: $error');
    }).whenComplete(() {
      setState(() {
        _isLoading = false;
      });
    });
  }
  Future<void> _generateAndSavePDF(List<dynamic> reportList, Map<String, dynamic> overallTotals) async {
    try {
      final pdf = pw.Document();

      // Flatten the nested structure similar to how the UI processes it
      final flattenedProducts = reportList.expand((zone) {
        final devices = zone['devices'] as List<dynamic>? ?? [];
        return devices.expand((device) {
          final products = device['products'] as List<dynamic>? ?? [];
          return products;
        });
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Text(
                'Department General Report',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                context: context,
                data: [
                  ['UPC', 'Department Name', 'Description', 'Qty', 'Total Retail'],
                  ...flattenedProducts.map((product) => [
                    product['upc'] ?? 'N/A',
                    product['departmentName'] ?? 'N/A',
                    product['description'] ?? 'N/A',
                    product['totalQty']?.toString() ?? 'N/A',
                    product['totalRetail']?.toString() ?? 'N/A',
                  ]),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Overall Totals',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Total Qty: ${overallTotals['totalQty'] ?? 'N/A'}'),
              pw.Text('Total Retail: ${overallTotals['totalRetail'] ?? 'N/A'}'),
            ];
          },
        ),
      );

      // Handle file saving and email sending as in your current implementation
      if (_downloadPath == null) {
        _downloadPath = await FilePicker.platform.getDirectoryPath();
        if (_downloadPath != null) {
          storage.write('downloadPath', _downloadPath);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No directory selected. PDF not saved.')),
          );
          return;
        }
      }

      final fileName = 'department_general_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '$_downloadPath/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to $filePath')),
      );

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


  Future<void> _promptUserId() async {
    if (_userId == null || _userId!.isEmpty) {
      String? userId = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          TextEditingController userIdController = TextEditingController();
          return AlertDialog(
            title: Text('Enter User ID'),
            content: TextField(
              controller: userIdController,
              decoration: InputDecoration(labelText: 'User ID'),
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context, null),
              ),
              TextButton(
                child: Text('Submit'),
                onPressed: () => Navigator.pop(context, userIdController.text),
              ),
            ],
          );
        },
      );

      if (userId != null && userId.isNotEmpty) {
        setState(() {
          _userId = userId;
        });
        _fetchReport();
      }
    }
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day
        .toString().padLeft(2, '0')}T${time.hour.toString().padLeft(
        2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
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

    _promptUserId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Department General Report Page'),
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
              items: <String>['custom', 'daily', 'weekly', 'monthly']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) async {
                if (newValue == null) return;

                // Prompt User ID for all report types
                String? userId = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    TextEditingController userIdController =
                    TextEditingController();
                    return AlertDialog(
                      title: Text('Enter User ID'),
                      content: TextField(
                        controller: userIdController,
                        decoration: InputDecoration(labelText: 'User ID'),
                      ),
                      actions: [
                        TextButton(
                          child: Text('Cancel'),
                          onPressed: () => Navigator.pop(context, null),
                        ),
                        TextButton(
                          child: Text('Submit'),
                          onPressed: () =>
                              Navigator.pop(context, userIdController.text),
                        ),
                      ],
                    );
                  },
                );

                if (userId == null || userId.isEmpty) {
                  // If User ID is not provided, revert dropdown selection
                  setState(() {
                    _selectedReportType =
                        _selectedReportType; // Keep the current selection
                  });
                  return;
                }

                setState(() {
                  _userId = userId; // Save the User ID
                  _selectedReportType =
                      newValue; // Update the selected report type
                  _isLoading = true; // Set loading to true
                });

                if (newValue == 'custom') {
                  // For custom report, allow Date and Time selection
                  await _selectDateRange(context);
                } else {
                  // For other report types, fetch the report immediately
                  _fetchReport();
                }
              },
            ),
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
            if (_selectedReportType == 'custom') ...[
              SizedBox(height: 8),
              Text(
                  'Selected Start: ${_formatDateTime(_startDate, _startTime)}'),
              Text('Selected End: ${_formatDateTime(_endDate, _endTime)}'),
            ],
            SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _reportData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Show loading indicator while waiting for data
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.1), // Subtle background color
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.greenAccent, width: 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: 16.0),
                            Text(
                              'Note: Please Select a Report Type with User ID',
                              style: TextStyle(
                                fontSize: 18, // Professional font size
                                color: Colors.blueAccent, // Harmonious font color
                                fontWeight: FontWeight.w600, // Semi-bold for emphasis
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  else if (!snapshot.hasData ||
                      snapshot.data?['status'] != 'success') {
                    return Center(
                      child: Text(
                        'No data available.',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else {
                    final reportData = snapshot.data!['data'];
                    final reportList =
                        reportData['reportData'] as List<dynamic>? ?? [];
                    final overallTotals = reportData['overallTotals'] ?? {};

                    // Filter report data based on the search query
                    final filteredReportList = reportList.expand((zone) {
                      final devices =
                          zone['devices'] as List<dynamic>? ?? [];
                      return devices.expand((device) {
                        final products =
                            device['products'] as List<dynamic>? ?? [];
                        return products.where((product) {
                          final description =
                              product['description']?.toLowerCase() ?? '';
                          final upc = product['upc']?.toLowerCase() ?? '';
                          return description.contains(_searchQuery) ||
                              upc.contains(_searchQuery);
                        }).toList();
                      }).toList();
                    }).toList();

                    // If no data is available
                    if (filteredReportList.isEmpty) {
                      return Center(
                        child: Text(
                          'No records found for the selected report.',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'REPORT GENERATED ON: ${DateTime.now()
                                  .toLocal()}',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...filteredReportList
                              .asMap()
                              .entries
                              .map((entry) {
                            int index = entry.key;
                            var product = entry.value;
                            return Card(
                              color: index % 2 == 0
                                  ? Colors.blueAccent[50]
                                  : Colors.blueAccent[200],
                              margin: EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                title: Text(
                                    'UPC#: ${product['upc'] ?? 'N/A'}'),
                                subtitle: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Department Name: ${product['departmentName'] ??
                                            'N/A'}'),
                                    Text(
                                        'Description: ${product['description'] ??
                                            'N/A'}'),
                                    Text(
                                        'Qty: ${product['totalQty']
                                            ?.toString() ?? 'N/A'}'),
                                    Text(
                                        'Total Retail: ${product['totalRetail']
                                            ?.toString() ?? 'N/A'}'),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Overall Totals',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Card(
                            margin: EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              title: Text(
                                  'Total Qty: ${overallTotals['totalQty']
                                      ?.toString() ?? 'N/A'}'),
                              subtitle: Text(
                                  'Total Retail: ${overallTotals['totalRetail']
                                      ?.toString() ?? 'N/A'}'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final snapshot = await _reportData;
          if (snapshot['status'] == 'success') {
            final reportList = snapshot['data']['reportData'] ?? [];
            final overallTotals = snapshot['data']['overallTotals'] ?? {};
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