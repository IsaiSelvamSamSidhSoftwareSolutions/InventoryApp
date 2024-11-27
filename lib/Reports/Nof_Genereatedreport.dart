

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
Future<Map<String, dynamic>> fetchReportData(
    String startDateTime, String endDateTime, String token, String reportType, String? userId) async {
  final String url =
      'https://iscandata.com/api/v1/reports/generate-nof-report?startDate=$startDateTime&endDate=$endDateTime&reportType=$reportType${userId != null ? '&userId=$userId' : ''}';

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

class Nof_ReportPage extends StatefulWidget {
  @override
  _NofReportPageState createState() => _NofReportPageState();
}

class _NofReportPageState extends State<Nof_ReportPage> {
  late Future<Map<String, dynamic>> _reportData;
  final storage = GetStorage();
  String _selectedReportType = 'custom';
  String? _userId;
  String token = '';
  bool _isLoading = false;
  String? userRole;
  DateTime _startDate = DateTime.now().subtract(Duration(days: 10));
  DateTime _endDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 23, minute: 59);
  String? _downloadPath;
  @override
  void initState() {
    super.initState();
    token = storage.read('token') ?? '';
    userRole = storage.read('userRole') ?? '';
    if (userRole == 'admin') {
      _promptUserId();
    } else {
      _fetchReport();
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

    // Prompt for User ID if the user is an admin
    _promptUserId();
  }

  void _fetchReport() {
    if (userRole == 'admin' && (_userId == null || _userId!.isEmpty)) {
      print('Admin must provide a userId before fetching reports.');
      return;
    }

    String startDateTime = '${_formatDateTime(_startDate, _startTime)}';
    String endDateTime = '${_formatDateTime(_endDate, _endTime)}';

    setState(() {
      _isLoading = true;
    });

    _reportData = fetchReportData(
      startDateTime,
      endDateTime,
      token,
      _selectedReportType,
      _userId,
    ).catchError((error) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching report: $error');
      throw Exception('Unable to fetch report.');
    }).whenComplete(() {
      setState(() {
        _isLoading = false;
      });
    });
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
  Future<void> _generateAndSavePDF(List<dynamic> reportList, Map<String, dynamic> overallTotals) async {
    try {
      final pdf = pw.Document();

      // Flatten the nested structure for departments and products
      final flattenedProducts = reportList.expand((department) {
        final products = department['products'] as List<dynamic>? ?? [];
        return products;
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
                  '\$${double.tryParse(product['retailPrice']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
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
              pw.Text(
                'Total Retail: \$${double.tryParse(overallTotals['totalRetail']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
              ),
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
      print("PDF ERROR $e");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('N.O.F. Report'),
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
                    _selectedReportType = _selectedReportType;
                  });
                  return;
                }

                setState(() {
                  _userId = userId; // Save the User ID
                  _selectedReportType = newValue; // Update the selected report type
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
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return Center(
                        child: Text(
                          'No data available. Select Report Type and enter the User ID',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error fetching report. Please try again.",
                          style: TextStyle(fontSize: 16, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else {
                      final statusCode = snapshot.data?['status'];

                      if (statusCode == 400) {
                        return Center(
                          child: Text(
                            'No Data Found for Report',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      final reportData = snapshot.data!['data']['formattedReport']
                      as List<dynamic>;
                      final overallTotals =
                      snapshot.data!['data']['overallTotals'];

                      if (reportData.isEmpty) {
                        return Center(
                          child: Text(
                            'No Data Found for Selected Report Type',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: reportData.length + 1, // Add 1 for the final summary card
                        itemBuilder: (context, index) {
                          if (index < reportData.length) {
                            // Regular department cards
                            final report = reportData[index];
                            final products =
                            report['products'] as List<dynamic>;
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dept: ${report['deptName']}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(height: 5),
                                    ...products.map((product) => Padding(
                                      padding:
                                      const EdgeInsets.only(bottom: 5.0),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text('UPC: ${product['upc']}'),
                                          Text(
                                              'Description: ${product['description']}'),
                                          Text('Qty: ${product['totalQty']}'),
                                          Text(
                                              'Retail: \$${product['retailPrice']}'),
                                        ],
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            // Final summary card
                            return Card(
                              color: Colors.grey[200],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Overall Totals',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                        'Total Quantity: ${overallTotals['totalQty']}'),
                                    Text(
                                        'Total Retail: \$${overallTotals['totalRetail']}'),
                                  ],
                                ),
                              ),
                            );
                          }
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
          print("_report Data $snapshot");
          if (snapshot['status'] == 'success') {
            // Correctly extract the formattedReport
            final reportList = snapshot['data']['formattedReport'] ?? [];
            print("Report list $reportList");

            // Extract the overall totals
            final overallTotals = snapshot['data']['overallTotals'] ?? {};

            // Generate and save the PDF
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
  } }