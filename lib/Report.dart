//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:get_storage/get_storage.dart';
// import 'package:intl/intl.dart'; // For date formatting
//
// Future<Map<String, dynamic>> fetchReportData(String startDateTime, String endDateTime, String token) async {
//   final url = 'https://iscandata.com/api/v1/reports/generate-report?startDate=$startDateTime&endDate=$endDateTime&reportType=custom';
//
//   try {
//     final response = await http.get(
//       Uri.parse(url),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//     );
//
//     print('Request URL: $url');
//     print('Response Status: ${response.statusCode}');
//     print('Response Body: ${response.body}');
//
//     if (response.statusCode == 200) {
//       return json.decode(response.body);
//     } else {
//       final errorData = json.decode(response.body);
//       print('Error details: ${errorData['error']}');
//       throw Exception('Failed to load report data: ${errorData['message']}');
//     }
//   } catch (error) {
//     print('Fetch error: $error');
//     throw error;
//   }
// }
//
// class ReportPage extends StatefulWidget {
//   @override
//   _ReportPageState createState() => _ReportPageState();
// }
//
// class _ReportPageState extends State<ReportPage> {
//   late Future<Map<String, dynamic>> _reportData;
//   final storage = GetStorage();
//   DateTimeRange? _selectedDateRange;
//   TimeOfDay? _selectedStartTime;
//   TimeOfDay? _selectedEndTime;
//   final _startDateController = TextEditingController();
//   final _endDateController = TextEditingController();
//   final _startTimeController = TextEditingController();
//   final _endTimeController = TextEditingController();
//   final _searchController = TextEditingController();
//   List<dynamic> _filteredReportList = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeDateControllers();
//     _searchController.addListener(_filterReports);
//
//     _updateReportData(); // Automatically fetch the report when the page loads
//   }
//
//   void _initializeDateControllers() {
//     // Calculate the default date range: from 20 days ago to today
//     final today = DateTime.now();
//     final twentyDaysAgo = today.subtract(Duration(days: 20));
//
//     // Format the dates
//     final dateFormat = DateFormat('yyyy-MM-dd');
//     _startDateController.text = dateFormat.format(twentyDaysAgo);
//     _endDateController.text = dateFormat.format(today);
//
//     // Default time: 00:00 to 23:59
//     _startTimeController.text = '00:00';
//     _endTimeController.text = '23:59';
//   }
//
//   void _updateReportData() {
//     String token = storage.read('token') ?? '';
//
//     final startDateTime = '${_startDateController.text}T${_startTimeController.text}:00';
//     final endDateTime = '${_endDateController.text}T${_endTimeController.text}:00';
//
//     print('Start DateTime: $startDateTime');
//     print('End DateTime: $endDateTime');
//
//     setState(() {
//       _reportData = fetchReportData(
//         startDateTime,
//         endDateTime,
//         token,
//       );
//     });
//   }
//
//   void _filterReports() {
//     final query = _searchController.text.toLowerCase();
//     setState(() {
//       _filteredReportList = _filteredReportList.where((report) {
//         final deptName = (report['departmentName'] as String).toLowerCase();
//         return deptName.contains(query);
//       }).toList();
//     });
//   }
//
//   Future<void> _selectDateTimeRange(BuildContext context) async {
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime.now().subtract(Duration(days: 30)),
//       lastDate: DateTime.now(),
//       initialDateRange: _selectedDateRange,
//     );
//
//     if (picked != null) {
//       setState(() {
//         _selectedDateRange = picked;
//         _startDateController.text = picked.start.toIso8601String().split('T')[0];
//         _endDateController.text = picked.end.toIso8601String().split('T')[0];
//       });
//     }
//   }
//
//   Future<void> _selectStartTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedStartTime ?? TimeOfDay.now(),
//     );
//
//     if (picked != null) {
//       setState(() {
//         _selectedStartTime = picked;
//         _startTimeController.text = picked.format(context);
//       });
//     }
//   }
//
//   Future<void> _selectEndTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedEndTime ?? TimeOfDay.now(),
//     );
//
//     if (picked != null) {
//       setState(() {
//         _selectedEndTime = picked;
//         _endTimeController.text = picked.format(context);
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Reports'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               controller: _startDateController,
//               decoration: InputDecoration(
//                 labelText: 'Start Date',
//                 suffixIcon: IconButton(
//                   icon: Icon(Icons.calendar_today),
//                   onPressed: () => _selectDateTimeRange(context),
//                 ),
//               ),
//               readOnly: true,
//             ),
//             SizedBox(height: 8),
//             TextField(
//               controller: _endDateController,
//               decoration: InputDecoration(
//                 labelText: 'End Date',
//                 suffixIcon: IconButton(
//                   icon: Icon(Icons.calendar_today),
//                   onPressed: () => _selectDateTimeRange(context),
//                 ),
//               ),
//               readOnly: true,
//             ),
//             SizedBox(height: 8),
//             TextField(
//               controller: _startTimeController,
//               decoration: InputDecoration(
//                 labelText: 'Start Time',
//                 suffixIcon: IconButton(
//                   icon: Icon(Icons.access_time),
//                   onPressed: () => _selectStartTime(context),
//                 ),
//               ),
//               readOnly: true,
//             ),
//             SizedBox(height: 8),
//             TextField(
//               controller: _endTimeController,
//               decoration: InputDecoration(
//                 labelText: 'End Time',
//                 suffixIcon: IconButton(
//                   icon: Icon(Icons.access_time),
//                   onPressed: () => _selectEndTime(context),
//                 ),
//               ),
//               readOnly: true,
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 labelText: 'Search Department Name',
//                 prefixIcon: Icon(Icons.search),
//               ),
//             ),
//             SizedBox(height: 16),
//             Expanded(
//               child: FutureBuilder<Map<String, dynamic>>(
//                 future: _reportData,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return Center(child: CircularProgressIndicator());
//                   } else if (snapshot.hasError) {
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   } else if (!snapshot.hasData || snapshot.data?['status'] != 'success') {
//                     return Center(child: Text('No data available'));
//                   } else {
//                     final reportData = snapshot.data!['data'];
//                     if (reportData == null || reportData['reportData'] == null) {
//                       return Center(child: Text('No report data available'));
//                     }
//                     final reportList = reportData['reportData'] as List<dynamic>;
//
//                     final cards = <Widget>[];
//
//                     for (var zone in reportList) {
//                       for (var device in zone['devices']) {
//                         for (var product in device['products']) {
//                           cards.add(
//                             Card(
//                               elevation: 4,
//                               margin: EdgeInsets.symmetric(vertical: 4),
//                               color: Colors.blue[300],
//                               child: ListTile(
//                                 title: Container(
//                                   padding: EdgeInsets.all(8.0),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         'Department Name: ${product['departmentName']}',
//                                         style: TextStyle(
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.black,
//                                         ),
//                                       ),
//                                       SizedBox(height: 5),
//                                       Text(
//                                         'Zone Name: ${zone['zoneName']}',
//                                         style: TextStyle(
//                                           fontSize: 14,
//                                           color: Colors.black87,
//                                         ),
//                                       ),
//                                       SizedBox(height: 5),
//                                       Text(
//                                         'Zone Description: ${zone['zoneDescription']}',
//                                         style: TextStyle(
//                                           fontSize: 14,
//                                           color: Colors.black54,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 subtitle: Padding(
//                                   padding: const EdgeInsets.all(8.0),
//                                   child: Text(
//                                     'UPC: ${product['upc']}',
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       color: Colors.black,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           );
//                         }
//                       }
//                     }
//
//                     return ListView(children: cards);
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
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart'; // For date formatting

Future<Map<String, dynamic>> fetchReportData(String startDateTime, String endDateTime, String token, BuildContext context) async {
  final url = 'https://iscandata.com/api/v1/reports/generate-report?startDate=$startDateTime&endDate=$endDateTime&reportType=custom';

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('Request URL: $url');
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Token blacklisted, navigate to login page
      Navigator.pushReplacementNamed(context, '/login');
      throw Exception('Token blacklisted, navigating to login page.');
    } else {
      final errorData = json.decode(response.body);
      print('Error details: ${errorData['error']}');
      throw Exception('Failed to load report data: ${errorData['message']}');
    }
  } catch (error) {
    print('Fetch error: $error');
    throw error;
  }
}

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late Future<Map<String, dynamic>> _reportData;
  final storage = GetStorage();
  DateTimeRange? _selectedDateRange;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _searchController = TextEditingController();
  List<dynamic> _filteredReportList = [];

  @override
  void initState() {
    super.initState();
    _initializeDateControllers();
    _searchController.addListener(_filterReports);

    _updateReportData(); // Automatically fetch the report when the page loads
  }

  void _initializeDateControllers() {
    final today = DateTime.now();
    final twentyDaysAgo = today.subtract(Duration(days: 20));
    final dateFormat = DateFormat('yyyy-MM-dd');
    _startDateController.text = dateFormat.format(twentyDaysAgo);
    _endDateController.text = dateFormat.format(today);
    _startTimeController.text = '00:00';
    _endTimeController.text = '23:59';
  }

  void _updateReportData() {
    String token = storage.read('token') ?? '';

    final startDateTime = '${_startDateController.text}T${_startTimeController.text}:00';
    final endDateTime = '${_endDateController.text}T${_endTimeController.text}:00';

    print('Start DateTime: $startDateTime');
    print('End DateTime: $endDateTime');

    setState(() {
      _reportData = fetchReportData(startDateTime, endDateTime, token, context);
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

  Future<void> _selectDateTimeRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 30)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _startDateController.text = picked.start.toIso8601String().split('T')[0];
        _endDateController.text = picked.end.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedStartTime = picked;
        _startTimeController.text = picked.format(context);
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedEndTime = picked;
        _endTimeController.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports',style:TextStyle(color: Colors.white)),
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
                labelText: 'Search Department Name',
                prefixIcon: Icon(Icons.search),
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
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data?['status'] != 'success') {
                    return Center(child: Text('No data available for selected date.'));
                  } else {
                    final reportData = snapshot.data!['data'];
                    if (reportData == null || reportData['reportData'] == null) {
                      return Center(child: Text('No report data available'));
                    }
                    final reportList = reportData['reportData'] as List<dynamic>;

                    final cards = <Widget>[];

                    for (var zone in reportList) {
                      for (var device in zone['devices']) {
                        for (var product in device['products']) {
                          cards.add(
                            Card(
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
                                      SizedBox(height: 5),
                                      Text(
                                        'Zone Name: ${zone['zoneName']}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        'Device Name: ${device['deviceName']}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        'Product Name: ${product['productName']}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      }
                    }

                    return ListView(children: cards);
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
