import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';

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
  Future<void> generateReport() async {
    if (selectedReport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select report type.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      reportData = [];
      nofReportData = []; // Initialize NOF report data
    });

    String token = getToken();
    String url = 'https://iscandata.com/api/v1/reports';

    Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // API call for the department general report
    final departmentResponse = await http.get(
      Uri.parse('$url/generate-report?reportType=${selectedReport!.toLowerCase()}'),
      headers: headers,
    );

    // API call for the NOF report
    final nofResponse = await http.get(
      Uri.parse('$url/generate-nof-report?reportType=${selectedReport!.toLowerCase()}'),
      headers: headers,
    );

    // Handle Department Report Response
    if (departmentResponse.statusCode == 200) {
      var data = jsonDecode(departmentResponse.body);
      print("Department API Response: $data"); // Debugging line to check the API response

      if (data is Map && data.containsKey('data')) {
        var reportDataMap = data['data'];

        // Handle different report types
        if (reportDataMap.containsKey('reportData')) {
          setState(() {
            reportData = reportDataMap['reportData'];
          });
        } else if (reportDataMap.containsKey('formattedReport')) {
          setState(() {
            reportData = reportDataMap['formattedReport'];
          });
        }
      }
    }

    if (nofResponse.statusCode == 200) {
      var nofData = jsonDecode(nofResponse.body);
      print("NOF API Response: $nofData"); // Debugging line

      if (nofData is Map && nofData.containsKey('data')) {
        var nofReportDataMap = nofData['data'];

        // Extract formattedReport from NOF data
        if (nofReportDataMap.containsKey('formattedReport')) {
          setState(() {
            nofReportData = nofReportDataMap['formattedReport'];
            print("NOF Report Data: $nofReportData"); // Debugging line
          });
        }
      }
    }
    // Set the generated timestamp
    generatedTimestamp = DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now());

    setState(() {
      isLoading = false;
    });
  }

  String getToken() {
    final box = GetStorage();
    return box.read('token') ?? '';
  }

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
        child: ListView(
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
            else if (reportData.isNotEmpty)
              Column(
                children: [
                  DetailZonesReportTable(reportData: reportData),
                  ZonesGeneralReportTable(reportData: reportData),
                  DepartmentGeneralReportTable(reportData: reportData),
                  NofReportTable(reportData: reportData),
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
      ),
    );
  }
}
String getCurrentDateTime() {
  DateTime now = DateTime.now();
  return "${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
}

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
      // int totalQty = 0;
      // double totalRetail = 0.0;
      int totalQty = 0;  // Change to num if necessary
      double totalRetail = 0.0;  // Already fine for floating-point calculations

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
        num totalQty = 0;  // Compatible with both int and double
        totalQty += totals['totalQty'];  // Works seamlessly// totals['totalQty'] is likely a num
        totalRetail += totals['totalRetail'];
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
class NofReportTable extends StatelessWidget {
  final List<dynamic> reportData;

  NofReportTable({required this.reportData});

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
              DataCell(Text(product['departmentId']?.toString() ?? '')), // Dept #
              DataCell(Text(product['departmentName'] ?? 'Unknown')), // Department Name
              DataCell(Text(product['upc'] ?? '')), // UPC#
              DataCell(Text(productQty.toString())), // Qty
              DataCell(Text(product['retailPrice'] != null
                  ? product['retailPrice'].toString()
                  : 'N/A')), // Retail
              DataCell(Text(productRetail.toStringAsFixed(2))), // Retail Total
            ],
          ));
        }
      }

      // Add totals row for the zone
      rows.add(DataRow(
        cells: [
          DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text(
            totalQty.toString(),
            style: TextStyle(fontWeight: FontWeight.bold),
          )),
          DataCell(Text('')),
          DataCell(Text(
            totalRetail.toStringAsFixed(2),
            style: TextStyle(fontWeight: FontWeight.bold),
          )),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text('Dept #')),
                DataColumn(label: Text('Department Name')),
                DataColumn(label: Text('UPC#')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Retail')),
                DataColumn(label: Text('Retail Total')),
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
        // Add the table header
        Text(
          'Nof Report [Dept #] [Department Name] [UPC#] [Qty] [Retail] [Retail Total]',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
        SizedBox(height: 16),
        ...zoneTables,
      ],
    );
  }
}
