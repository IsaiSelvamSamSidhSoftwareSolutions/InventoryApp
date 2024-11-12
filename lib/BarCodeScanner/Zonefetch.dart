
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
class ZoneSelectionScreen extends StatefulWidget {
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
    _downloadPath = _storage.read('downloadPath');
  }

  void _handleZoneEnded(String zoneId, String sessionId) {
    setState(() {
      selectedZoneId = zoneId;
      this.sessionId = sessionId;
    });
    _endSession(); // Now _endSession can use the updated selectedZoneId and sessionId
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

  Future<void> _startSession() async {
    if (selectedZoneId == null) {
      _showAlert('Please select a zone before starting the session.');
      return;
    }

    final token = _storage.read('token') as String;
    try {
      final response = await http.post(
        Uri.parse('https://iscandata.com/api/v1/sessions/scan/start'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"selectedZone": selectedZoneId}),
      );
      final responseBody = jsonDecode(response.body);
      print('Start Session Response: $responseBody');

      if (responseBody['status'] == 'success') {
        setState(() {
          sessionId = responseBody['sessionId'];
        });
        print('Session ID: $sessionId');
      } else if (response.statusCode == 401) {
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pushReplacementNamed(
              '/login'); // Adjust route name accordingly
        });
        return;
      } else {
        _showAlert('Failed to start session');
      }
    } catch (e) {
      print('Error details of: $e');
    }
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
          // Map department details, UPC, quantity, and price
          final department = scan['department'] ?? {};
          final String departmentName = department['name'] ??
              'Unknown Department';
          final int quantity = scan['quantity'] ?? 0;
          final double price = (scan['productPrice'] ?? 0.0).toDouble();
          final double totalPrice = (scan['totalPrice'] ?? 0.0).toDouble();

          // Return ScannedItem with department, quantity, and pricing details
          return ScannedItem(
            upc: scan['upc'],
            department: departmentName,
            quantity: quantity,
            price: price,
            totalPrice: totalPrice,
          );
        }).toList();

        // Table data structure if needed
        final List<Map<String, dynamic>> tableData = scannedItems.map((item) {
          return {
            'UPC': item.upc,
            'Department': item.department,
            'Quantity': item.quantity,
            'Price': item.price,
            'Total Price': item.totalPrice,
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
        return false; // Return false since data is invalid
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
      csvData += 'N.O.F. Report\n';
      csvData += 'Department Name, UPC, Quantity, Retail Price, Total Retail\n';

      for (var scan in scans) {
        double quantity = (scan['quantity'] is int) ? (scan['quantity'] as int)
            .toDouble() : (scan['quantity'] ?? 0.0);
        double price = (scan['price'] is int) ? (scan['price'] as int)
            .toDouble() : (scan['price'] ?? 0.0);
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

        // N.O.F. Report
        builder.element('NofReport', nest: () {
          builder.element('Header',
              nest: 'Department Name, UPC, Quantity, Retail Price, Total Retail');
          final List<dynamic> scans = reportData['scans'];
          for (var scan in scans) {
            double quantity = (scan['quantity'] is int)
                ? (scan['quantity'] as int).toDouble()
                : (scan['quantity'] ?? 0.0);
            double price = (scan['price'] is int) ? (scan['price'] as int)
                .toDouble() : (scan['price'] ?? 0.0);
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

      // Add session details and scanned items to the PDF using MultiPage for automatic pagination
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) =>
          [
            pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Scan Session Report', style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Text('Date: ${DateTime.now().toLocal().toString().split(
                      ' ')[0]}', style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 10),
                  pw.Text('Start Time: $startTime',
                      style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 10),
                  pw.Text(
                      'End Time: $endTime', style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 20),
                  pw.Text('Time Taken: $timeTakenStr seconds',
                      style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 20),
                ],
              ),
            ),

            // Detail Zones Report
            pw.Text('Detail Zones Report', style: pw.TextStyle(
                fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...scannedItems.map((item) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Zone Name: ${item.department}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text(
                      'UPC: ${item.upc}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Product Description: ${item.department}',
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

            // Zones General Report
            pw.SizedBox(height: 20),
            pw.Text('Zones General Report', style: pw.TextStyle(
                fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...scannedItems.map((item) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Zone Name: ${item.department}',
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

            // Department General Report
            pw.SizedBox(height: 20),
            pw.Text('Department General Report', style: pw.TextStyle(
                fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...scannedItems.map((item) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
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

            // N.O.F. Report
            pw.SizedBox(height: 20),
            pw.Text('N.O.F. Report', style: pw.TextStyle(
                fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...scannedItems.map((item) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Department Name: ${item.department}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text(
                      'UPC: ${item.upc}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Quantity: ${item.quantity}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Retail Price: \$${item.price.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text(
                      'Total Retail: \$${item.totalPrice.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 10),
                ],
              );
            }).toList(),
          ],
        ),
      );

      // Prompt user to select a directory to save the PDF
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        print('No directory selected. PDF not saved.');
        return false; // Return false since no directory was selected
      }

      // Save the PDF file to the selected directory
      final fileName = 'scan_session_${DateTime
          .now()
          .millisecondsSinceEpoch}.pdf';
      final filePath = '$selectedDirectory/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Store the selected path in GetStorage
      _storage.write('downloadPath', selectedDirectory);

      // Show a success Snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('PDF saved successfully: $filePath'),
        backgroundColor: Colors.green,
      ));

      return true; // Return true to indicate success
    } catch (e) {
      print('Error generating PDF: $e');
      return false; // Return false to indicate failure
    }
  }

  Future<void> _saveFile(String data, String extension) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      print('No directory selected. File not saved.');
      return;
    }

    try {
      final fileName = 'report_${DateTime
          .now()
          .millisecondsSinceEpoch}.$extension';
      final filePath = '$selectedDirectory/$fileName';
      final file = File(filePath);
      await file.writeAsString(data);

      // Store the selected path in GetStorage
      _storage.write('downloadPath', selectedDirectory);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$extension file saved to $filePath'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      print('Error saving file: $e'); // Log error to console
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Cannot save the file in the selected folder. Please choose a Document folder.'),
        backgroundColor: Colors.red,
      ));
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
                      Navigator.of(context).pop(); // Close the bottom sheet
                    },
                  ),
                ],
              ),
              ListTile(
                leading: Icon(Icons.file_download),
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
                leading: Icon(Icons.file_download),
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
                leading: Icon(Icons.file_download),
                title: Text('Download as PDF'),
                onTap: () async {
                  if (reportData['scans'] != null &&
                      reportData['scans'] is List) {
                    print(reportData['scans']);
                    List<
                        ScannedItem> scannedItems = (reportData['scans'] as List)
                        .map((item) {
                      if (item is Map<String, dynamic>) {
                        return ScannedItem(
                          upc: item['upc'] ?? 'Unknown',
                          quantity: item['quantity'] ?? 0,
                          department: item['department'] != null &&
                              item['department'] is Map
                              ? (item['department']['name'] ??
                              'Unknown Department')
                              : 'Unknown Department',
                          price: (item['price'] ?? 0).toDouble(),
                          totalPrice: (item['totalPrice'] ?? 0).toDouble(),
                        );
                      } else {
                        return ScannedItem(
                          upc: 'Unknown',
                          quantity: 0,
                          department: 'Unknown Department',
                          price: 0,
                          totalPrice: 0,
                        );
                      }
                    }).toList();

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
    String scannedItemsStr = '';
    for (ScannedItem item in scannedItems) {
      scannedItemsStr += 'UPC: ${item.upc}, De'
          'partment: ${item.department}, Quantity: ${item
          .quantity}, Price: ${item.price}\n';
    }
    _showAlert(
        'Session ended successfully. Time taken: $timeTakenStr\nScanned Items:\n$scannedItemsStr');
  }

  // Function to calculate the time difference between two timestamps
  String _calculateTimeDifference(String start, String end) {
    final DateTime startTime = DateTime.parse(start);
    final DateTime endTime = DateTime.parse(end);

    final Duration difference = endTime.difference(startTime);

    // Convert the difference to minutes and seconds
    final int minutes = difference.inMinutes;
    final int seconds = difference.inSeconds % 60;

    return '$minutes minutes, $seconds seconds';
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

  void _navigateToScan() async {
    // Check if the zone ID and session ID are selected
    if (selectedZoneId != null && sessionId != null) {
      // Check camera permissionn
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

        // Permission granted, navigate to BarcodeScanPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BarcodeScanPage(
                  zoneId: selectedZoneId!,
                  sessionId: sessionId!,
                  onZoneEnded: (zoneId, sessionId) =>
                      _handleZoneEnded(
                          zoneId, sessionId), // Pass _handleZoneEnded
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

  void _onZoneEnd(String zoneId, String sessionId) {
    _removeZone(zoneId);
    _handleZoneEnded(zoneId, sessionId);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Zone'),
        backgroundColor: Colors.blueAccent,
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
                CircularProgressIndicator(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: isNavigating ? null : () async {
                        // Start the session
                        await _startSession();
                        // Check if the session ID was successfully set
                        if (sessionId != null) {
                          _navigateToScan(); // Only navigate if session ID is not null
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue,
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
                      onPressed: _endSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        'End Session',
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
                  'Please select a zone to start scanning and ensure upload XML file is done before scan',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
            ],
          ),
        ),
      ),
    );
  }
}