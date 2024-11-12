import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class ScanTiming extends StatefulWidget {
  @override
  _SessionDataState createState() => _SessionDataState();
}

class _SessionDataState extends State<ScanTiming> {
  List<dynamic> _sessions = [];
  final box = GetStorage();
  String? selectedDeviceId;
  String? token;
  bool isLoading = true;
  String sortOption = 'None'; // Default sorting option

  // Default dates
  DateTime fromDate = DateTime(2024, 9, 10);
  DateTime toDate = DateTime.now(); // Set toDate to today’s date by default

  @override
  void initState() {
    super.initState();
    selectedDeviceId = box.read('selectedDeviceId');
    token = box.read('token');
    print("selected device id $selectedDeviceId");
    _fetchSessionData();
  }

  Future<void> _fetchSessionData() async {
    setState(() {
      isLoading = true; // Show loader while fetching data
    });

    if (token == null || token!.isEmpty) {
      // Redirect to login if token is missing
      Navigator.pushReplacementNamed(context, '/login');
      return; // Exit the function early
    }

    try {
      // Format the dates to 'yyyy-MM-dd'
      String formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
      String formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);

      // Construct the URL with selected dates and deviceId
      final url = Uri.parse(
        'https://iscandata.com/api/v1/sessions/?fromDate=$formattedFromDate&toDate=$formattedToDate&deviceId=$selectedDeviceId',
      );

      // Set headers, including the Authorization header with the JWT token
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data");

        setState(() {
          _sessions = data['sessions'];
          _sortSessions(); // Sort sessions based on selected option
        });
      } else {
        throw Exception('Failed to load sessions');
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false; // Hide loader after data fetching
      });
    }
  }

  String _calculateTotalTime(String startTime, String endTime) {
    DateTime start = DateTime.parse(startTime);
    DateTime end = DateTime.parse(endTime);
    Duration difference = end.difference(start);

    return '${difference.inMinutes} min, ${difference.inSeconds.remainder(60)} sec';
  }

  int _getTotalTimeInSeconds(String startTime, String endTime) {
    DateTime start = DateTime.parse(startTime);
    DateTime end = DateTime.parse(endTime);
    return end.difference(start).inSeconds;
  }

  void _sortSessions() {
    if (sortOption == 'Max Time') {
      _sessions.sort((a, b) {
        int timeA = _getTotalTimeInSeconds(a['startScanTime'], a['endScanTime']);
        int timeB = _getTotalTimeInSeconds(b['startScanTime'], b['endScanTime']);
        return timeB.compareTo(timeA); // Descending order (Max Time)
      });
    } else if (sortOption == 'Min Time') {
      _sessions.sort((a, b) {
        int timeA = _getTotalTimeInSeconds(a['startScanTime'], a['endScanTime']);
        int timeB = _getTotalTimeInSeconds(b['startScanTime'], b['endScanTime']);
        return timeA.compareTo(timeB); // Ascending order (Min Time)
      });
    }
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fromDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != fromDate) {
      setState(() {
        fromDate = picked;
        _fetchSessionData(); // Fetch data with new fromDate
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: toDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != toDate) {
      setState(() {
        toDate = picked;
        _fetchSessionData(); // Fetch data with new toDate
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Session Data', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loader when data is loading
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _selectFromDate(context),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: 8),
                      Text('From: ${DateFormat('yyyy-MM-dd').format(fromDate)}'),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _selectToDate(context),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: 8),
                      Text('To: ${DateFormat('yyyy-MM-dd').format(toDate)}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Sort By: "),
                DropdownButton<String>(
                  value: sortOption,
                  items: [
                    DropdownMenuItem(value: 'None', child: Text('None')),
                    DropdownMenuItem(value: 'Max Time', child: Text('Max Time')),
                    DropdownMenuItem(value: 'Min Time', child: Text('Min Time')),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      sortOption = newValue!;
                      _sortSessions(); // Re-sort the sessions
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _sessions.isEmpty
                ? Center(child: Text('No session found for selecting dates'))
                : ListView.builder(
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                var session = _sessions[index];
                var startScanTime = DateFormat('yyyy-MM-dd HH:mm:ss')
                    .format(DateTime.parse(session['startScanTime']));
                var endScanTime = DateFormat('yyyy-MM-dd HH:mm:ss')
                    .format(DateTime.parse(session['endScanTime']));
                var totalTime = _calculateTotalTime(
                    session['startScanTime'], session['endScanTime']);

                Color rowColor = index.isEven ? Colors.blue[100]! : Colors.blue[200]!;

                return Card(
                  elevation: 5,
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device: ${session['device']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Table(
                          border: TableBorder.all(),
                          columnWidths: const {
                            0: FlexColumnWidth(),
                            1: FlexColumnWidth(),
                            2: FlexColumnWidth(),
                          },
                          children: [
                            TableRow(children: [
                              Container(
                                color: Colors.blue[100],
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Start Scan Time',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                color: Colors.blue[100],
                                padding: const EdgeInsets.all(8.0),
                                child: Text('End Scan Time',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                color: Colors.blue[100],
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Total Time Taken',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ]),
                            TableRow(children: [
                              Container(
                                color: rowColor,
                                padding: const EdgeInsets.all(8.0),
                                child: Text(startScanTime),
                              ),
                              Container(
                                color: rowColor,
                                padding: const EdgeInsets.all(8.0),
                                child: Text(endScanTime),
                              ),
                              Container(
                                color: rowColor,
                                padding: const EdgeInsets.all(8.0),
                                child: Text(totalTime),
                              ),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
