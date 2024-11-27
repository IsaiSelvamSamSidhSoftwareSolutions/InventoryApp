// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:get_storage/get_storage.dart';
//
// class ReportPage extends StatefulWidget {
//   @override
//   _ReportPageState createState() => _ReportPageState();
// }
//
// class _ReportPageState extends State<ReportPage> {
//   final storage = GetStorage();
//   String _selectedReportType = 'daily';
//   String? _userId;
//   bool _isLoading = false;
//   Future<Map<String, dynamic>?>? _reportData;
//
//   DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
//   DateTime _endDate = DateTime.now();
//   TimeOfDay _startTime = TimeOfDay(hour: 0, minute: 0);
//   TimeOfDay _endTime = TimeOfDay(hour: 23, minute: 59);
//
//   @override
//   void initState() {
//     super.initState();
//     _promptUserId(); // Prompt for User ID on app start
//   }
//
//   Future<void> _promptUserId() async {
//     final userId = await showDialog<String>(
//       context: context,
//       builder: (context) {
//         final userIdController = TextEditingController();
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
//               onPressed: () => Navigator.pop(context, null),
//               child: Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context, userIdController.text.trim()),
//               child: Text('Submit'),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (userId != null && userId.isNotEmpty) {
//       setState(() {
//         _userId = userId;
//       });
//       if (_selectedReportType == 'custom') {
//         await _selectDateRange(context);
//       }
//       _updateReportData(); // Fetch report data after setting userId
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
//   }
//
//   Future<Map<String, dynamic>?> fetchReportData(
//       String reportType, String userId) async {
//     String token = storage.read('token') ?? '';
//     String url;
//
//     if (reportType == 'custom') {
//       String startDateTime = '${_formatDateTime(_startDate, _startTime)}';
//       String endDateTime = '${_formatDateTime(_endDate, _endTime)}';
//       url =
//       'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType&userId=$userId&startDate=$startDateTime&endDate=$endDateTime';
//     } else {
//       url =
//       'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType&userId=$userId';
//     }
//
//     try {
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       } else {
//         final errorData = json.decode(response.body);
//         throw Exception('Failed to load report data: ${errorData['message']}');
//       }
//     } catch (e) {
//       print('Error fetching data: $e');
//       return null;
//     }
//   }
//
//   void _updateReportData() {
//     if (_userId == null || _userId!.isEmpty) {
//       _promptUserId(); // Ensure User ID is set
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//       _reportData = fetchReportData(_selectedReportType, _userId!);
//       _isLoading = false;
//     });
//   }
//
//   String _formatDateTime(DateTime date, TimeOfDay time) {
//     return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
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
//             Text('Select Report Type',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             SizedBox(height: 8),
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.blueAccent),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: DropdownButton<String>(
//                 isExpanded: true,
//                 value: _selectedReportType,
//                 items: <String>['custom', 'daily', 'weekly', 'monthly'].map((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),
//                 onChanged: (String? newValue) async {
//                   setState(() {
//                     _selectedReportType = newValue!;
//                   });
//                   await _promptUserId(); // Ask for User ID immediately
//                 },
//               ),
//             ),
//             SizedBox(height: 16),
//             Expanded(
//               child: FutureBuilder<Map<String, dynamic>?>(
//                 future: _reportData,
//                 builder: (context, snapshot) {
//                   if (_isLoading) {
//                     return Center(child: CircularProgressIndicator());
//                   } else if (snapshot.hasError) {
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   } else if (!snapshot.hasData || snapshot.data == null) {
//                     return Center(child: Text('No reports found'));
//                   } else {
//                     final reportData = snapshot.data!['data'];
//                     if (reportData == null) {
//                       return Center(child: Text('No report data available'));
//                     }
//
//                     final reportList = reportData['reportData'];
//                     if (reportList.isEmpty) {
//                       return Center(
//                         child: Text(
//                           'No Data Found for Selected Report Type',
//                           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                         ),
//                       );
//                     }
//
//                     return ListView.builder(
//                       itemCount: reportList.length,
//                       itemBuilder: (context, index) {
//                         final zone = reportList[index];
//                         return Card(
//                           margin: EdgeInsets.symmetric(vertical: 8),
//                           child: ListTile(
//                             title: Text('Zone Name: ${zone['zoneName']}'),
//                             subtitle: Text('Details available'),
//                           ),
//                         );
//                       },
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
class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final storage = GetStorage();
  String? _selectedReportType;
  String? _userId;
  bool _isLoading = false;
  Future<Map<String, dynamic>?>? _reportData;

  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 23, minute: 59);
  String? _downloadPath;
  @override
  void initState() {
    super.initState();
    // Initialize with a default report type and immediately fetch data
    _selectedReportType = 'daily';
    _promptUserIdForReport(_selectedReportType!);
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
              // Title
              pw.Text(
                'Zones General Report',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 10),

              // Table for product details
              pw.Table.fromTextArray(
                headers: ['UPC', 'Description', 'Qty', 'Retail'],
                data: flattenedProducts.map((product) => [
                  product['upc'] ?? 'N/A',
                  product['description'] ?? 'N/A',
                  product['totalQty']?.toString() ?? '0',
                  '\$${product['retailPrice']?.toStringAsFixed(2) ?? '0.00'}',
                ]).toList(),
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
              pw.SizedBox(height: 20),

              // Overall Totals Section
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

      final fileName = 'Zones General Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

  Future<void> _promptUserIdForReport(String reportType) async {
    final userId = await showDialog<String>(
      context: context,
      builder: (context) {
        final userIdController = TextEditingController();
        return AlertDialog(
          title: Text('Enter User ID for $reportType Report'),
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
      if (reportType == 'custom') {
        await _selectDateRange(context);
      }
      _fetchReportData();
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

  Future<Map<String, dynamic>?> fetchReportData(String reportType, String userId) async {
    String token = storage.read('token') ?? '';
    String url;

    if (reportType == 'custom') {
      String startDateTime = _formatDateTime(_startDate, _startTime);
      String endDateTime = _formatDateTime(_endDate, _endTime);
      url =
      'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType&userId=$userId&startDate=$startDateTime&endDate=$endDateTime';
    } else {
      url = 'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType&userId=$userId';
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
      return null;
    }
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
              // Title
              pw.Text(
                'NOF Report',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 10),

              // Table for product details
              pw.Table.fromTextArray(
                headers: ['UPC', 'Description', 'Qty', 'Retail'],
                data: flattenedProducts.map((product) => [
                  product['upc'] ?? 'N/A',
                  product['description'] ?? 'N/A',
                  product['totalQty']?.toString() ?? '0',
                  '\$${product['retailPrice']?.toStringAsFixed(2) ?? '0.00'}',
                ]).toList(),
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
              pw.SizedBox(height: 20),

              // Overall Totals Section
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

      final fileName = 'Nof_report${DateTime.now().millisecondsSinceEpoch}.pdf';
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
  void _fetchReportData() {
    if (_userId == null || _userId!.isEmpty) {
      return; // Skip fetch if userId is not set
    }

    setState(() {
      _isLoading = true;
      _reportData = fetchReportData(_selectedReportType!, _userId!);
    });
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zones General Report', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Report Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
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
                  await _promptUserIdForReport(_selectedReportType!);
                },
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _reportData,
                builder: (context, snapshot) {
                  if (_isLoading) {
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
                    if (reportList.isEmpty) {
                      return Center(
                        child: Text(
                          'No Data Found for Selected Report Type',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: reportList.length,
                      itemBuilder: (context, index) {
                        final zone = reportList[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text('Zone Name: ${zone['zoneName']}'),
                            subtitle: Text('Details available'),
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
