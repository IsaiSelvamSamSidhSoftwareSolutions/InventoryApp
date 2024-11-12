import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:get_storage/get_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart' as xml;

class  Nof_ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<Nof_ReportPage> {
  late Future<Map<String, dynamic>?> _reportData;
  final storage = GetStorage();
  String _selectedReportType = 'daily';
  final _searchController = TextEditingController();
  List<dynamic> _filteredReportList = [];
  String? _downloadPath;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterReports);
    _downloadPath = storage.read('downloadPath'); // Read cached download path
    _updateReportData();
  }

  Future<Map<String, dynamic>?> fetchReportData(String reportType, String token, BuildContext context) async {
    // Check if the user role is admin
    String userRole = storage.read('userRole') ?? ''; // Assuming userRole is stored in GetStorage
    final url = 'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType${userRole == 'admin' && _userId != null ? '&userId=$_userId' : ''}';

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
              labelText: 'User  ID',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _userId = userIdController.text; // Set the userId
                  _updateReportData(); // Fetch report data with new userId
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
  void _updateReportData() async {
    String token = storage.read('token') ?? '';
    // Fetch report data
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
              '${product['totalQty']?.toString() ?? ' 0'}\n';
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
                    // Check user role
                    String userRole = storage.read('userRole') ?? '';
                    if (userRole == 'admin') {
                      // Trigger the dialog to get userId
                      _showUserIdDialog(_selectedReportType);
                    } else {
                      // Fetch report data without userId
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