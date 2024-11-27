import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
void main() async {
  await GetStorage.init(); // Initialize GetStorage
  runApp(ReportPageClient());
}

class ReportPageClient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Report Generation Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ReportGenerator(),
    );
  }
}

class ReportGenerator extends StatefulWidget {
  @override
  _ReportGeneratorState createState() => _ReportGeneratorState();
}

class _ReportGeneratorState extends State<ReportGenerator> {
  String? selectedReport;
  bool isLoading = false;
  List<dynamic> reportData = [];
  String? generatedTimestamp;
  List<dynamic> nofReportData = [];

  // Updated report types
  final List<String> reportTypes = [
    'Daily',
    'Weekly',
    'Monthly',

  ];

  @override
  void initState() {
    super.initState();
    // Set default selected report type to 'Daily'
    selectedReport = reportTypes.first;
    // Automatically generate the report for the default selection
    generateReport();
  }

  Future<Map<String, dynamic>> generateReport() async {
    if (selectedReport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a report type.')),
      );
      return {'status': 'error', 'message': 'No report type selected'};
    }

    try {
      setState(() {
        isLoading = true;
        reportData = [];
        nofReportData = [];
      });

      String token = getToken();
      String url = 'https://iscandata.com/api/v1/reports';

      Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // API call for the department general report
      final departmentResponse = await http.get(
        Uri.parse(
            '$url/generate-report?reportType=${selectedReport!.toLowerCase()}'),
        headers: headers,
      );

      // API call for the NOF report
      final nofResponse = await http.get(
        Uri.parse('$url/generate-nof-report?reportType=${selectedReport!
            .toLowerCase()}'),
        headers: headers,
      );

      // Handle Department Report Response
      if (departmentResponse.statusCode == 200) {
        var data = jsonDecode(departmentResponse.body);
        print("Nof API $data");
        if (data is Map && data.containsKey('data')) {
          reportData = data['data']['reportData'] ?? [];
        }
      }

      // Handle NOF Report Response
      if (nofResponse.statusCode == 200) {
        var nofData = jsonDecode(nofResponse.body);
        if (nofData is Map && nofData.containsKey('data')) {
          nofReportData = nofData['data']['formattedReport'] ?? [];
          print("Nof Report Complete $nofReportData");
        }
      }

      // Safely calculate overall totals
      final totalQty = reportData.fold<int>(
        0,
            (sum, item) => sum + (item['totalQty'] ?? 0) as int,
      );
      final totalRetail = reportData.fold<double>(
        0.0,
            (sum, item) => sum + (item['totalRetail'] ?? 0.0) as double,
      );

      // Return combined results
      return {
        'status': 'success',
        'data': {
          'reportData': reportData,
          'overallTotals': {
            'totalQty': totalQty,
            'totalRetail': totalRetail,
          },
        },
      };
    } catch (e) {
      print("Error generating report: $e");
      return {'status': 'error', 'message': e.toString()};
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Future<void> generateReport() async {
  //   if (selectedReport == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Please select report type.')),
  //     );
  //     return;
  //   }
  //
  //   setState(() {
  //     isLoading = true;
  //     reportData = [];
  //     nofReportData = []; // Initialize NOF report data
  //   });
  //
  //   String token = getToken();
  //   String url = 'https://iscandata.com/api/v1/reports';
  //
  //   Map<String, String> headers = {
  //     'Authorization': 'Bearer $token',
  //     'Content-Type': 'application/json',
  //   };
  //
  //   // API call for the department general report
  //   final departmentResponse = await http.get(
  //     Uri.parse('$url/generate-report?reportType=${selectedReport!.toLowerCase()}'),
  //     headers: headers,
  //   );
  //
  //   // API call for the NOF report
  //   final nofResponse = await http.get(
  //     Uri.parse('$url/generate-nof-report?reportType=${selectedReport!.toLowerCase()}'),
  //     headers: headers,
  //   );
  //
  //   // Handle Department Report Response
  //   if (departmentResponse.statusCode == 200) {
  //     var data = jsonDecode(departmentResponse.body);
  //     print("Department API Response: $data"); // Debugging line to check the API response
  //
  //     if (data is Map && data.containsKey('data')) {
  //       var reportDataMap = data['data'];
  //
  //       // Handle different report types
  //       if (reportDataMap.containsKey('reportData')) {
  //         setState(() {
  //           reportData = reportDataMap['reportData'];
  //         });
  //       } else if (reportDataMap.containsKey('formattedReport')) {
  //         setState(() {
  //           reportData = reportDataMap['formattedReport'];
  //         });
  //       }
  //     }
  //   }
  //
  //   if (nofResponse.statusCode == 200) {
  //     var nofData = jsonDecode(nofResponse.body);
  //     print("NOF API Response: $nofData"); // Debugging line
  //
  //     if (nofData is Map && nofData.containsKey('data')) {
  //       var nofReportDataMap = nofData['data'];
  //
  //       // Extract formattedReport from NOF data
  //       if (nofReportDataMap.containsKey('formattedReport')) {
  //         setState(() {
  //           nofReportData = nofReportDataMap['formattedReport'];
  //           print("NOF Report Data: $nofReportData"); // Debugging line
  //         });
  //       }
  //     }
  //   }
  //   // Set the generated timestamp
  //   generatedTimestamp = DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now());
  //
  //   setState(() {
  //     isLoading = false;
  //   });
  // }

  String getToken() {
    final box = GetStorage();
    return box.read('token') ?? '';
  }

  Future<void> _generateAndSavePDF({
    required BuildContext context,
    required List<dynamic> reportData,
    required List<dynamic> nofReportData,
    required Map<String, dynamic> overallTotals,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              _buildDetailZonesReport(reportData),
              pw.SizedBox(height: 20),
              _buildZonesGeneralReport(reportData),
              pw.SizedBox(height: 20),
              _buildDepartmentGeneralReport(reportData),
              pw.SizedBox(height: 20),
              _buildNofReport(nofReportData),
              pw.SizedBox(height: 20),
              //_buildOverallTotals(overallTotals),
            ];
          },
        ),
      );

      String? _downloadPath;

      // Select directory for saving the PDF
      if (_downloadPath == null) {
        _downloadPath = await FilePicker.platform.getDirectoryPath();
        if (_downloadPath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No directory selected. PDF not saved.')),
          );
          return;
        }
      }

      // Save the file
      final fileName = 'Generated_Report_${DateTime
          .now()
          .millisecondsSinceEpoch}.pdf';
      final filePath = '$_downloadPath/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to $filePath')),
      );

      // Send the PDF via email
      await _sendEmailWithPDF(context, filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PDF. Please try again.')),
      );
      print("Error generating PDF: $e");
    }
  }

// Function to send the PDF via email
  Future<void> _sendEmailWithPDF(BuildContext context, String filePath) async {
    try {
      final storage = GetStorage();
      final token = storage.read('token') as String?;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication token not available')),
        );
        return;
      }

      final file = File(filePath);
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
        filePath,
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
      print("Error sending email: $e");
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text('Report Generator'),
  //       backgroundColor: Colors.blueAccent,
  //       leading: IconButton(
  //         icon: Icon(Icons.arrow_back),
  //         onPressed: () {
  //           Navigator.pop(context);
  //         },
  //       ),
  //     ),
  //     body: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: ListView(
  //         children: [
  //           DropdownButtonFormField(
  //             decoration: InputDecoration(
  //               labelText: 'Select Report Type',
  //               border: OutlineInputBorder(),
  //             ),
  //             value: selectedReport,
  //             onChanged: (value) {
  //               setState(() {
  //                 selectedReport = value as String?;
  //               });
  //             },
  //             items: reportTypes.map((reportType) {
  //               return DropdownMenuItem(
  //                 value: reportType,
  //                 child: Text(reportType),
  //               );
  //             }).toList(),
  //           ),
  //           SizedBox(height: 16),
  //           ElevatedButton(
  //             onPressed: generateReport,
  //             child: Text('Generate Report'),
  //           ),
  //           SizedBox(height: 16),
  //           if (isLoading)
  //             Center(
  //               child: CircularProgressIndicator(),
  //             )
  //           else if (reportData.isNotEmpty)
  //             Column(
  //               children: [
  //                 DetailZonesReportTable(reportData: reportData),
  //                 ZonesGeneralReportTable(reportData: reportData),
  //                 DepartmentGeneralReportTable(reportData: reportData),
  //                 NofReportTable(nofReportData: nofReportData),
  //               ],
  //             )
  //           else
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 if (generatedTimestamp != null)
  //                   Text(
  //                     'Report generated at $generatedTimestamp',
  //                     style: TextStyle(fontSize: 16),
  //                   ),
  //                 Text(
  //                   'No data found for the selected report type.',
  //                   style: TextStyle(fontSize: 16, color: Colors.red),
  //                 ),
  //               ],
  //             ),
  //         ],
  //       ),
  //     ),
  //       floatingActionButton: FloatingActionButton.extended(
  //         onPressed: () async {
  //           try {
  //             // Fetch report data
  //             final snapshot = await generateReport();
  //             if (snapshot['status'] == 'success') {
  //               final reportList = snapshot['data']['reportData'] ?? [];
  //               final overallTotals = snapshot['data']['overallTotals'] ?? {};
  //
  //               // Call PDF generation and saving
  //               await _generateAndSavePDF(
  //                 context: context,
  //                 reportData: reportList,
  //                 overallTotals: overallTotals,
  //                 nofReportData: nofReportData
  //               );
  //             } else {
  //               // Show error if fetching report data fails
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 SnackBar(content: Text(snapshot['message'] ?? 'Failed to fetch report data.')),
  //               );
  //             }
  //           } catch (e) {
  //             // Handle any errors during PDF generation or email sending
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               SnackBar(content: Text('An error occurred: $e')),
  //             );
  //             print("Error: $e");
  //           }
  //         },
  //         label: Text('Download & Email'),
  //         icon: Icon(Icons.download),
  //         backgroundColor: Colors.blueAccent,
  //       )
  //   );
  // }
// }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Generator'),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(bottom: 80),
              // Add bottom padding to avoid overlap
              children: [
                DropdownButtonFormField(
                  decoration: InputDecoration(
                    labelText: 'Select Report Type',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedReport,
                  onChanged: (value) {
                    setState(() {
                      selectedReport = value as String?;
                    });
                  },
                  items: reportTypes.map((reportType) {
                    return DropdownMenuItem(
                      value: reportType,
                      child: Text(reportType),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: generateReport,
                  child: Text('Generate Report'),
                ),
                SizedBox(height: 16),
                if (isLoading)
                  Center(
                    child: CircularProgressIndicator(),
                  )
                else
                  if (reportData.isNotEmpty)
                    Column(
                      children: [
                        DetailZonesReportTable(reportData: reportData),
                        ZonesGeneralReportTable(reportData: reportData),
                        DepartmentGeneralReportTable(reportData: reportData),
                        NofReportTable(nofReportData: nofReportData),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (generatedTimestamp != null)
                          Text(
                            'Report generated at $generatedTimestamp',
                            style: TextStyle(fontSize: 16),
                          ),
                        Text(
                          'No data found for the selected report type.',
                          style: TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      ],
                    ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  try {
                    // Fetch report data
                    final snapshot = await generateReport();
                    if (snapshot['status'] == 'success') {
                      final reportList = snapshot['data']['reportData'] ?? [];
                      final overallTotals = snapshot['data']['overallTotals'] ??
                          {};

                      // Call PDF generation and saving
                      await _generateAndSavePDF(
                        context: context,
                        reportData: reportList,
                        overallTotals: overallTotals,
                        nofReportData: nofReportData,
                      );
                    } else {
                      // Show error if fetching report data fails
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(snapshot['message'] ??
                                'Failed to fetch report data.')),
                      );
                    }
                  } catch (e) {
                    // Handle any errors during PDF generation or email sending
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('An error occurred: $e')),
                    );
                    print("Error: $e");
                  }
                },
                label: Text('Download & Email'),
                icon: Icon(Icons.download),
                backgroundColor: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
  String getCurrentDateTime() {
  DateTime now = DateTime.now();
  return "${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
}
/////////////////////////////////
// PDF GENERATION

class DetailZonesReportTable extends StatelessWidget {
  final List<dynamic> reportData;

  DetailZonesReportTable({required this.reportData});

  @override
  Widget build(BuildContext context) {
    List<Widget> zoneTables = [];

    for (var zone in reportData) {
      List<DataRow> rows = [];
      int totalQty = 0;
      double totalRetail = 0.0;

      for (var device in zone['devices']) {
        for (var product in device['products']) {
          int productQty = product['totalQty'] ?? 0;
          double productRetail = product['totalRetail']?.toDouble() ?? 0.0;

          totalQty += productQty;
          totalRetail += productRetail;

          rows.add(DataRow(
            cells: [
              DataCell(Text(product['upc'] ?? '')),
              DataCell(Text(product['description'] ?? '')),
              DataCell(Text(productQty.toString())),
              DataCell(Text(productRetail.toStringAsFixed(2))),
            ],
          ));
        }
      }

      // Add totals row only once after each zone data
      rows.add(DataRow(
        cells: [
          DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text('')),
          DataCell(Text(totalQty.toString(), style: TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(totalRetail.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ));

      // Create DataTable for each zone
      zoneTables.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone Header
          Text(
            '${zone['zoneName']} - ${zone['zoneDescription']}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          // Data Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text('UPC#')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Total Retail')),
              ],
              rows: rows,
            ),
          ),
          SizedBox(height: 16), // Spacing between zones
        ],
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header for the entire table
        Text(
          'Detail Zones Report Table \n [Zone#] [zone name custom label] [UPC#] [Description] [Qty] [Total Retail]',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
        SizedBox(height: 16),
        ...zoneTables,
      ],
    );
  }
}
class ZonesGeneralReportTable extends StatelessWidget {
  final List<dynamic> reportData;

  ZonesGeneralReportTable({required this.reportData});

  @override
  Widget build(BuildContext context) {
    List<Widget> zoneTables = [];

    for (var zone in reportData) {
      List<DataRow> rows = [];
      int totalQty = 0; // Track total quantity for the zone
      double totalRetail = 0.0; // Track total retail for the zone

      Map<int, Map<String, dynamic>> departmentTotals = {};

      for (var device in zone['devices']) {
        for (var product in device['products']) {
          int departmentId = product['departmentId'] ?? 0;
          String departmentName = product['departmentName'] ?? 'Unknown';
          int qty = product['totalQty'] ?? 0;
          double retail = product['totalRetail']?.toDouble() ?? 0.0;

          // Aggregate data by department
          if (!departmentTotals.containsKey(departmentId)) {
            departmentTotals[departmentId] = {
              'departmentName': departmentName,
              'totalQty': 0,
              'totalRetail': 0.0,
            };
          }

          departmentTotals[departmentId]!['totalQty'] += qty;
          departmentTotals[departmentId]!['totalRetail'] += retail;

          // Add to zone totals
          totalQty += qty;
          totalRetail += retail;
        }
      }

      // Generate rows for the department
      departmentTotals.forEach((departmentId, totals) {
        rows.add(DataRow(
          cells: [
            DataCell(Text(departmentId.toString())), // Department ID
            DataCell(Text(totals['departmentName'])), // Department Name
            DataCell(Text(totals['totalQty'].toString())), // Qty
            DataCell(Text(totals['totalRetail'].toStringAsFixed(2))), // Total Retail
          ],
        ));
      });

      // Add total row for the zone
      rows.add(DataRow(
        cells: [
          DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text('')),
          DataCell(Text(totalQty.toString(), style: TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(totalRetail.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ));

      // Create DataTable for each zone
      zoneTables.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone Header
          Text(
            '${zone['zoneName']} - ${zone['zoneDescription']}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          // Data Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text('Department ID')),
                DataColumn(label: Text('Department Name')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Total Retail')),
              ],
              rows: rows,
            ),
          ),
          SizedBox(height: 16), // Spacing between zones
        ],
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add the report header
        Text(
          'Zones General Report Table \n [Zone#] [Departments with counted products] [Qty] [Total Retail]',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
        SizedBox(height: 16),
        ...zoneTables,
      ],
    );
  }
}
class NofReportTable extends StatelessWidget {
  final List<dynamic> nofReportData;

  const NofReportTable({required this.nofReportData, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (nofReportData.isEmpty) {
      return Center(
        child: Text(
          'No data available for NOF Report.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    List<DataRow> rows = [];
    int totalQty = 0;
    double totalRetail = 0.0;

    // Loop through departments and products
    for (var department in nofReportData) {
      for (var product in department['products'] ?? []) {
        int qty = product['totalQty'] ?? 0;
        double retail = _safeToDouble(product['totalRetail']);

        // Aggregate totals
        totalQty += qty;
        totalRetail += retail;

        rows.add(
          DataRow(
            cells: [
              DataCell(Text(department['deptId']?.toString() ?? 'N/A')), // Dept #
              DataCell(Text(department['deptName'] ?? 'Unknown')), // Department Name
              DataCell(Text(product['upc'] ?? 'N/A')), // UPC#
              DataCell(Text(qty.toString())), // Qty
              DataCell(Text('\$${_formatPrice(product['retailPrice'])}')), // Retail $
              DataCell(Text('\$${_formatPrice(retail)}')), // Retail Total
            ],
          ),
        );
      }
    }

    // Add total row
    rows.add(DataRow(
      cells: [
        DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text(totalQty.toString(), style: TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text('')),
        DataCell(Text('\$${totalRetail.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    ));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Dept #')),
          DataColumn(label: Text('Department Name')),
          DataColumn(label: Text('UPC#')),
          DataColumn(label: Text('Qty')),
          DataColumn(label: Text('Retail')),
          DataColumn(label: Text('Retail Total')),
        ],
        rows: rows,
      ),
    );
  }

  /// Helper method to safely parse a value to double
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0; // Attempt to parse string
    }
    return 0.0; // Default fallback
  }

  /// Helper method to safely format price values
  String _formatPrice(dynamic price) {
    return _safeToDouble(price).toStringAsFixed(2);
  }
}
class DepartmentGeneralReportTable extends StatelessWidget {
  final List<dynamic> reportData;

  DepartmentGeneralReportTable({required this.reportData});

  @override
  Widget build(BuildContext context) {
    Map<int, Map<String, dynamic>> departmentTotals = {};

    for (var zone in reportData) {
      for (var device in zone['devices']) {
        for (var product in device['products']) {
          int departmentId = product['departmentId'] ?? 0;
          String departmentName = product['departmentName'] ?? 'Unknown';
          int qty = product['totalQty'] ?? 0;
          double retail = product['totalRetail']?.toDouble() ?? 0.0;

          if (!departmentTotals.containsKey(departmentId)) {
            departmentTotals[departmentId] = {
              'departmentName': departmentName,
              'totalQuantity': 0,
              'totalRetail': 0.0,
            };
          }

          departmentTotals[departmentId]!['totalQuantity'] += qty;
          departmentTotals[departmentId]!['totalRetail'] += retail;
        }
      }
    }

    List<Widget> departmentTables = [];

    departmentTotals.forEach((departmentId, totals) {
      List<DataRow> rows = [];

      rows.add(DataRow(
        cells: [
          DataCell(Text(departmentId.toString())), // Department ID
          DataCell(Text(totals['departmentName'])), // Department Name
          DataCell(Text(totals['totalQuantity'].toString())), // Qty
          DataCell(Text(totals['totalRetail'].toStringAsFixed(2))), // Total Retail
        ],
      ));

      // Add totals row for the department
      rows.add(DataRow(
        cells: [
          DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text('')),
          DataCell(Text(
            totals['totalQuantity'].toString(),
            style: TextStyle(fontWeight: FontWeight.bold),
          )),
          DataCell(Text(
            totals['totalRetail'].toStringAsFixed(2),
            style: TextStyle(fontWeight: FontWeight.bold),
          )),
        ],
      ));

      // Add each department's table
      departmentTables.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${totals['departmentName']} (Department ID: $departmentId)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text('Department ID')),
                DataColumn(label: Text('Department Name')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Total Retail')),
              ],
              rows: rows,
            ),
          ),
          SizedBox(height: 16),
        ],
      ));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add the table header
        Text(
          'Department General -[Dept#] [Department Name] [Qty] [Total Retail]',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
        SizedBox(height: 16),
        ...departmentTables,
      ],
    );
  }
}

//
pw.Widget _buildDetailZonesReport(List<dynamic> reportData) {
  final rows = <List<String>>[];
  int overallQty = 0;
  double overallRetail = 0.0;

  for (var zone in reportData) {
    int zoneTotalQty = 0;
    double zoneTotalRetail = 0.0;

    final devices = zone['devices'] as List<dynamic>? ?? [];
    for (var device in devices) {
      final products = device['products'] as List<dynamic>? ?? [];
      for (var product in products) {
        final int qty = product['totalQty'] ?? 0;
        final retail = product['totalRetail']?.toDouble() ?? 0.0;

        zoneTotalQty += qty.toInt();
        zoneTotalRetail += retail;

        rows.add([
          zone['zoneName'] ?? 'N/A',
          product['upc'] ?? 'N/A',
          product['description'] ?? 'N/A',
          qty.toString(),
          '\$${retail.toStringAsFixed(2)}',
        ]);
      }
    }

    overallQty += zoneTotalQty;
    overallRetail += zoneTotalRetail;

    // Add totals row for this zone
    rows.add([
      'TOTAL (${zone['zoneName']})',
      '',
      '',
      zoneTotalQty.toString(),
      '\$${zoneTotalRetail.toStringAsFixed(2)}',
    ]);
  }

  // Add overall totals
  rows.add([
    'GRAND TOTAL',
    '',
    '',
    overallQty.toString(),
    '\$${overallRetail.toStringAsFixed(2)}',
  ]);

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Detail Zones Report',
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 10),
      pw.Table.fromTextArray(
        headers: ['Zone Name', 'UPC', 'Description', 'Qty', 'Total Retail'],
        data: rows,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        cellStyle: pw.TextStyle(fontSize: 9),
        border: pw.TableBorder.all(color: PdfColors.grey),
      ),
    ],
  );
}
pw.Widget _buildZonesGeneralReport(List<dynamic> reportData) {
  final rows = <List<String>>[];
  int overallQty = 0;
  double overallRetail = 0.0;

  for (var zone in reportData) {
    int zoneTotalQty = 0;
    double zoneTotalRetail = 0.0;

    final devices = zone['devices'] as List<dynamic>? ?? [];
    for (var device in devices) {
      final products = device['products'] as List<dynamic>? ?? [];
      for (var product in products) {
        final int qty = product['totalQty'] ?? 0;
        final retail = product['totalRetail']?.toDouble() ?? 0.0;

        zoneTotalQty += qty.toInt();
        zoneTotalRetail += retail;

        rows.add([
          zone['zoneName'] ?? 'N/A',
          product['departmentName'] ?? 'N/A',
          qty.toString(),
          '\$${retail.toStringAsFixed(2)}',
        ]);
      }
    }

    overallQty += zoneTotalQty;
    overallRetail += zoneTotalRetail;

    // Add totals row for this zone
    rows.add([
      'TOTAL (${zone['zoneName']})',
      '',
      zoneTotalQty.toString(),
      '\$${zoneTotalRetail.toStringAsFixed(2)}',
    ]);
  }

  // Add overall totals
  rows.add([
    'GRAND TOTAL',
    '',
    overallQty.toString(),
    '\$${overallRetail.toStringAsFixed(2)}',
  ]);

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Zones General Report',
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 10),
      pw.Table.fromTextArray(
        headers: ['Zone Name', 'Department Name', 'Qty', 'Total Retail'],
        data: rows,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        cellStyle: pw.TextStyle(fontSize: 9),
        border: pw.TableBorder.all(color: PdfColors.grey),
      ),
    ],
  );
}
pw.Widget _buildDepartmentGeneralReport(List<dynamic> reportData) {
  final rows = <List<String>>[];
  int totalQty = 0;
  double totalRetail = 0.0;

  // Aggregate data by department
  final departmentTotals = <String, Map<String, dynamic>>{};
  for (var zone in reportData) {
    final devices = zone['devices'] as List<dynamic>? ?? [];
    for (var device in devices) {
      final products = device['products'] as List<dynamic>? ?? [];
      for (var product in products) {
        final deptName = product['departmentName'] ?? 'Unknown';
        final qty = int.tryParse(product['totalQty'].toString()) ?? 0; // Safe parsing
        final retail = double.tryParse(product['totalRetail']?.toString() ?? '0') ?? 0.0;

        // Update department totals
        if (!departmentTotals.containsKey(deptName)) {
          departmentTotals[deptName] = {'qty': 0, 'retail': 0.0};
        }
        departmentTotals[deptName]!['qty'] += qty;
        departmentTotals[deptName]!['retail'] += retail;

        // Update overall totals
        totalQty += qty;
        totalRetail += retail;
      }
    }
  }

  // Prepare rows for PDF table
  departmentTotals.forEach((deptName, totals) {
    rows.add([
      deptName,
      totals['qty'].toString(),
      '\$${totals['retail'].toStringAsFixed(2)}',
    ]);
  });

  // Add grand total row
  rows.add([
    'TOTAL',
    totalQty.toString(),
    '\$${totalRetail.toStringAsFixed(2)}',
  ]);

  // Build the PDF table
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Department General Report',
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 10),
      pw.Table.fromTextArray(
        headers: ['Department Name', 'Qty', 'Total Retail'],
        data: rows,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        cellStyle: pw.TextStyle(fontSize: 9),
        border: pw.TableBorder.all(color: PdfColors.grey),
      ),
    ],
  );
}
pw.Widget _buildNofReport(List<dynamic> nofReportData) {
  final rows = <List<String>>[];
  int totalQty = 0;
  double totalRetail = 0.0;

  for (var department in nofReportData) {
    final products = department['products'] as List<dynamic>? ?? [];
    for (var product in products) {
      final qty = product['totalQty'] ?? 0;
      final retailPriceString = product['retailPrice'] ?? '0';
      final retailTotalString = product['totalRetail'] ?? '0';

      // Safely parse to double
      final retailPrice = double.tryParse(retailPriceString.toString()) ?? 0.0;
      final retailTotal = double.tryParse(retailTotalString.toString()) ?? 0.0;

      rows.add([
        department['deptId']?.toString() ?? 'N/A',
        department['deptName'] ?? 'Unknown',
        product['upc'] ?? 'N/A',
        qty.toString(),
        '\$${retailPrice.toStringAsFixed(2)}',
        '\$${retailTotal.toStringAsFixed(2)}',
      ]);

      totalQty += int.tryParse(qty.toString()) ?? 0;
      totalRetail += retailTotal;
    }
  }

  // Add grand total row
  rows.add([
    'TOTAL',
    '',
    '',
    totalQty.toString(),
    '',
    '\$${totalRetail.toStringAsFixed(2)}',
  ]);

  // Build the PDF table
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'NOF Report',
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 10),
      pw.Table.fromTextArray(
        headers: [
          'Dept #',
          'Department Name',
          'UPC#',
          'Qty',
          'Retail',
          'Total Retail',
        ],
        data: rows,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        cellStyle: pw.TextStyle(fontSize: 9),
        border: pw.TableBorder.all(color: PdfColors.grey),
      ),
    ],
  );
}
