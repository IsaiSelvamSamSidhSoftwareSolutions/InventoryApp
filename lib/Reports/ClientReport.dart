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
    List<DataRow> rows = [];

    for (var zone in reportData) {
      for (var device in zone['devices']) {
        for (var product in device['products']) {
          rows.add(DataRow(
            cells: [
              DataCell(Text(zone['zoneName'] ?? '')),
              DataCell(Text(zone['zoneDescription'] ?? '')),
              DataCell(Text(product['upc'] ?? '')),
              DataCell(Text(product['description'] ?? '')),
              DataCell(Text((product['totalQty'] ?? 0).toString())),
              DataCell(Text((product['totalRetail'] ?? 0.0).toStringAsFixed(2))),
            ],
          ));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail Zones Report',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          'REPORTS GENERATED ON: ${getCurrentDateTime()}',
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
        SizedBox(height: 8), // Add some spacing
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('Zone Name')),
              DataColumn(label: Text('Zone Description')),
              DataColumn(label: Text('UPC#')),
              DataColumn(label: Text('Description')),
              DataColumn(label: Text('Qty')),
              DataColumn(label: Text('Total Retail')),
            ],
            rows: rows,
            dataRowColor: MaterialStateProperty.resolveWith((states) {
              return states.contains(MaterialState.selected) ? null : Colors.grey[200];
            }),
            dataRowHeight: 40,
          ),
        ),
      ],
    );
  }
}
class ZonesGeneralReportTable extends StatelessWidget {
  final List<dynamic> reportData;

  ZonesGeneralReportTable({required this.reportData});

  @override
  Widget build(BuildContext context) {
    List<DataRow> rows = [];

    for (var zone in reportData) {
      for (var device in zone['devices']) {
        for (var product in device['products']) {
          rows.add(DataRow(
            cells: [
              DataCell(Text(zone['zoneName'] ?? '')),
              DataCell(Text(zone['zoneDescription'] ?? '')),
              DataCell(Text(product['upc'] ?? '')),
              DataCell(Text(product['description'] ?? '')),
              DataCell(Text((product['totalRetail']?.toStringAsFixed(2) ?? '0.00'))),
            ],
          ));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zones General Report',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'REPORTS GENERATED ON: ${getCurrentDateTime()}',
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),// Add some spacing
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('Zone Name')),
              DataColumn(label: Text('Zone Description')),
              DataColumn(label: Text('UPC#')),
              DataColumn(label: Text('Description')),
              DataColumn(label: Text('Total Retail')),
            ],
            rows: rows,
            dataRowColor: MaterialStateProperty.resolveWith((states) {
              return states.contains(MaterialState.selected) ? null : Colors.grey[200];
            }),
            dataRowHeight: 40,
          ),
        ),
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
          String departmentName = product['departmentName'] ?? '';
          int totalQty = product['totalQty'] ?? 0;
          double totalRetail = product['totalRetail']?.toDouble() ?? 0.0;

          if (!departmentTotals.containsKey(departmentId)) {
            departmentTotals[departmentId] = {
              'departmentName': departmentName,
              'totalQuantity': 0 ,
              'totalRetail': 0.0,
            };
          }

          departmentTotals[departmentId]!['totalQuantity'] += totalQty;
          departmentTotals[departmentId]!['totalRetail'] += totalRetail;
        }
      }
    }

    List<DataRow> rows = departmentTotals.entries.map((entry) {
      return DataRow(
        cells: [
          DataCell(Text(entry.value['departmentName'] ?? '')),
          DataCell(Text(entry.key.toString())), // Department Id
          DataCell(Text(entry.value['totalQuantity'].toString())),
          DataCell(Text(entry.value['totalRetail'].toStringAsFixed(2))),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Department General Report',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          'REPORTS GENERATED ON: ${getCurrentDateTime()}',
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
        SizedBox(height: 8), // Add some spacing
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('Department Name')),
              DataColumn(label: Text('Department Id')),
              DataColumn(label: Text('Qty')),
              DataColumn(label: Text('Total Retail')),
            ],
            rows: rows,
            dataRowColor: MaterialStateProperty.resolveWith((states) {
              return states.contains(MaterialState.selected) ? null : Colors.grey[200];
            }),
            dataRowHeight: 40,
          ),
        ),
      ],
    );
  }
}
class NofReportTable extends StatelessWidget {
  final List<dynamic> reportData;

  NofReportTable({required this.reportData});

  @override
  Widget build(BuildContext context) {
    List<DataRow> rows = [];

    for (var zone in reportData) {
      for (var device in zone['devices']) {
        if (device['products'] != null) {
          for (var product in device['products']) {
            // Debugging prints
            print('Product UPC: ${product['upc']}');
            print('Retail Price: ${product['retailPrice']}');
            print('Total Retail: ${product['totalRetail']}');
            rows.add(DataRow(
              cells: [
                DataCell(Text(product['departmentId']?.toString() ?? '')), // Dept #
                DataCell(Text(product['departmentName'] ?? '')), // Department Name
                DataCell(Text(product['upc'] ?? '')), // UPC#
                DataCell(Text((product['totalQty'] ?? 0).toString())), // Qty
                // DataCell(Text((double.tryParse(product['retailPrice'].toString()) ?? 0.0).toStringAsFixed(2))), // Retail $
                DataCell(Text(product['retailPrice'] != null ? product['retailPrice'].toString() : 'N/A')),
                DataCell(Text((double.tryParse(product['totalRetail'].toString()) ?? 0.0).toStringAsFixed(2))), // Retail Total $
              ],
            ));
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOF Report',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          'REPORTS GENERATED ON: ${getCurrentDateTime()}',
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
        SizedBox(height: 8), // Add some spacing
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
            dataRowColor: MaterialStateProperty.resolveWith((states) {
              return states.contains(MaterialState.selected) ? null : Colors.grey[200];
            }),
            dataRowHeight: 40,
          ),
        ),
      ],
    );
  }
}