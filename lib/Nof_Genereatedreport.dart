//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:get_storage/get_storage.dart';
//
// Future<Map<String, dynamic>> fetchReportData(String startDateTime, String endDateTime, String token) async {
//   final url = 'https://iscandata.com/api/v1/reports/generate-nof-report?startDate=$startDateTime&endDate=$endDateTime&reportType=custom';
//   final response = await http.get(
//     Uri.parse(url),
//     headers: {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token',
//     },
//   );
//
//   if (response.statusCode == 200) {
//     final responseData = json.decode(response.body);
//     return responseData;
//   } else {
//     throw Exception('Failed to load report data: ${response.body}');
//   }
// }
//
// class Nof_ReportPage extends StatefulWidget {
//   @override
//   _NofReportPageState createState() => _NofReportPageState();
// }
//
// class _NofReportPageState extends State<Nof_ReportPage> {
//   late Future<Map<String, dynamic>> _reportData;
//   final storage = GetStorage();
//   DateTimeRange? _selectedDateRange;
//   final _startDateController = TextEditingController();
//   final _endDateController = TextEditingController();
//   final _searchController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     DateTime now = DateTime.now();
//     DateTime startDate = now.subtract(Duration(days: 20));
//     _startDateController.text = '${startDate.toLocal()}'.split(' ')[0];
//     _endDateController.text = '${now.toLocal()}'.split(' ')[0];
//     String token = storage.read('token') ?? '';
//     _reportData = fetchReportData(
//       '${_startDateController.text}T00:00:00',
//       '${_endDateController.text}T23:59:59',
//       token,
//     );
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
//         _startDateController.text = "${picked.start.toLocal().toString().split(' ')[0]}";
//         _endDateController.text = "${picked.end.toLocal().toString().split(' ')[0]}";
//         _updateReportData();
//       });
//     }
//   }
//
//   void _updateReportData() {
//     String token = storage.read('token') ?? '';
//     setState(() {
//       _reportData = fetchReportData(
//         '${_startDateController.text}T00:00:00',
//         '${_endDateController.text}T23:59:59',
//         token,
//       );
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('N.O.F. Report'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildDateTimePicker(context, 'Start Date', _startDateController, _selectDateTimeRange),
//             SizedBox(height: 8),
//             _buildDateTimePicker(context, 'End Date', _endDateController, _selectDateTimeRange),
//             SizedBox(height: 16),
//             _buildSearchBar(),
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
//                     final formattedReport = reportData['formattedReport'] as List<dynamic>? ?? [];
//
//                     // Filter reports based on the search query
//                     final searchQuery = _searchController.text.toLowerCase();
//                     final reportsToDisplay = formattedReport.where((product) {
//                       final deptName = product['deptName']?.toLowerCase() ?? '';
//                       return deptName.contains(searchQuery);
//                     }).toList();
//
//                     return ListView(
//                       children: reportsToDisplay.map<Widget>((report) {
//                         return _buildReportCard(report);
//                       }).toList(),
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
//   Widget _buildDateTimePicker(BuildContext context, String label, TextEditingController controller, Future<void> Function(BuildContext) onTap) {
//     return Card(
//       child: ListTile(
//         title: TextField(
//           controller: controller,
//           decoration: InputDecoration(
//             labelText: label,
//             suffixIcon: IconButton(
//               icon: Icon(Icons.calendar_today),
//               onPressed: () => onTap(context),
//             ),
//           ),
//           readOnly: true,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSearchBar() {
//     return Card(
//       child: TextField(
//         controller: _searchController,
//         decoration: InputDecoration(
//           labelText: 'Search by Department',
//           prefixIcon: Icon(Icons.search),
//           border: OutlineInputBorder(),
//         ),
//         onChanged: (value) {
//           setState(() {
//             // Update the UI to reflect the search
//           });
//         },
//       ),
//     );
//   }
//
//   Widget _buildReportCard(Map<String, dynamic> report) {
//     final deptName = report['deptName'] ?? '';
//     final products = report['products'] as List<dynamic>? ?? [];
//
//     return Card(
//       child: ListTile(
//         title: Text("Dept: $deptName"),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: products.map<Widget>((product) {
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('UPC: ${product['upc']}'),
//                 Text('Qty: ${product['totalQty']}'),
//                 Text('Retail: \$${product['retailPrice']}'),
//                 Text('Total Retail: \$${product['totalRetail']}'),
//                 SizedBox(height: 8),
//               ],
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/widgets.dart';

Future<Map<String, dynamic>> fetchReportData(String startDateTime, String endDateTime, String token) async {
  final url = 'https://iscandata.com/api/v1/reports/generate-nof-report?startDate=$startDateTime&endDate=$endDateTime&reportType=custom';
  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final responseData = json.decode(response.body);
    return responseData;
  } else if (response.statusCode == 401) {
    // Handle blacklisted token
    throw Exception('Token is blacklisted');
  } else {
    throw Exception('Failed to load report data: ${response.body}');
  }
}

class Nof_ReportPage extends StatefulWidget {
  @override
  _NofReportPageState createState() => _NofReportPageState();
}

class _NofReportPageState extends State<Nof_ReportPage> {
  late Future<Map<String, dynamic>> _reportData;
  final storage = GetStorage();
  DateTimeRange? _selectedDateRange;
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    DateTime startDate = now.subtract(Duration(days: 20));
    _startDateController.text = '${startDate.toLocal()}'.split(' ')[0];
    _endDateController.text = '${now.toLocal()}'.split(' ')[0];
    String token = storage.read('token') ?? '';
    _reportData = fetchReportData(
      '${_startDateController.text}T00:00:00',
      '${_endDateController.text}T23:59:59',
      token,
    ).catchError((error) {
      if (error.toString() == 'Exception: Token is blacklisted') {
        // Redirect to login page if the token is blacklisted
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
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
        _startDateController.text = "${picked.start.toLocal().toString().split(' ')[0]}";
        _endDateController.text = "${picked.end.toLocal().toString().split(' ')[0]}";
        _updateReportData();
      });
    }
  }

  void _updateReportData() {
    String token = storage.read('token') ?? '';
    setState(() {
      _reportData = fetchReportData(
        '${_startDateController.text}T00:00:00',
        '${_endDateController.text}T23:59:59',
        token,
      ).catchError((error) {
        if (error.toString() == 'Exception: Token is blacklisted') {
          // Redirect to login page if the token is blacklisted
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('N.O.F. Report', style:TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateTimePicker(context, 'Start Date', _startDateController, _selectDateTimeRange),
            SizedBox(height: 8),
            _buildDateTimePicker(context, 'End Date', _endDateController, _selectDateTimeRange),
            SizedBox(height: 16),
            _buildSearchBar(),
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
                    return Center(child: Text('No data available'));
                  } else {
                    final reportData = snapshot.data!['data'];
                    final formattedReport = reportData['formattedReport'] as List<dynamic>? ?? [];

                    // Filter reports based on the search query
                    final searchQuery = _searchController.text.toLowerCase();
                    final reportsToDisplay = formattedReport.where((product) {
                      final deptName = product['deptName']?.toLowerCase() ?? '';
                      return deptName.contains(searchQuery);
                    }).toList();

                    return ListView(
                      children: reportsToDisplay.map<Widget>((report) {
                        return _buildReportCard(report);
                      }).toList(),
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

  Widget _buildDateTimePicker(BuildContext context, String label, TextEditingController controller, Future<void> Function(BuildContext) onTap) {
    return Card(
      child: ListTile(
        title: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () => onTap(context),
            ),
          ),
          readOnly: true,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Card(
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search by Department',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() {
            // Update the UI to reflect the search
          });
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final deptName = report['deptName'] ?? '';
    final products = report['products'] as List<dynamic>? ?? [];

    return Card(
      child: ListTile(
        title: Text("Dept: $deptName"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: products.map<Widget>((product) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UPC: ${product['upc']}'),
                Text('Qty: ${product['totalQty']}'),
                Text('Retail: \$${product['retailPrice']}'),
                Text('Total Retail: \$${product['totalRetail']}'),
                SizedBox(height: 8),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
