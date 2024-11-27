
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart'; // Add this import
import 'Scanner.dart'; // Ensure this import path is correct
import 'package:inventary_app_production/ZonePage.dart';
import 'package:pdf/pdf.dart';
import 'package:xml/xml.dart' as xml;
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart'; // For temp directory access
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'Bluetoothscanner.dart';
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? startSessionID;

  Future<void> _startSession(BuildContext context) async {

    final _storage = GetStorage();
    final token = _storage.read('token') as String;

    try {
      final response = await http.post(
        Uri.parse('https://iscandata.com/api/v1/sessions/scan/start'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final responseBody = jsonDecode(response.body);
      print('Start Session Response: $responseBody');

      if (responseBody['status'] == 'success') {
        setState(() {
          startSessionID = responseBody['sessionId']; // Extract the sessionId correctly
        });
        print('Session ID: $startSessionID');

        // Navigate to ZoneSelectionScreen and pass the session ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ZoneSelectionScreen(sessionId: startSessionID!),
          ),
        );
      } else if (response.statusCode == 401) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pushReplacementNamed('/login');
        });
      } else {
        // Handle other status codes or errors
        print('Unexpected error: ${response.body}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Welcome to Store',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _startSession(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Start Inventory',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ZoneSelectionScreen extends StatefulWidget {
  final String sessionId;

  const ZoneSelectionScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  _ZoneSelectionScreenState createState() => _ZoneSelectionScreenState();
}
class _ZoneSelectionScreenState extends State<ZoneSelectionScreen> {
  final _storage = GetStorage(); // Assuming GetStorage is being used
  Map<String, String> zoneIdMap = {};
  String? selectedZoneId;
  String? sessionId;
  bool isNavigating = false;
  String? _downloadPath;

  @override
  void initState() {
    super.initState();
    _fetchZoneIds();
    sessionId = widget.sessionId; //
    _downloadPath = _storage.read('downloadPath');
  }

  void _handleZoneEnded(String zoneId, String sessionId, {required bool isBluetooth}) {
    setState(() {
      selectedZoneId = zoneId;
      this.sessionId = sessionId;
    });

   // _endSession(); // Calls the end session function with the updated values
  }

  Future<void> _fetchZoneIds() async {
    final token = _storage.read('token') as String;
    try {
      final response = await http.get(
        Uri.parse('https://iscandata.com/api/v1/zones/notUsedZones'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      final responseBody = jsonDecode(response.body);
      print('Fetch Zones Response: $responseBody');

      if (responseBody['status'] == 'success') {
        final zonesData = responseBody['data']['zones'] as List;
        setState(() {
          zoneIdMap = {
            for (var zone in zonesData) zone['name']: zone['_id'],
          };
        });
      } else if (response.statusCode == 401) {
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pushReplacementNamed(
              '/login'); // Adjust route name accordingly
        });
        return;
      } else {
        // Show a bottom sheet after a 10-second delay
        await Future.delayed(Duration(seconds: 10));
        _showZoneBottomSheet(); // Corrected method call
      }
    } catch (e) {
      print('Error details: $e');
    }
  }

  /////////////////////////////////////////////////
  //Method to remove the zone when the "End Scan" button is pressed
  void _removeZone(String zoneId) {
    setState(() {
      // Remove the zone from the map
      zoneIdMap.removeWhere((key, value) => value == zoneId);
      // Reset selectedZoneId if it matches the removed zone
      if (selectedZoneId == zoneId) {
        selectedZoneId = null;
      }
    });
  }

  ///////////////////////////////////////////////////////

  void _showZoneBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Before scanning, you must add a zone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20),
              Icon(
                Icons.warning_amber_rounded,
                size: 50,
                color: Colors.orangeAccent,
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ZonePage()),
                  );
                },
                icon: Icon(Icons.add_location_alt, color: Colors.white),
                label: Text(
                  'Add Zone',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Please ensure a zone is added before proceeding to scanning.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _endSession() async {
    final token = _storage.read('token') as String?;
    if (token == null || sessionId == null || sessionId!.isEmpty ||
        selectedZoneId == null || selectedZoneId!.isEmpty) {
      _showAlert('Session ID or selected zone is missing.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://iscandata.com/api/v1/sessions/scan/end'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "sessionId": sessionId,
          "selectedZone": selectedZoneId,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        // Extract the session details from the response
        final session = responseBody['session'];
        final String startScanTime = session['startScanTime'];
        final String endScanTime = session['endScanTime'];

        // Calculate the time taken for the scan session
        final String timeTakenStr = _calculateTimeDifference(
            startScanTime, endScanTime);
// Extract the scans from the response
        final List<dynamic> scans = responseBody['scans'];
        final List<ScannedItem> scannedItems = scans.map((scan) {
          // Map department and zone details
          final department = scan['department'] ?? {};
          final zone = scan['zone'] ?? {};
          final String departmentName = department['name'] ?? 'Unknown Department';
          final String zoneName = zone['name'] ?? 'Unknown Zone'; // Define zoneName here
          final zoneDescription= zone['description'] ?? 'Unknown zoneDescription';
          final int quantity = scan['quantity'] ?? 0;
          final double price = (scan['productPrice'] ?? 0.0).toDouble();
          final double totalPrice = (scan['totalPrice'] ?? 0.0).toDouble();
          final bool notOnFile = scan['notOnFile'] ?? false;
          final String departmentId = department['id']?.toString() ?? 'Unknown Department ID';
          final productDescription= scan['productDescription'] ?? 'Unknown Product';

          final String zoneId = zone['_id']?.toString() ?? 'Unknown Zone ID';
          // Return ScannedItem with all details
          return ScannedItem(
            upc: scan['upc'],
            department: departmentName,
            quantity: quantity,
            price: price,
            totalPrice: totalPrice,
            notOnFile: notOnFile,
            zoneName: zoneName,
              productDescription:productDescription,
              zoneDescription : zoneDescription,
            departmentId: departmentId,
            zoneId: zoneId
            // Use zoneName consistently here
          );
        }).toList();

// Table data structure if needed
        final List<Map<String, dynamic>> tableData = scannedItems.map((item) {
          return {
            'UPC': item.upc,
            'Department': item.department,
            'Zone': item.zoneName, // Use zoneName consistently
            'Quantity': item.quantity,
            'Department ID': item.departmentId, // New field
            'Zone ID': item.zoneId, // New field
            'Price': item.price,
            'Total Price': item.totalPrice,
            'productDescription' :item.productDescription,
            'zoneDescription': item.zoneDescription
          };
        }).toList();
        // Display information in logs (optional)
        print('Session ended successfully.');
        print('Time taken: $timeTakenStr');
        print('Scanned items: $scannedItems');
        // Show download options (e.g., save as CSV/XML)
        _showDownloadOptions(responseBody);

        // Show an alert or table display with the results
        _showEndSessionAlert(timeTakenStr, scannedItems, tableData);
      } else {
        // If the session fails to end, print the failure message and show an alert
        print('Failed to end session: ${responseBody['message']}');
        _showAlert(
            'Failed to end session. Scan session may have already ended. Please go back and select a zone to start a new session.');
      }
    } catch (e) {
      // Catch any exceptions and show an error alert
      print('Error ending session: $e');
      _showAlert('An error occurred while ending the session.');
    }
  }

  void _showLeaveWithoutDownloadConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text(
              'You haven\'t downloaded the session report. Are you sure you want to leave?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Yes, Leave'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _endSession(); // End the session
              },
            ),
          ],
        );
      },
    );
  }


  Future<bool> _generateAndSaveCSV(Map<String, dynamic> reportData) async {
    try {
      // Check if 'scans' exist in reportData
      if (reportData['scans'] == null) {
        print('Invalid report data: scans are missing');
        return false; // Return false sinc data is invalid
      }

      String csvData = ''; // Initialize CSV data
      String startTime = reportData['session']['startScanTime'] ??
          'N/A'; // Get start time
      String endTime = reportData['session']['endScanTime'] ??
          'N/A'; // Get end time
      String timeTakenStr = _calculateTimeDifference(
          startTime, endTime); // Calculate time taken

      // Add session details to CSV
      csvData += 'Session Start Time: $startTime\n';
      csvData += 'Session End Time: $endTime\n';
      csvData += 'Total Time Taken: $timeTakenStr seconds\n\n';

      // Add Detail Zones Report
      csvData += 'Detail Zones Report\n';
      csvData += 'Zone Name, UPC, Product Description, Quantity, Total Price\n';

      final List<dynamic> scans = reportData['scans'];
      for (var scan in scans) {
        var zone = scan['zone']['name'] ?? 'Unknown Zone';
        double quantity = (scan['quantity'] is int) ? (scan['quantity'] as int)
            .toDouble() : (scan['quantity'] ?? 0.0);
        double totalPrice = (scan['totalPrice'] is int)
            ? (scan['totalPrice'] as int).toDouble()
            : (scan['totalPrice'] ?? 0.0);

        csvData += '$zone, '
            '${scan['upc']}, '
            '${scan['productDescription']}, '
            '$quantity, '
            '$totalPrice\n';
      }
      csvData += '\n'; // Add a newline for separation

      // Add Zones General Report
      csvData += 'Zones General Report\n';
      csvData += 'Zone Name, Total Quantity, Total Retail\n';

      // Initialize zonesSummary map
      Map<String, Map<String, dynamic>> zonesSummary = {};
      for (var scan in scans) {
        String zoneName = scan['zone']['name'];
        double quantity = (scan['quantity'] is int) ? (scan['quantity'] as int)
            .toDouble() : (scan['quantity'] ?? 0.0);
        double totalPrice = (scan['totalPrice'] is int)
            ? (scan['totalPrice'] as int).toDouble()
            : (scan['totalPrice'] ?? 0.0);

        // Initialize the zone entry if it doesn't exist
        if (!zonesSummary.containsKey(zoneName)) {
          zonesSummary[zoneName] = {'totalQty': 0.0, 'totalRetail': 0.0};
        }

        // Safely access the values now
        zonesSummary[zoneName]!['totalQty'] +=
            quantity; // Use the null assertion operator
        zonesSummary[zoneName]!['totalRetail'] +=
            totalPrice; // Use the null assertion operator
      }

      zonesSummary.forEach((zoneName, summary) {
        csvData += '$zoneName, '
            '${summary['totalQty']}, '
            '${summary['totalRetail']}\n';
      });
      csvData += '\n'; // Add a newline for separation

      // Add Department General Report
      csvData += 'Department General Report\n';
      csvData += 'Department Name, Total Quantity, Total Retail\n';

      // Initialize departmentSummary map
      Map<String, Map<String, dynamic>> departmentSummary = {};
      for (var scan in scans) {
        String departmentName = scan['department']['name'];
        double quantity = (scan['quantity'] is int) ? (scan['quantity'] as int)
            .toDouble() : (scan['quantity'] ?? 0.0);
        double totalPrice = (scan['totalPrice'] is int)
            ? (scan['totalPrice'] as int).toDouble()
            : (scan['totalPrice'] ?? 0.0);

        // Initialize the department entry if it doesn't exist
        if (!departmentSummary.containsKey(departmentName)) {
          departmentSummary[departmentName] =
          {'totalQty': 0.0, 'totalRetail': 0.0};
        }

        // Safely access the values now
        departmentSummary[departmentName]!['totalQty'] +=
            quantity; // Use the null assertion operator
        departmentSummary[departmentName]!['totalRetail'] +=
            totalPrice; // Use the null assertion operator
      }

      departmentSummary.forEach((deptName, summary) {
        csvData += '$deptName, '
            '${summary['totalQty']}, '
            '${summary['totalRetail']}\n';
      });
      csvData += '\n'; // Add a newline for separation

      // Assuming N.O.F. reports are similar to scans
      // Assuming N.O.F. reports are similar to scans
      csvData += 'N.O.F. Report\n';
      csvData += 'Department Name, UPC, Quantity, Retail Price, Total Retail\n';

// Filter scans based on notOnFile == true
      final nofScans = scans.where((scan) => scan['notOnFile'] == true)
          .toList();

      for (var scan in nofScans) {
        double quantity = (scan['quantity'] is int)
            ? (scan['quantity'] as int).toDouble()
            : (scan['quantity'] ?? 0.0);
        double price = (scan['price'] is int)
            ? (scan['price'] as int).toDouble()
            : (scan['price'] ?? 0.0);
        double totalPrice = (scan['totalPrice'] is int)
            ? (scan['totalPrice'] as int).toDouble()
            : (scan['totalPrice'] ?? 0.0);

        csvData += '${scan['department']['name']}, '
            '${scan['upc']}, '
            '$quantity, '
            '$price, '
            '$totalPrice\n';
      }
      csvData += '\n'; // Add a newline for separation

      // Save the CSV file
      await _saveFile(csvData, 'csv');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('CSV file generated successfully'),
      ));

      return true; // Return true since CSV generation was successful
    } catch (e) {
      print('Error generating CSV: $e');
      return false; // Return false since CSV generation failed
    }
  }

  Future<bool> _generateAndSaveXML(Map<String, dynamic> reportData) async {
    try {
      // Check if 'scans' exist in reportData
      if (reportData['scans'] == null) {
        print('Invalid report data: scans are missing');
        return false; // Return false since data is invalid
      }

      final builder = xml.XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element('Report', nest: () {
        String startTime = reportData['session']['startScanTime'] ??
            'N/A'; // Get start time
        String endTime = reportData['session']['endScanTime'] ??
            'N/A'; // Get end time
        String timeTakenStr = _calculateTimeDifference(
            startTime, endTime); // Calculate time taken

        // Add session details to XML
        builder.element('SessionDetails', nest: () {
          builder.element('StartTime', nest: startTime);
          builder.element('EndTime', nest: endTime);
          builder.element('TimeTaken', nest: timeTakenStr);
        });

        // Detail Zones Report
        builder.element('DetailZonesReport', nest: () {
          builder.element('Header',
              nest: 'Zone Name, UPC, Product Description, Quantity, Total Price');
          final List<dynamic> scans = reportData['scans'];
          for (var scan in scans) {
            var zone = scan['zone']['name'] ?? 'Unknown Zone';
            double quantity = (scan['quantity'] is int)
                ? (scan['quantity'] as int).toDouble()
                : (scan['quantity'] ?? 0.0);
            double totalPrice = (scan['totalPrice'] is int)
                ? (scan['totalPrice'] as int).toDouble()
                : (scan['totalPrice'] ?? 0.0);
            builder.element('Scan', nest: () {
              builder.element('ZoneName', nest: zone);
              builder.element('UPC', nest: scan['upc']);
              builder.element(
                  'ProductDescription', nest: scan['productDescription']);
              builder.element('Quantity', nest: quantity.toString());
              builder.element('TotalPrice', nest: totalPrice.toString());
            });
          }
        });

        // Zones General Report
        builder.element('ZonesGeneralReport', nest: () {
          builder.element(
              'Header', nest: 'Zone Name, Total Quantity, Total Retail');
          Map<String, Map<String, dynamic>> zonesSummary = {};
          final List<dynamic> scans = reportData['scans'];
          for (var scan in scans) {
            String zoneName = scan['zone']['name'];
            double quantity = (scan['quantity'] is int)
                ? (scan['quantity'] as int).toDouble()
                : (scan['quantity'] ?? 0.0);
            double totalPrice = (scan['totalPrice'] is int)
                ? (scan['totalPrice'] as int).toDouble()
                : (scan['totalPrice'] ?? 0.0);
            if (!zonesSummary.containsKey(zoneName)) {
              zonesSummary[zoneName] = {'totalQty': 0.0, 'totalRetail': 0.0};
            }
            zonesSummary[zoneName]!['totalQty'] += quantity;
            zonesSummary[zoneName]!['totalRetail'] += totalPrice;
          }
          zonesSummary.forEach((zoneName, summary) {
            builder.element('Zone', nest: () {
              builder.element('ZoneName', nest: zoneName);
              builder.element(
                  'TotalQuantity', nest: summary['totalQty'].toString());
              builder.element(
                  'TotalRetail', nest: summary['totalRetail'].toString());
            });
          });
        });

        // Department General Report
        builder.element('DepartmentGeneralReport', nest: () {
          builder.element(
              'Header', nest: 'Department Name, Total Quantity, Total Retail');
          Map<String, Map<String, dynamic>> departmentSummary = {};
          final List<dynamic> scans = reportData['scans'];
          for (var scan in scans) {
            String departmentName = scan['department']['name'];
            double quantity = (scan['quantity'] is int)
                ? (scan['quantity'] as int).toDouble()
                : (scan['quantity'] ?? 0.0);
            double totalPrice = (scan['totalPrice'] is int)
                ? (scan['totalPrice'] as int).toDouble()
                : (scan['totalPrice'] ?? 0.0);
            if (!departmentSummary.containsKey(departmentName)) {
              departmentSummary[departmentName] =
              {'totalQty': 0.0, 'totalRetail': 0.0};
            }
            departmentSummary[departmentName]!['totalQty'] += quantity;
            departmentSummary[departmentName]!['totalRetail'] += totalPrice;
          }
          departmentSummary.forEach((deptName, summary) {
            builder.element('Department', nest: () {
              builder.element('DepartmentName', nest: deptName);
              builder.element(
                  'TotalQuantity', nest: summary['totalQty'].toString());
              builder.element(
                  'TotalRetail', nest: summary['totalRetail'].toString());
            });
          });
        });

        // // N.O.F. Report
        // builder.element('NofReport', nest: () {
        //   builder.element('Header',
        //       nest: 'Department Name, UPC, Quantity, Retail Price, Total Retail');
        //   final List<dynamic> scans = reportData['scans'];
        //   for (var scan in scans) {
        //     double quantity = (scan['quantity'] is int)
        //         ? (scan['quantity'] as int).toDouble()
        //         : (scan['quantity'] ?? 0.0);
        //     double price = (scan['price'] is int) ? (scan['price'] as int)
        //         .toDouble() : (scan['price'] ?? 0.0);
        //     double totalPrice = (scan['totalPrice'] is int)
        //         ? (scan['totalPrice'] as int).toDouble()
        //         : (scan['totalPrice'] ?? 0.0);
        //     builder.element('Scan', nest: () {
        //       builder.element(
        //           'DepartmentName', nest: scan['department']['name']);
        //       builder.element('UPC', nest: scan['upc']);
        //       builder.element('Quantity', nest: quantity.toString());
        //       builder.element('RetailPrice', nest: price.toString());
        //       builder.element('TotalRetail', nest: totalPrice.toString());
        //     });
        //   }
        // });
        builder.element('NofReport', nest: () {
          builder.element('Header',
              nest: 'Department Name, UPC, Quantity, Retail Price, Total Retail');

          // Extract and filter scans where notOnFile is true
          final List<dynamic> scans = reportData['scans'];
          final filteredScans = scans.where((scan) => scan['notOnFile'] == true)
              .toList();

          for (var scan in filteredScans) {
            // Safely extract and convert values
            double quantity = (scan['quantity'] is int)
                ? (scan['quantity'] as int).toDouble()
                : (scan['quantity'] ?? 0.0);
            double price = (scan['price'] is int)
                ? (scan['price'] as int).toDouble()
                : (scan['price'] ?? 0.0);
            double totalPrice = (scan['totalPrice'] is int)
                ? (scan['totalPrice'] as int).toDouble()
                : (scan['totalPrice'] ?? 0.0);

            builder.element('Scan', nest: () {
              builder.element(
                  'DepartmentName', nest: scan['department']['name']);
              builder.element('UPC', nest: scan['upc']);
              builder.element('Quantity', nest: quantity.toString());
              builder.element('RetailPrice', nest: price.toString());
              builder.element('TotalRetail', nest: totalPrice.toString());
            });
          }
        });
      });

      final xmlData = builder.buildDocument().toString();
      await _saveFile(xmlData, 'xml');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('XML file downloaded successfully!'),
        backgroundColor: Colors.green,
      ));
      return true; // Indicate success
    } catch (e) {
      print('Error generating XML: $e'); // Log error to console
      return false; // Indicate failure
    }
  }

  Future<bool> _generatePDF(List<ScannedItem> scannedItems, String startTime,
      String endTime, String timeTakenStr) async {
    try {
      final pdf = pw.Document();
      // Helper function to calculate totals for a specific filter
      double calculateTotalQuantity(List<ScannedItem> items) =>
          items.fold(0, (sum, item) => sum + item.quantity);

      double calculateTotalRetail(List<ScannedItem> items) =>
          items.fold(0, (sum, item) => sum + item.totalPrice);

      // Filtered lists for each report
      final List<ScannedItem> detailZonesItems = scannedItems; // All items for Detail Zones Report
      final List<ScannedItem> generalZonesItems = scannedItems; // Grouped by zone for Zones General Report
      final List<ScannedItem> departmentGeneralItems = scannedItems; // Grouped by department
      final List<ScannedItem> nofItems =
      scannedItems.where((item) => item.notOnFile == true).toList();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) =>
          [
            pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Scan Session Report',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Text(
                      'Date: ${DateTime.now().toLocal().toString().split(
                          ' ')[0]}',
                      style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 10),
                  pw.Text('Start Time: $startTime',
                      style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 10),
                  pw.Text('End Time: $endTime',
                      style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 20),
                  pw.Text('Time Taken: $timeTakenStr seconds',
                      style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 20),
                ],
              ),
            ),

            // Detail Zones Report
            pw.Text('Detail Zones Report',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...scannedItems.map((item) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Zone Name: ${item.zoneName}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Zone Description: ${item.zoneDescription}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text(
                      'UPC: ${item.upc}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Product Description: ${item.productDescription}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Quantity: ${item.quantity}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text(
                      'Total Price: \$${item.totalPrice.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 10),
                ],
              );
            }).toList(),
            pw.Divider(),
            pw.Text(
              'Total Quantity: ${calculateTotalQuantity(detailZonesItems)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Total Retail: \$${calculateTotalRetail(detailZonesItems).toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),

            // Zones General Report
            pw.SizedBox(height: 20),
            pw.Text('Zones General Report',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...scannedItems.map((item) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Zone Name: ${item.zoneName}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Zone Description: ${item.zoneDescription}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Dept Id: ${item.departmentId}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Dept Name: ${item.department}',
                      style: pw.TextStyle(fontSize: 16)),

                  pw.Text('Total Quantity: ${item.quantity}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text(
                      'Total Retail: \$${item.totalPrice.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 10),
                ],
              );
            }).toList(),
            pw.Divider(),
            pw.Text(
              'Total Quantity: ${calculateTotalQuantity(generalZonesItems)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Total Retail: \$${calculateTotalRetail(generalZonesItems).toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            // Department General Report
            pw.SizedBox(height: 20),
            pw.Text('Department General Report',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...scannedItems.map((item) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Department Id: ${item.departmentId}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Department Name: ${item.department}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Total Quantity: ${item.quantity}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text(
                      'Total Retail: \$${item.totalPrice.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 10),
                ],
              );
            }).toList(),
            pw.Divider(),
            pw.Text(
              'Total Quantity: ${calculateTotalQuantity(departmentGeneralItems)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Total Retail: \$${calculateTotalRetail(departmentGeneralItems).toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),

            // N.O.F. Report (filtered by notOnFile == true)
            pw.SizedBox(height: 20),
            pw.Text('N.O.F. Report',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...scannedItems
                .where((item) =>
            item.notOnFile == true) // Filter items where notOnFile is true
                .map((item) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Department Name: ${item.department}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Department Id: ${item.departmentId}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text(
                      'UPC: ${item.upc}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Quantity: ${item.quantity}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text(
                      'Retail Price: \$${item.price.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text(
                      'Total Retail: \$${item.totalPrice.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 10),
                ],
              );
            }).toList(),
            pw.Divider(),
            pw.Text(
              'Total Quantity: ${calculateTotalQuantity(nofItems)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Total Retail: \$${calculateTotalRetail(nofItems).toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      );

      // Prompt user to select a directory to save the PDF
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        print('No directory selected. PDF not saved.');
        return false;
      }

      // Save the PDF file to the selected directory
      final fileName = 'scan_session_${DateTime
          .now()
          .millisecondsSinceEpoch}.pdf';
      final filePath = '$selectedDirectory/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      print('PDF saved at: $filePath'); // Debugging path

      // Use the exact path for email
      bool emailSuccess = await _sendEmailWithPDF(filePath);

      if (emailSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PDF saved and email sent successfully: $filePath'),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PDF saved, but email sending failed: $filePath'),
          backgroundColor: Colors.orange,
        ));
      }

      return true;
    } catch (e) {
      print('Error generating PDF: $e');
      return false;
    }
  }

  // Future<bool> _sendEmailWithPDF() async {
  //   try {
  //     final token = _storage.read('token') as String?;
  //     if (token == null) {
  //       print('Token not available');
  //       return false;
  //     }
  //
  //     // Retrieve the exact file path from GetStorage
  //     final filePath = _storage.read('savedFilePath') as String?;
  //     if (filePath == null || !File(filePath).existsSync()) {
  //       print('File path not found or file does not exist.');
  //       return false;
  //     }
  //
  //     // Prepare the request
  //     final request = http.MultipartRequest(
  //       'POST',
  //       Uri.parse('https://iscandata.com/api/v1/sessions/send-report'),
  //     );
  //     request.headers['Authorization'] = 'Bearer $token';
  //
  //     // Attach the file
  //     request.files.add(await http.MultipartFile.fromPath(
  //       'file',
  //       filePath,
  //       contentType: MediaType('application', 'pdf'),
  //     ));
  //
  //     // Send the request
  //     final response = await request.send();
  //
  //     if (response.statusCode == 200) {
  //       print('Email sent successfully with attachment: $filePath');
  //       return true;
  //     } else {
  //       print('Failed to send email: ${response.statusCode}');
  //       return false;
  //     }
  //   } catch (e) {
  //     print('Error sending email: $e');
  //     return false;
  //   }
  // }
  Future<bool> _sendEmailWithPDF(String filepath) async {
    try {
      final token = _storage.read('token') as String?;
      if (token == null) {
        print('Token not available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Authentication token not available')),
          );
        }
        return false;
      }

      if (filepath.isEmpty) {
        print('File path not provided.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File path not provided.')),
          );
        }
        return false;
      }

      // Check if the file exists
      final file = File(filepath);
      if (!file.existsSync()) {
        print('File does not exist at path: $filepath');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                'The file does not exist at the specified path.')),
          );
        }
        return false;
      }

      // Prepare the HTTP request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://iscandata.com/api/v1/sessions/send-report'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      // request.files.add(await http.MultipartFile.fromPath(
      //   'file',
      //   filepath,
      //   contentType: MediaType('application', 'pdf'),
      // ));
      request.files.add(await http.MultipartFile.fromPath(
        'report', // Updated to match the server's expected field name
        filepath,
        contentType: MediaType('application', 'pdf'),
      ));


      final response = await request.send();

      // Read the response body for details
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print('Email sent successfully with attachment: $filepath');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email sent successfully!')),
          );
        }
        return true;
      } else {
        print('Failed to send email: ${response.statusCode}');
        print('Error details: $responseBody');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                'Failed to send email: ${response.reasonPhrase}')),
          );
        }
        return false;
      }
    } catch (e) {
      print('Error sending email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while sending the email.')),
        );
      }
      return false;
    }
  }

  Future<void> _saveFile(String data, String extension) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      print('No directory selected. File not saved.');
      return;
    }

    try {
      final fileName = 'scan_session_${DateTime
          .now()
          .millisecondsSinceEpoch}.$extension';
      final filePath = '$selectedDirectory/$fileName';
      final file = File(filePath);
      await file.writeAsString(data);

      print('PDF saved at: $filePath'); // Log the saved file path

      // Call the function to send the email, passing the filePath
      await _sendEmailWithPDF(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$extension file saved to $filePath')),
        );
      }
    } catch (e) {
      print('Error saving file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save file. Please try again.')),
        );
      }
    }
  }


  void _showDownloadOptions(Map<String, dynamic> reportData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom AppBar
              AppBar(
                title: Text('Download Options'),
                actions: [
                  IconButton(
                    icon: Icon(Icons.cancel),
                    onPressed: () {
                      _showLeaveWithoutDownloadConfirmation();
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Close the bottom sheet
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),

              ListTile(
                leading: Icon(Icons.insert_drive_file),
                title: Text('Download as CSV'),
                onTap: () async {
                  if (reportData != null) {
                    bool success = await _generateAndSaveCSV(reportData);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('CSV downloaded successfully'),
                      ));
                    }
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.table_chart_rounded),
                title: Text('Download as XML'),
                onTap: () async {
                  if (reportData != null) {
                    bool success = await _generateAndSaveXML(reportData);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('XML downloaded successfully'),
                      ));
                    }
                  }
                },
              ),
              ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  // Ensures the row doesn't take up unnecessary space
                  children: [
                    Icon(Icons.email, color: Colors.blue), // Email icon
                    SizedBox(width: 10), // Spacing between icons
                    Icon(Icons.download, color: Colors.green), // Download icon
                  ],
                ),
                title: Text('Download as PDF'),
                onTap: () async {
                  if (reportData['scans'] != null &&
                      reportData['scans'] is List) {
                    print(reportData['scans']);
                    final List<ScannedItem> scannedItems = (reportData['scans'] as List).map((item) {
                      if (item is Map<String, dynamic>) {
                        // Safely handle `zone`
                        final String zoneName = item['zone'] != null && item['zone'] is Map<String, dynamic>
                            ? (item['zone']['name'] ?? 'Unknown Zone')
                            : 'Unknown Zone';
                        final String zoneDescription = item['zone'] != null && item['zone'] is Map<String, dynamic>
                            ? (item['zone']['description'] ?? 'Unknown Zone Description')
                            : 'Unknown Zone Description';
                        final String zoneId = item['zone'] != null && item['zone'] is Map<String, dynamic>
                            ? (item['zone']['_id'] ?? 'Unknown Zone ID')
                            : 'Unknown Zone ID';

                        // Safely handle `department`
                        final String departmentName = item['department'] != null && item['department'] is Map<String, dynamic>
                            ? (item['department']['name'] ?? 'Unknown Department')
                            : 'Unknown Department';
                        final String departmentId = item['department'] != null && item['department'] is Map<String, dynamic>
                            ? (item['department']['id']?.toString() ?? 'Unknown Department ID')
                            : 'Unknown Department ID';

                        // Safely handle `productDescription`
                        final String productDescription = item['productDescription'] is String
                            ? item['productDescription']
                            : 'Unknown Product';

                        return ScannedItem(
                          upc: item['upc'] ?? 'Unknown',
                          quantity: item['quantity'] ?? 0,
                          department: item['department'] != null && item['department'] is Map
                              ? (item['department']['name'] ?? 'Unknown Department')
                              : 'Unknown Department',
                          zoneName: zoneName,
                            zoneId: zoneId,
                            departmentId: departmentId,
                          productDescription: productDescription,
                          price: (item['price'] ?? 0).toDouble(),
                          totalPrice: (item['totalPrice'] ?? 0).toDouble(),
                          notOnFile: item['notOnFile'] ?? false,
                            zoneDescription:zoneDescription
                        );
                      } else {
                        return ScannedItem(
                          upc: 'Unknown',
                          quantity: 0,
                          zoneName: 'Unknown Zone',
                          department: 'Unknown Department',
                          price: 0.0,
                          totalPrice: 0.0,
                          notOnFile: false,
                            zoneId: 'Unknown Zone ID',
                            departmentId: 'Unknown Department ID',
                          productDescription: 'Unknown Product',
                            zoneDescription: 'Unknow zoneDescription'
                        );
                      }
                    }).toList().cast<
                        ScannedItem>(); // Cast to List<ScannedItem>
                    // Call your PDF generation function
                    String startTime = reportData['session']['startScanTime'] ??
                        'N/A';
                    String endTime = reportData['session']['endScanTime'] ??
                        'N/A';
                    final String timeTakenStr = _calculateTimeDifference(
                        startTime, endTime);

                    bool success = await _generatePDF(
                        scannedItems, startTime, endTime, timeTakenStr);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('PDF saved successfully'),
                        backgroundColor: Colors.green,
                      ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(' Failed to save PDF'),
                        backgroundColor: Colors.red,
                      ));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('No scans found'),
                      backgroundColor: Colors.red,
                    ));
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.folder),
                title: Text('Change Download Location'),
                onTap: () async {
                  String? selectedDirectory = await FilePicker.platform
                      .getDirectoryPath();
                  if (selectedDirectory != null) {
                    setState(() {
                      _downloadPath = selectedDirectory;
                      _storage.write('downloadPath', selectedDirectory);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Download path changed to $selectedDirectory'),
                    ));
                  }
                },
              ),
              SizedBox(height: 20), // Add space before the cancel button
            ],
          ),
        );
      },
    );
  }

// Update the _showEndSessionAlert function to display the scanned items
  void _showEndSessionAlert(String timeTakenStr, List<ScannedItem> scannedItems,
      List<Map<String, dynamic>> tableData) {
    // Display the scanned items in a list or table
    // For example:
    // String scannedItemsStr = '';
    // for (ScannedItem item in scannedItems) {
    //   scannedItemsStr += 'UPC: ${item.upc}, De'
    //       'partment: ${item.department}, Quantity: ${item
    //       .quantity}, Price: ${item.price}\n';
    // // }
    // _showAlert(
    //     'Session ended successfully. Time taken: $timeTakenStr\nScanned Items:\n$scannedItemsStr');
    _showAlert(
        'Session ended successfully. The time taken for this session was $timeTakenStr. You will now have the option to download the session report in CSV, XML, or PDF format. Additionally, a PDF copy will be sent to your registered email address automatically.'
    );

  }

  // Function to calculate the time difference between two timestamps
  String _calculateTimeDifference(String start, String end) {
    final DateTime startTime = DateTime.parse(start);
    final DateTime endTime = DateTime.parse(end);

    final Duration difference = endTime.difference(startTime);

    // Convert the difference to minutes and seconds
    final int minutes = difference.inMinutes;
    final int seconds = difference.inSeconds % 60;

    return '$minutes minutes, $seconds';
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      // Permission granted
      _navigateToScan();
    } else if (status.isDenied) {
      // Permission denied
      _showAlert('Camera permission is required for scanning products.');
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied, show settings
      openAppSettings();
    }
  }
  void _navigateToScan({bool useBluetoothScanner = false}) async {
    // Check if the zone ID and session ID are selected
    if (selectedZoneId != null && sessionId != null) {
      // Check camera permission
      final status = await Permission.camera.request();
      if (status.isGranted) {
        setState(() {
          isNavigating = true; // Start navigating
        });

        // Show a message indicating navigation is in progress
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are navigating to Scanning...'),
            duration: Duration(seconds: 2), // Adjust as needed
          ),
        );

        // Delay for a short while to show the message
        await Future.delayed(Duration(seconds: 2));

        // Permission granted, navigate to the appropriate page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => useBluetoothScanner
                ? Bluetoothscanner(
              zoneId: selectedZoneId!,
              sessionId: sessionId!,
              onZoneEnded: (zoneId, sessionId) {
                _handleZoneEnded(zoneId, sessionId, isBluetooth: true);
              },
            )
                : BarcodeScanPage(
              zoneId: selectedZoneId!,
              sessionId: sessionId!,
              onZoneEnded: (zoneId, sessionId) {
                _handleZoneEnded(zoneId, sessionId, isBluetooth: false);
              },
            ),
          ),
        ).then((_) {
          // Reset navigation state after coming back
          setState(() {
            isNavigating = false;
          });
        });
      } else if (status.isDenied) {
        // Permission denied
        _showAlert('Camera permission is required for scanning products.');
      } else if (status.isPermanentlyDenied) {
        // Permission permanently denied, show settings
        openAppSettings();
      }
    } else {
      _showAlert('Please select a zone and ensure the session has started.');
    }
  }
  void _onZoneEnd(String zoneId, String sessionId, {bool isBluetooth = false}) {
    _removeZone(zoneId);
    _handleZoneEnded(zoneId, sessionId, isBluetooth: isBluetooth); // Pass the isBluetooth parameter
  }
  Future<void> _startZone() async {
    final _storage = GetStorage();
    final token = _storage.read('token') as String;
    try {
      final response = await http.post(
        Uri.parse('https://iscandata.com/api/v1/sessions/scan/addZone'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"selectedZone": selectedZoneId},),
      );
      final responseBody = jsonDecode(response.body);
      print('Start Session Response: $responseBody');

      if (responseBody['status'] == 'success') {} else
      if (response.statusCode == 401) {
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pushReplacementNamed(
              '/login'); // Adjust route name accordingly
        });
        return;
      }
    } catch (e) {
      print('Error details of: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Zone'),
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),// Removes the default back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (zoneIdMap.isNotEmpty)
                Column(
                  children: [
                    Text(
                      'Select a Zone to Start',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black54),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedZoneId,
                        hint: Text('Select Zone'),
                        items: zoneIdMap.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.value,
                            child: Text(entry.key),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedZoneId = value;
                            print("Selected Zone ID -- $selectedZoneId");
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                )
              else
                Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text(
                      'Loading zones, please wait...',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: (selectedZoneId == null || isNavigating)
                          ? null
                          : () async {
                        // Start the session
                        await _startZone();
                        if (sessionId != null) {
                          _navigateToScan(); // Only navigate if session ID is not null
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        height: 50,
                        decoration: BoxDecoration(
                          color: (selectedZoneId == null || isNavigating)
                              ? Colors.grey
                              : Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              isNavigating ? 'Navigating...' : 'Start Scanning',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        bool confirm = await _showEndInventoryConfirmation();
                        if (confirm) {
                          _endSession();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        'End Inventory',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              if (selectedZoneId == null)
                Text(
                  'Please select a zone to start scanning and ensure XML file upload is completed before scanning.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
            ],
          ),
        ),
      ),
    );
  }

// Confirmation dialog for ending inventory
  Future<bool> _showEndInventoryConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('End Inventory Session'),
          content: Text(
            'Are you sure you want to end this inventory session? This will reset the session, and you will need to initiate a new one.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('End Session'),
            ),
          ],
        );
      },
    ) ??
        false;
  }
}
class ScannedItem {
  final String upc;
  final int quantity;
  final String department;
  final String departmentId;
  final String zoneName;
  final String zoneId;
  final String zoneDescription;
  final String productDescription;
  final double price;
  final double totalPrice;
  final bool notOnFile;

  ScannedItem({
    required this.upc,
    required this.quantity,
    required this.department,
    required this.departmentId,
    required this.zoneName,
    required this.zoneId,
    required this.zoneDescription,
    required this.productDescription,
    required this.price,
    required this.totalPrice,
    required this.notOnFile,
  });
}
