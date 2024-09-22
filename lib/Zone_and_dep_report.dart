// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:get_storage/get_storage.dart';
// import 'package:intl/intl.dart'; // For date formatting
//
// Future<Map<String, dynamic>> fetchReportData(String startDateTime, String endDateTime, String token) async {
//   final url =
//       'https://iscandata.com/api/v1/reports/generate-report?startDate=$startDateTime&endDate=$endDateTime&reportType=custom';
//   final response = await http.get(
//     Uri.parse(url),
//     headers: {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token',
//     },
//   );
//
//   if (response.statusCode == 200) {
//     return json.decode(response.body);
//   } else {
//     throw Exception('Failed to load report data');
//   }
// }
//
// class DetailedZoneReportPage extends StatefulWidget {
//   @override
//   _ReportPageState createState() => _ReportPageState();
// }
//
// class _ReportPageState extends State<DetailedZoneReportPage> {
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
//
//   List<dynamic> _filteredReportList = [];
//   List<dynamic> _reportList = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _startDateController.text = '2024-09-01'; // default start date
//     _endDateController.text = '2024-09-17'; // default end date
//     _startTimeController.text = '00:00'; // default start time
//     _endTimeController.text = '23:59'; // default end time
//     _searchController.addListener(_filterSearchResults);
//     _fetchReportData();
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _fetchReportData() async {
//     try {
//       String token = storage.read('token') ?? '';
//       _reportData = fetchReportData(
//         '${_startDateController.text}T${_startTimeController.text}:00',
//         '${_endDateController.text}T${_endTimeController.text}:00',
//         token,
//       );
//
//       _reportData.then((data) {
//         setState(() {
//           _reportList = data['data']['reportData'] ?? [];
//           _filteredReportList = _reportList; // Initialize with all data
//         });
//       });
//     } catch (e) {
//       print('Error fetching report data: $e');
//     }
//   }
//
//   Future<void> _selectDateTimeRange(BuildContext context) async {
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//       initialDateRange: _selectedDateRange,
//     );
//
//     if (picked != null && picked != _selectedDateRange) {
//       setState(() {
//         _selectedDateRange = picked;
//         _startDateController.text = DateFormat('yyyy-MM-dd').format(picked.start);
//         _endDateController.text = DateFormat('yyyy-MM-dd').format(picked.end);
//         _selectedStartTime = TimeOfDay(hour: 0, minute: 0);
//         _selectedEndTime = TimeOfDay(hour: 23, minute: 59);
//         _startTimeController.text = '00:00';
//         _endTimeController.text = '23:59';
//       });
//       _fetchReportData(); // Fetch data after date range selection
//     }
//   }
//
//   Future<void> _selectStartTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedStartTime ?? TimeOfDay(hour: 0, minute: 0),
//     );
//
//     if (picked != null && picked != _selectedStartTime) {
//       setState(() {
//         _selectedStartTime = picked;
//         _startTimeController.text = _selectedStartTime!.format(context);
//       });
//       _fetchReportData(); // Fetch data after start time selection
//     }
//   }
//
//   Future<void> _selectEndTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedEndTime ?? TimeOfDay(hour: 23, minute: 59),
//     );
//
//     if (picked != null && picked != _selectedEndTime) {
//       setState(() {
//         _selectedEndTime = picked;
//         _endTimeController.text = _selectedEndTime!.format(context);
//       });
//       _fetchReportData(); // Fetch data after end time selection
//     }
//   }
//
//   void _filterSearchResults() {
//     final query = _searchController.text.toLowerCase();
//
//     setState(() {
//       _filteredReportList = _reportList.where((zone) {
//         final zoneName = zone['zoneName']?.toString().toLowerCase() ?? '';
//         return zoneName.contains(query);
//       }).toList();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Detailed Zone General Report'),
//         backgroundColor: Colors.lightBlueAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildDatePicker(context, 'Start Date', _startDateController, _selectDateTimeRange),
//             SizedBox(height: 8),
//             _buildDatePicker(context, 'End Date', _endDateController, _selectDateTimeRange),
//             SizedBox(height: 8),
//             _buildTimePicker(context, 'Start Time', _startTimeController, _selectStartTime),
//             SizedBox(height: 8),
//             _buildTimePicker(context, 'End Time', _endTimeController, _selectEndTime),
//             SizedBox(height: 16),
//             Text(
//               'REPORT GENERATED ON: ${DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now())}'
//                   '\nSelected Range: From ${_startDateController.text} ${_startTimeController.text} - To ${_endDateController.text} ${_endTimeController.text}',
//               style: TextStyle(fontSize: 16, color: Colors.blueAccent),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 labelText: 'Search by Zone Name',
//                 border: OutlineInputBorder(),
//                 suffixIcon: Icon(Icons.search),
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
//                     final reportData = snapshot.data!['data'] ?? [];
//                     List<dynamic> reportList = (reportData['reportData'] as List<dynamic>?) ?? [];
//
//                     return SingleChildScrollView(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: reportList.map<Widget>((zone) {
//                           final zoneName = zone['zoneName'] ?? 'N/A';
//                           final devices = zone['devices'] as List<dynamic>? ?? [];
//
//                           return Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text('Zone#: $zoneName', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                               ...devices.map<Widget>((device) {
//                                 final products = device['products'] as List<dynamic>? ?? [];
//                                 return Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: products.map<Widget>((product) {
//                                     final departmentName = product['departmentName'] ?? 'N/A';
//                                     final totalQty = product['totalQty']?.toString() ?? '0';
//                                     final totalRetail = (product['totalRetail'] as num?)?.toStringAsFixed(2) ?? '0.00';
//
//                                     return Card(
//                                       margin: EdgeInsets.symmetric(vertical: 8.0),
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(8.0),
//                                         child: Column(
//                                           crossAxisAlignment: CrossAxisAlignment.start,
//                                           children: [
//                                             Text('Department: $departmentName', style: TextStyle(fontWeight: FontWeight.bold)),
//                                             Text('Qty: $totalQty'),
//                                             Text('Total Retail: \$${totalRetail}'),
//                                           ],
//                                         ),
//                                       ),
//                                     );
//                                   }).toList(),
//                                 );
//                               }).toList(),
//                               Divider(),
//                             ],
//                           );
//                         }).toList(),
//                       ),
//                     );
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDatePicker(BuildContext context, String label, TextEditingController controller, Function onTap) {
//     return GestureDetector(
//       onTap: () => onTap(context),
//       child: AbsorbPointer(
//         child: TextField(
//           controller: controller,
//           decoration: InputDecoration(
//             labelText: label,
//             border: OutlineInputBorder(),
//             suffixIcon: Icon(Icons.calendar_today),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTimePicker(BuildContext context, String label, TextEditingController controller, Function onTap) {
//     return GestureDetector(
//       onTap: () => onTap(context),
//       child: AbsorbPointer(
//         child: TextField(
//           controller: controller,
//           decoration: InputDecoration(
//             labelText: label,
//             border: OutlineInputBorder(),
//             suffixIcon: Icon(Icons.access_time),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

Future<Map<String, dynamic>> fetchReportData(String startDateTime, String endDateTime, String token) async {
  final url =
      'https://iscandata.com/api/v1/reports/generate-report?startDate=$startDateTime&endDate=$endDateTime&reportType=custom';
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
    throw Exception('Unauthorized'); // Trigger 401 handling
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
  DateTimeRange? _selectedDateRange;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _searchController = TextEditingController();

  List<dynamic> _filteredReportList = [];
  List<dynamic> _reportList = [];

  @override
  void initState() {
    super.initState();
    _startDateController.text = '2024-09-01'; // default start date
    _endDateController.text = '2024-09-17'; // default end date
    _startTimeController.text = '00:00'; // default start time
    _endTimeController.text = '23:59'; // default end time
    _searchController.addListener(_filterSearchResults);
    _fetchReportData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReportData() async {
    try {
      String token = storage.read('token') ?? '';
      _reportData = fetchReportData(
        '${_startDateController.text}T${_startTimeController.text}:00',
        '${_endDateController.text}T${_endTimeController.text}:00',
        token,
      );

      _reportData.then((data) {
        setState(() {
          _reportList = data['data']['reportData'] ?? [];
          _filteredReportList = _reportList; // Initialize with all data
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
        _startDateController.text = DateFormat('yyyy-MM-dd').format(picked.start);
        _endDateController.text = DateFormat('yyyy-MM-dd').format(picked.end);
        _selectedStartTime = TimeOfDay(hour: 0, minute: 0);
        _selectedEndTime = TimeOfDay(hour: 23, minute: 59);
        _startTimeController.text = '00:00';
        _endTimeController.text = '23:59';
      });
      _fetchReportData(); // Fetch data after date range selection
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
      });
      _fetchReportData(); // Fetch data after start time selection
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
      });
      _fetchReportData(); // Fetch data after end time selection
    }
  }

  void _filterSearchResults() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredReportList = _reportList.where((zone) {
        final zoneName = zone['zoneName']?.toString().toLowerCase() ?? '';
        return zoneName.contains(query);
      }).toList();
    });
  }

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
            _buildDatePicker(context, 'Start Date', _startDateController, _selectDateTimeRange),
            SizedBox(height: 8),
            _buildDatePicker(context, 'End Date', _endDateController, _selectDateTimeRange),
            SizedBox(height: 8),
            _buildTimePicker(context, 'Start Time', _startTimeController, _selectStartTime),
            SizedBox(height: 8),
            _buildTimePicker(context, 'End Time', _endTimeController, _selectEndTime),
            SizedBox(height: 16),
            Text(
              'REPORT GENERATED ON: ${DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now())}'
                  '\nSelected Range: From ${_startDateController.text} ${_startTimeController.text} - To ${_endDateController.text} ${_endTimeController.text}',
              style: TextStyle(fontSize: 16, color: Colors.blueAccent),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Zone Name',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
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
                  } else if (!snapshot.hasData || snapshot.data?['data']['reportData'].isEmpty) {
                    return Center(child: Text('No data available for selected date.'));
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

                                    return Card(
                                      margin: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Department: $departmentName', style: TextStyle(fontWeight: FontWeight.bold)),
                                            Text('Total Quantity: $totalQty'),
                                            Text('Total Retail: \$${totalRetail}'),
                                          ],
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
    );
  }

  Widget _buildDatePicker(BuildContext context, String label, TextEditingController controller, Function onTap) {
    return GestureDetector(
      onTap: () => onTap(context),
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context, String label, TextEditingController controller, Function onTap) {
    return GestureDetector(
      onTap: () => onTap(context),
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.access_time),
          ),
        ),
      ),
    );
  }
}
