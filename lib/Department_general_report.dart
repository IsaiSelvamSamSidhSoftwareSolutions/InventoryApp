
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';

Future<Map<String, dynamic>?> fetchReportData(
    String startDateTime,
    String endDateTime,
    String token,
    ) async {
  final url =
      'https://iscandata.com/api/v1/reports/generate-report?startDate=$startDateTime&endDate=$endDateTime&reportType=custom';
  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  print('Response Status: ${response.statusCode}');
  print('Response Body: ${response.body}');

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    print('Failed to load report data');
    return null;
  }
}

class DepartmentGeneralReportPage extends StatefulWidget {
  @override
  _DepartmentGeneralReportPageState createState() => _DepartmentGeneralReportPageState();
}

class _DepartmentGeneralReportPageState extends State<DepartmentGeneralReportPage> {
  late Future<Map<String, dynamic>?> _reportData;
  final storage = GetStorage();
  DateTimeRange? _selectedDateRange;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _startDateController.text = '2024-09-4'; // default start date
    _endDateController.text = '2024-09-17'; // default end date
    _startTimeController.text = '00:00'; // default start time
    _endTimeController.text = '23:59'; // default end time
    String token = storage.read('token') ?? '';
    _reportData = fetchReportData(
      '${_startDateController.text}T${_startTimeController.text}:00',
      '${_endDateController.text}T${_endTimeController.text}:00',
      token,
    );
  }

  Future<void> _selectDateTimeRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
        _startDateController.text = picked.start.toLocal().toString().split(' ')[0];
        _endDateController.text = picked.end.toLocal().toString().split(' ')[0];
        _selectedStartTime = TimeOfDay(hour: 0, minute: 0);
        _selectedEndTime = TimeOfDay(hour: 23, minute: 59);
        _startTimeController.text = '00:00';
        _endTimeController.text = '23:59';

        _updateReportData();
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay(hour: 0, minute: 0),
    );

    if (picked != null && picked != _selectedStartTime) {
      setState(() {
        _selectedStartTime = picked;
        _startTimeController.text = _selectedStartTime!.format(context);
        _updateReportData();
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay(hour: 23, minute: 59),
    );

    if (picked != null && picked != _selectedEndTime) {
      setState(() {
        _selectedEndTime = picked;
        _endTimeController.text = _selectedEndTime!.format(context);
        _updateReportData();
      });
    }
  }

  void _updateReportData() {
    String token = storage.read('token') ?? '';
    _reportData = fetchReportData(
      '${_startDateController.text}T${_startTimeController.text}:00',
      '${_endDateController.text}T${_endTimeController.text}:00',
      token,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Department General' ,style:TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _startDateController,
              decoration: InputDecoration(
                labelText: 'Start Date',
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDateTimeRange(context),
                ),
              ),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              controller: _endDateController,
              decoration: InputDecoration(
                labelText: 'End Date',
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDateTimeRange(context),
                ),
              ),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              controller: _startTimeController,
              decoration: InputDecoration(
                labelText: 'Start Time',
                suffixIcon: IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: () => _selectStartTime(context),
                ),
              ),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              controller: _endTimeController,
              decoration: InputDecoration(
                labelText: 'End Time',
                suffixIcon: IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: () => _selectEndTime(context),
                ),
              ),
              readOnly: true,
            ),
            SizedBox(height: 16),
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
            SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _reportData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    print('Error: ${snapshot.error}');
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data?['status'] != 'success') {
                    return Center(child: Text('No data available'));
                  } else {
                    final reportData = snapshot.data!['data'];
                    final reportList = reportData['reportData'] as List<dynamic>? ?? [];
                    final overallTotals = reportData['overallTotals'] ?? {};

                    // Filter report data based on the search query
                    final filteredReportList = reportList.expand((zone) {
                      final devices = zone['devices'] as List<dynamic>? ?? [];
                      return devices.expand((device) {
                        final products = device['products'] as List<dynamic>? ?? [];
                        return products.where((product) {
                          final description = product['description']?.toLowerCase() ?? '';
                          final upc = product['upc']?.toLowerCase() ?? '';
                          return description.contains(_searchQuery) || upc.contains(_searchQuery);
                        }).toList();
                      }).toList();
                    }).toList();

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'REPORT GENERATED ON: ${DateTime.now().toLocal()}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...filteredReportList.map((product) {
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                title: Text('UPC#: ${product['upc'] ?? 'N/A'}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Department Name: ${product['departmentName'] ?? 'N/A'}'),
                                    Text('Description: ${product['description'] ?? 'N/A'}'),
                                    Text('Qty: ${product['totalQty']?.toString() ?? 'N/A'}'),
                                    Text('Total Retail: ${product['totalRetail']?.toString() ?? 'N/A'}'),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Overall Totals',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Card(
                            margin: EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              title: Text('Total Qty: ${overallTotals['totalQty']?.toString() ?? 'N/A'}'),
                              subtitle: Text('Total Retail: ${overallTotals['totalRetail']?.toString() ?? 'N/A'}'),
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
    );
  }
}

