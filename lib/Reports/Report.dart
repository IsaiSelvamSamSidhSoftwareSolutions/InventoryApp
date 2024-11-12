import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:get_storage/get_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart' as xml;

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late Future<Map<String, dynamic>?> _reportData;
  final storage = GetStorage();
  String _selectedReportType = 'daily';
  final _searchController = TextEditingController();
  List<dynamic> _filteredReportList = [];
  String? _downloadPath;
  String? _userId;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterReports);
    _downloadPath = storage.read('downloadPath'); // Read cached download path
    _userRole = storage.read('userRole') ?? ''; // Get user role from storage
    _updateReportData();
  }

  Future<Map<String, dynamic>?> fetchReportData(String reportType, String token, BuildContext context) async {
    final url = 'https://iscandata.com/api/v1/reports/generate-report?reportType=$reportType${_userRole == 'admin' && _userId != null ? '&userId=$_userId' : ''}';

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

  void _updateReportData() async {
    String token = storage.read('token') ?? '';
    setState(() {
      _reportData = fetchReportData(_selectedReportType, token, context);
    });
  }

  void _showUserIdDialog() {
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
                setState(() {
                  _userId = userIdController.text; // Set the userId
                  _updateReportData(); // Fetch report data with new userId
                });
                Navigator.of(context).pop();
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

  void _onReportTypeChanged(String? newValue) {
    setState(() {
      _selectedReportType = newValue!;
      if (_userRole == 'admin') {
        _showUserIdDialog(); // Show User ID dialog for admin users
      } else {
        _updateReportData(); // Fetch report data directly for non-admin users
      }
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
                onChanged: _onReportTypeChanged,
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
    );
  }
}
