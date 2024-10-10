import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
Future<Map<String, dynamic>> fetchReportData(String reportType, String token, {String? userId}) async {
  final url = 'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType${userId != null ? '&userId=$userId' : ''}';
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
    throw Exception('Unauthorized'); // Handle unauthorized access
  } else {
    throw Exception('Failed to load report data');
  }
}

class DetailedZoneReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<DetailedZoneReportPage> {
  late Future<Map<String, dynamic>> _reportData;
  final storage = GetStorage();
  String _selectedReportType = 'daily'; // Default report type
  List<dynamic> _reportList = [];
  String? _userId; // User ID for admin role
  String? _userRole; // User role
  String? _downloadPath;

  @override
  void initState() {
    super.initState();
    _userRole = storage.read('UserRole'); // Get user role from GetStorage
    _fetchReportData(); // Fetch data initially
    _downloadPath = storage.read('downloadPath');
  }

  Future<void> _fetchReportData() async {
    try {
      String token = storage.read('token') ?? '';
      if (_userRole == 'admin' && _userId != null) {
        _reportData = fetchReportData(_selectedReportType, token, userId: _userId);
      } else {
        _reportData = fetchReportData(_selectedReportType, token);
      }

      _reportData.then((data) {
        setState(() {
          _reportList = data['data']['reportData'] ?? []; // Set report list
        });
      }).catchError((error) {
        if (error.toString() == 'Unauthorized') {
          // Redirect to login page on 401
          Navigator.of(context).pushReplacementNamed('/login');
        } else {
          print('Error fetching report data: $error');
        }
      });
    } catch (e) {
      print('Error fetching report data: $e');
    }
  }
  void _onReportTypeChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedReportType = newValue;
      });
      if (_userRole == 'admin') {
        _showUserIdDialog(newValue);
      } else {
        _fetchReportData(); // Fetch new data based on report type selection
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
                  _fetchReportData();
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
  // Future<void> _generateAndSaveCSV(Map<String, dynamic> reportData) async {
  //   String csvData = 'Department Name, Zone Name, UPC, Description, Total Qty , totalRetail\n'; // CSV Header
  //
  //   final reportList = reportData['data']['reportData'] as List<dynamic>;
  //
  //   for (var zone in reportList) {
  //     for (var device in zone['devices']) {
  //       for (var product in device['products']) {
  //         csvData +=
  //         '${product['departmentName'] ?? ''}, '
  //             '${zone['zoneName'] ?? ''}, '
  //             '${product['upc'] ?? ''}, '
  //             '${product['description'] ?? ''}, '
  //             '${product['totalQty']?.toString() ?? '0'},'
  //             '${product['totalRetail']?.toString() ?? '0'}\n';
  //       }
  //     }
  //   }
  //
  //   await _saveFile(csvData, 'csv');
  // }
  //
  // Future<void> _generateAndSaveXML(Map<String, dynamic> reportData) async {
  //   final builder = xml.XmlBuilder();
  //   builder.processing('xml', 'version="1.0"');
  //   builder.element('Report', nest: () {
  //     final reportList = reportData['data']['reportData'] as List<dynamic>;
  //
  //     for (var zone in reportList) {
  //       builder.element('Zone', nest: () {
  //         builder.element('zoneName', nest: zone['zoneName'] ?? 'Unknown Zone');
  //         for (var device in zone['devices'] ?? []) {
  //           builder.element('Device', nest: () {
  //             for (var product in device['products'] ?? []) {
  //               builder.element('Product', nest: () {
  //                 builder.element('departmentName', nest: product['departmentName'] ?? 'Unknown Department');
  //                 builder.element('upc', nest: product['upc'] ?? 'Unknown UPC');
  //                 builder.element('description', nest: product['description'] ?? 'No Description');
  //                 builder.element('totalQty', nest: product['totalQty']?.toString() ?? '0');
  //                 builder.element('totalRetail', nest: product['totalRetail']?.toString() ?? '0');
  //               });
  //             }
  //           });
  //         }
  //       });
  //     }
  //   });
  //
  //   final xmlData = builder.buildDocument().toString();
  //   await _saveFile(xmlData, 'xml');
  // }
  Future<void> _generateAndSaveCSV(Map<String, dynamic> reportData) async {
    String csvData = 'Zone#,Department Name,Total Qty,Total Retail\n'; // CSV Header

    final reportList = reportData['data']['reportData'] as List<dynamic>;

    for (var zone in reportList) {
      for (var device in zone['devices']) {
        for (var product in device['products']) {
          csvData +=
          '${zone['zoneName'] ?? ''}, '
              '${product['departmentName'] ?? ''}, '
              '${product['totalQty']?.toString() ?? '0'},'
              '${(product['totalRetail'] as num?)?.toStringAsFixed(2) ?? '0.00'}\n';
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
                  builder.element('totalQty', nest: product['totalQty']?.toString() ?? '0');
                  builder.element('totalRetail', nest: (product['totalRetail'] as num?)?.toStringAsFixed(2) ?? '0.00');
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
        title: Text('Detailed Zone General Report'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label for report type selection
            Text(
              'Select Report Type',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            // Dropdown to select report type
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButton<String>(
                value: _selectedReportType,
                isExpanded: true,
                hint: Text('Select Report Type', style: TextStyle(color: Colors.grey)),
                items: <String>['daily', 'weekly', 'monthly']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.capitalizeFirstOfEach()),
                  );
                }).toList(),
                onChanged: _onReportTypeChanged,
                style: TextStyle(fontSize: 16, color: Colors.black),
                dropdownColor: Colors.white,
                underline: Container(
                  height: 2,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _reportData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('No report found'));
                  } else if (!snapshot.hasData || snapshot.data?['data']['reportData'].isEmpty) {
                    return Center(child: Text('No data available for selected report type.'));
                  } else {
                    final reportData = snapshot.data!['data'] ?? [];
                    List<dynamic> reportList = (reportData['reportData'] as List<dynamic>?) ?? [];

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: reportList.map<Widget>((zone) {
                          final zoneName = zone['zoneName'] ?? 'N/A';
                          final devices = zone['devices'] as List<dynamic>? ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Zone#: $zoneName', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ...devices.map<Widget>((device) {
                                final products = device['products'] as List<dynamic>? ?? [];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: products.map<Widget>((product) {
                                    final departmentName = product['departmentName'] ?? 'N/A';
                                    final totalQty = product['totalQty']?.toString() ?? '0';
                                    final totalRetail = (product['totalRetail'] as num?)?.toStringAsFixed(2) ?? '0.00';

                                    Color cardColor = products.indexOf(product) % 2 == 0 ? Colors.blueAccent[100]! : Colors.lightBlueAccent[200]!;

                                    return Container(
                                      width: double.infinity,
                                      margin: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Card(
                                        color: cardColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16.0),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Department: $departmentName',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              SizedBox(height: 8.0),
                                              Text(
                                                'Total Quantity: $totalQty',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              SizedBox(height: 4.0),
                                              Text(
                                                'Total Retail: \$${totalRetail}',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              }).toList(),
                              SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
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

// Extension to capitalize the first letter of each word
extension StringCasingExtension on String {
  String capitalizeFirstOfEach() {
    return this.split(' ').map((str) => str[0].toUpperCase() + str.substring(1)).join(' ');
  }
}