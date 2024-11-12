import 'dart:convert';
import 'dart:io'; // For File handling
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart'; // Importing Flutter Sound
import 'package:path_provider/path_provider.dart'; // For temp directory access
import 'package:flutter/services.dart'; // For rootBundle access
import 'package:xml/xml.dart' as xml;
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:flutter_typeahead/flutter_typeahead.dart';
class BarcodeScanPage extends StatefulWidget {
  final String zoneId;
  final String sessionId;
  final Function? onZoneEnded;
  BarcodeScanPage({required this.zoneId, required this.sessionId , this.onZoneEnded});

  @override
  _BarcodeScanPageState createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  final GetStorage _storage = GetStorage();
  late MobileScannerController _scannerController;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _upcController = TextEditingController();
  Department? _selectedDepartment; // Store the selected department object
  bool _isScanning = true; // Control scanning state
  bool _productFound = false;
  bool _canScan = true;
  String? productData;
  List<ScannedItem> _scannedItems = [];
  final storage = GetStorage();
  String? _downloadPath;
  Color _upcColor = Colors.black;
  final GlobalKey<FormState> _formKey = GlobalKey<
      FormState>(); // Color for UPC text field

  // Initialize FlutterSoundPlayer
  final FlutterSoundPlayer _soundPlayer = FlutterSoundPlayer();

  @override
  void initState() {
    super.initState();
    _downloadPath = storage.read('downloadPath');
    _scannerController = MobileScannerController();
    super.initState();
    _quantityController.text = '1';
    _requestCameraPermission();
    _initializeSoundPlayer(); // Initialize sound player
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _departmentController.dispose();
    _descriptionController.dispose();
    _upcController.dispose();
    _soundPlayer.closePlayer(); // Close the audio session
    super.dispose();
  }
  // void _endZone() {
  //   // Notify the parent widget that the zone has been ended
  //   if (widget.onZoneEnded != null) {
  //     widget.onZoneEnded!(widget.zoneId); // Pass the zoneId of the ended zone
  //   }
  //
  //   // Show success message
  //   _showSnackbar('Zone ended successfully.', Colors.blue);
  //
  //   // Optionally, navigate back or perform other actions
  //   Navigator.of(context).pop();
  // }

  Future<void> _requestCameraPermission() async {
    // Check current permission status
    final status = await Permission.camera.status;
    if (status.isGranted) {
      // If permission is already granted, just start the scanner
      _initializeScanner();
    } else {
      // Request permission
      final result = await Permission.camera.request();
      if (result.isGranted) {
        // Permission granted, restart scanner directly
        _initializeScanner();
      } else if (result.isDenied) {
        _showAlert('Camera permission is required to scan barcodes.');
      } else if (result.isPermanentlyDenied) {
        // If permanently denied, direct user to settings
        _showAlert(
            'Camera permission is permanently denied. Please enable it in app settings.');
        openAppSettings().then((opened) {
          if (opened) {
            // Try to restart scanner when coming back from settings
            _requestCameraPermission(); // Retry permission check and start scanner
          }
        });
      }
    }
  }

  void _initializeScanner() {
    setState(() {
      _scannerController = MobileScannerController();
      _scannerController.start();
      _canScan = true; // Reset scan flag
    });
  }

  Future<void> _initializeSoundPlayer() async {
    await _soundPlayer
        .openPlayer(); // Corrected method for opening audio session
  }

  Future<void> _fetchProductDetails(String barcode) async {
    final token = _storage.read('token') as String?;
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://iscandata.com/api/v1/products/$barcode'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        final productData = responseBody['data']['product'];
        await _playBeepSound();
        if (productData != null) {
          _upcController.text = barcode;
          _upcColor = Colors.black;
          _departmentController.text = productData['department']['name']?.toString() ?? '000';
          _priceController.text = productData['price']?.toString() ?? '0.00';
          _descriptionController.text = productData['description'] ?? 'No description';
          _productFound = true;
          setState(() {
            _isScanning = true;
          });
          _scannerController.stop();
          Future.delayed(Duration(milliseconds: 500), () {
            _scannerController.start();
          });
        } else {
          _showProductNotFoundAlert(barcode);
          _productFound = false;
          _upcController.text = barcode;
          _upcColor = Colors.red;
        }
      } else {
        _showProductNotFoundAlert(barcode);
        _productFound = false;
        _upcController.text = barcode;
        _upcColor = Colors.red;
        print('Error: ${responseBody['message']}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  void _endZone() {
    // Notify the parent widget that the zone has been ended
    if (widget.onZoneEnded != null) {
      widget.onZoneEnded!(widget.zoneId, widget.sessionId); // Pass both zoneId and sessionId
    }

    // Show success message
    _showSnackbar('Zone ended successfully.', Colors.blue);

    // Optionally, navigate back or perform other actions
    Navigator.of(context).pop();
  }
  //
  // Future<void> _fetchProductDetails(String barcode) async {
  //   final token = _storage.read('token') as String?;
  //   if (token == null) return;
  //
  //   try {
  //     final response = await http.get(
  //       Uri.parse('https://iscandata.com/api/v1/products/$barcode'),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //       },
  //     );
  //
  //     final responseBody = jsonDecode(response.body);
  //
  //     if (response.statusCode == 200 && responseBody['status'] == 'success') {
  //       final productData = responseBody['data']['product'];
  //       await _playBeepSound();
  //       if (productData != null) {
  //         _upcController.text =
  //             barcode; // Set the UPC text field with the scanned barcode
  //         _upcColor = Colors.black; // Reset color to black
  //         _departmentController.text =
  //             productData['department']['id']?.toString() ?? '000';
  //         _priceController.text = productData['price']?.toString() ?? '0.00';
  //         _descriptionController.text =
  //             productData['description'] ?? 'No description';
  //         _productFound = true;
  //         setState(() {
  //           _isScanning =
  //           true; // Set _isScanning to true after a successful scan
  //         });
  //         _scannerController.stop(); // Stop the scanner
  //         Future.delayed(Duration(milliseconds: 500), () {
  //           _scannerController.start(); // Restart the scanner after a delay
  //         });
  //       } else {
  //         setState(() {
  //           productData == null;
  //         });
  //
  //         _productFound = false;
  //         _upcController.text =
  //             barcode; // Set the UPC text field with the scanned barcode
  //         _upcColor = Colors.red; // Set UPC text field color to red
  //       }
  //     } else {
  //
  //       _productFound = false;
  //       _upcController.text =
  //           barcode; // Set the UPC text field with the scanned barcode
  //       _upcColor = Colors.red; // Set UPC text field color to red
  //       print('Error: ${responseBody['message']}'); // Log API error message
  //     }
  //   } catch (e) {
  //     _productFound = false;
  //     _upcController.text =
  //         barcode; // Set the UPC text field with the scanned barcode
  //     _upcColor = Colors.red; // Set UPC text field color to red
  //     print('Error fetching product details: $e');
  //   }
  // }
  // Show Alert if Product Not Found
  void _showProductNotFoundAlert(String barcode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Product Not Found'),
          content: Text('The UPC $barcode could not be found. Please enter the details manually.'),
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
  // Fetch departments from API using http package
  Future<List<Department>> fetchDepartments(String query) async {
    final token = _storage.read('token') as String?;
    final response = await http.get(
      Uri.parse('https://iscandata.com/api/v1/departments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        List departments = data['data']['departments'];
        return departments
            .map((dept) => Department.fromJson(dept))
            .where((dept) => dept.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        throw Exception('Failed to load departments');
      }
    } else {
      throw Exception('Error fetching departments: ${response.reasonPhrase}');
    }
  }
  void _showSnackbar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: Duration(seconds: 3), // Adjust duration as needed
    );

    // Show the Snackbar
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _submitScan() async {
    final token = _storage.read('token') as String?;
    if (token == null || widget.sessionId.isEmpty || widget.zoneId.isEmpty)
      return;

    try {
      final response = await http.post(
        Uri.parse('https://iscandata.com/api/v1/scans/scan'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "upc": _upcController.text,
          "quantity": _quantityController.text,
          "department": _selectedDepartment?.id ?? _departmentController.text,
          "price": _priceController.text,
          "description": _descriptionController.text,
          "selectedZone": widget.zoneId,
          "selectedZone": widget.zoneId,
          "sessionId": widget.sessionId,
        }),
      );

      if (response.statusCode == 201) {
        // Play beep sound on successful scan
        // _showAlert('Scan submitted successfully!');
        _showSnackbar(
            'Scan successfully submitted and stored in Database. For more info, see Reports.',
            Colors.green);
        _resetFields();
        // Clear previous data from text fields
        _upcController.clear();
        // _quantityController.clear();
        _quantityController.text = '1'; // Reset to default quantity of 1
        _departmentController.clear();
        _priceController.clear();
        _descriptionController.clear();
      } else {
        print('Failed to submit scan: ${response.body}'); // Log failure reason
        _showAlert('Failed to submit scan.');
        _upcController.clear();
        // _quantityController.clear();
        _quantityController.text = '1'; // Reset to default quantity of 1
        _departmentController.clear();
        _priceController.clear();
        _descriptionController.clear();
      }
    } catch (e) {
      print('An error occurred while submitting the scan ! : $e');
    }
  }

  Future<void> _playBeepSound() async {
    try {
      // Load the beep.mp3 file from the assets folder
      final byteData = await rootBundle.load('assets/beep.mp3');

      // Get a temporary directory to store the beep sound
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/beep.mp3');

      // Write the audio file to the temp directory
      await tempFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      // Play the sound using the temporary file path
      await _soundPlayer.startPlayer(
        fromURI: tempFile.path, // Use the file path from the temp directory
        codec: Codec.mp3, // Specify the codec based on your audio file type
      );
    } catch (e) {
      print('Error playing beep sound: $e');
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _endSession() async {
    final token = _storage.read('token') as String?;
    if (token == null || widget.sessionId.isEmpty || widget.zoneId.isEmpty) {
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
          "sessionId": widget.sessionId,
          "selectedZone": widget.zoneId,
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
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close the dialog
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
        String startTime = reportData['session']['startScanTime'] ?? 'N/A'; // Get start time
        String endTime = reportData['session']['endScanTime'] ?? 'N/A'; // Get end time
        String timeTakenStr = _calculateTimeDifference(startTime, endTime); // Calculate time taken

        // Add session details to XML
        builder.element('SessionDetails', nest: () {
          builder.element('StartTime', nest: startTime);
          builder.element('EndTime', nest: endTime);
          builder.element('TimeTaken', nest: timeTakenStr);
        });

        // Detail Zones Report
        builder.element('DetailZonesReport', nest: () {
          builder.element('Header', nest: 'Zone Name, UPC, Product Description, Quantity, Total Price');
          final List<dynamic> scans = reportData['scans'];
          for (var scan in scans) {
            var zone = scan['zone']['name'] ?? 'Unknown Zone';
            double quantity = (scan['quantity'] is int) ? (scan['quantity'] as int).toDouble() : (scan['quantity'] ?? 0.0);
            double totalPrice = (scan['totalPrice'] is int) ? (scan['totalPrice'] as int).toDouble() : (scan['totalPrice'] ?? 0.0);
            builder.element('Scan', nest: () {
              builder.element('ZoneName', nest: zone);
              builder.element('UPC', nest: scan['upc']);
              builder.element('ProductDescription', nest: scan['productDescription']);
              builder.element('Quantity', nest: quantity.toString());
              builder.element('TotalPrice', nest: totalPrice.toString());
            });
          }
        });

        // Zones General Report
        builder.element('ZonesGeneralReport', nest: () {
          builder.element('Header', nest: 'Zone Name, Total Quantity, Total Retail');
          Map<String, Map<String, dynamic>> zonesSummary = {};
          final List<dynamic> scans = reportData['scans'];
          for (var scan in scans) {
            String zoneName = scan['zone']['name'];
            double quantity = (scan['quantity'] is int) ? (scan['quantity'] as int).toDouble() : (scan['quantity'] ?? 0.0);
            double totalPrice = (scan['totalPrice'] is int) ? (scan['totalPrice'] as int).toDouble() : (scan['totalPrice'] ?? 0.0);
            if (!zonesSummary.containsKey(zoneName)) {
              zonesSummary[zoneName] = {'totalQty': 0.0, 'totalRetail': 0.0};
            }
            zonesSummary[zoneName]!['totalQty'] += quantity;
            zonesSummary[zoneName]!['totalRetail'] += totalPrice;
          }
          zonesSummary.forEach((zoneName, summary) {
            builder.element('Zone', nest: () {
              builder.element('ZoneName', nest: zoneName);
              builder.element('TotalQuantity', nest: summary['totalQty'].toString());
              builder.element('TotalRetail', nest: summary['totalRetail'].toString());
            });
          });
        });

        // Department General Report
        builder.element('DepartmentGeneralReport', nest: () {
          builder.element('Header', nest: 'Department Name, Total Quantity, Total Retail');
          Map<String, Map<String, dynamic>> departmentSummary = {};
          final List<dynamic> scans = reportData['scans'];
          for (var scan in scans) {
            String departmentName = scan['department']['name'];
            double quantity = (scan['quantity'] is int) ? (scan['quantity'] as int).toDouble() : (scan['quantity'] ?? 0.0);
            double totalPrice = (scan['totalPrice'] is int) ? (scan['totalPrice'] as int).toDouble() : (scan['totalPrice'] ?? 0.0);
            if (!departmentSummary.containsKey(departmentName)) {
              departmentSummary[departmentName] = {'totalQty': 0.0, 'totalRetail': 0.0};
          }
          departmentSummary[departmentName]!['totalQty'] += quantity;
          departmentSummary[departmentName]!['totalRetail'] += totalPrice;
          }
          departmentSummary.forEach((deptName, summary) {
          builder.element('Department', nest: () {
          builder.element('DepartmentName', nest: deptName);
          builder.element('TotalQuantity', nest: summary['totalQty'].toString());
          builder.element('TotalRetail', nest: summary['totalRetail'].toString());
          });
          });
        });

        // N.O.F. Report
        builder.element('NofReport', nest: () {
          builder.element('Header', nest: 'Department Name, UPC, Quantity, Retail Price, Total Retail');
          final List<dynamic> scans = reportData['scans'];
          for (var scan in scans) {
            double quantity = (scan['quantity'] is int) ? (scan['quantity'] as int).toDouble() : (scan['quantity'] ?? 0.0);
            double price = (scan['price'] is int) ? (scan['price'] as int).toDouble() : (scan['price'] ?? 0.0);
            double totalPrice = (scan['totalPrice'] is int) ? (scan['totalPrice'] as int).toDouble() : (scan['totalPrice'] ?? 0.0);
            builder.element('Scan', nest: () {
              builder.element('DepartmentName', nest: scan['department']['name']);
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
  Future<bool> _generatePDF(List<ScannedItem> scannedItems, String startTime, String endTime, String timeTakenStr) async {
    try {
      final pdf = pw.Document();

      // Add session details and scanned items to the PDF using MultiPage for automatic pagination
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Scan Session Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Text('Date: ${DateTime.now().toLocal().toString().split(' ')[0]}', style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 10),
                  pw.Text('Start Time: $startTime', style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 10),
                  pw.Text('End Time: $endTime', style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 20),
                  pw.Text('Time Taken: $timeTakenStr seconds', style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 20),
                ],
              ),
            ),

            // Detail Zones Report
            pw.Text('Detail Zones Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...scannedItems.map((item) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Zone Name: ${item.department}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('UPC: ${item.upc}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Product Description: ${item.department}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Quantity: ${item.quantity}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Total Price: \$${item.totalPrice.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 10),
                ],
              );
            }).toList(),

            // Zones General Report
            pw.SizedBox(height: 20),
            pw.Text('Zones General Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...scannedItems.map((item) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Zone Name: ${item.department}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Total Quantity: ${item.quantity}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Total Retail: \$${item.totalPrice.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 10),
                ],
              );
            }).toList(),

            // Department General Report
            pw.SizedBox(height: 20),
            pw.Text('Department General Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...scannedItems.map((item) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Department Name: ${item.department}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Total Quantity: ${item.quantity}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Total Retail: \$${item.totalPrice.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 10),
                ],
              );
            }).toList(),

            // N.O.F. Report
            pw.SizedBox(height: 20),
            pw.Text('N.O.F. Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...scannedItems.map((item) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Department Name: ${item.department}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('UPC: ${item.upc}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Quantity: ${item.quantity}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Retail Price: \$${item.price.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Total Retail: \$${item.totalPrice.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
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
      final fileName = 'scan_session_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '$selectedDirectory/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Store the selected path in GetStorage
      storage.write('downloadPath', selectedDirectory);

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
      storage.write('downloadPath', selectedDirectory);

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
                      Navigator.of(context).pop(); // Close the dialog
                      Navigator.of(context).pop(); // Close the dialog
                      Navigator.of(context).pop();// Close the bottom sheet
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
                  if (reportData['scans'] != null && reportData['scans'] is List) {
                    print(reportData['scans']);
                    List<ScannedItem> scannedItems = (reportData['scans'] as List).map((item) {
                      if (item is Map<String, dynamic>) {
                        return ScannedItem(
                          upc: item['upc'] ?? 'Unknown',
                          quantity: item['quantity'] ?? 0,
                          department: item['department'] != null && item['department'] is Map ? (item['department']['name'] ?? 'Unknown Department') : 'Unknown Department',
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
                    String startTime = reportData['session']['startScanTime'] ?? 'N/A';
                    String endTime = reportData['session']['endScanTime'] ?? 'N/A';
                    final String timeTakenStr = _calculateTimeDifference(startTime, endTime);

                    bool success = await _generatePDF(scannedItems, startTime, endTime, timeTakenStr);
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
                  String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                  if (selectedDirectory != null) {
                    setState(() {
                      _downloadPath = selectedDirectory;
                      storage.write('downloadPath', selectedDirectory);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Download path changed to $selectedDirectory'),
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
  void _showEndSessionAlert(String timeTakenStr, List<ScannedItem> scannedItems, List<Map<String, dynamic>> tableData) {
    // Display the scanned items in a list or table
    // For example:
    String scannedItemsStr = '';
    for (ScannedItem item in scannedItems) {
      scannedItemsStr += 'UPC: ${item.upc}, De'
          'partment: ${item.department}, Quantity: ${item.quantity}, Price: ${item.price}\n';
    }
    _showAlert('Session ended successfully. Time taken: $timeTakenStr\nScanned Items:\n$scannedItemsStr');
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

  // Alert function to show the session end message


  Color _getFieldColor(TextEditingController controller) {
    if (controller.text.isEmpty) {
      return Colors.red.shade100; // Red color for empty fields
    } else if (productData == null) {
      return Colors.green.shade100; // Orange color if productData is null
    }
    return Colors.white; // Default color for valid fields
  }


  void _resetFields() {
    _upcController.clear();
    _quantityController.clear();
    _priceController.clear();
    _departmentController.clear();
    _descriptionController.clear();
    setState(() {
      _productFound = false; // Reset the product found flag
      _upcColor = Colors.black; // Reset UPC text color
    });
  }

  void _clearFields() {
    setState(() {
      _upcController.clear();
      _quantityController.text = '1'; // Reset quantity to default of 1
      _departmentController.clear();
      _priceController.clear();
      _descriptionController.clear();
    });
  }


  @override
  Widget build(BuildContext context) {
    return  WillPopScope(
      onWillPop: () async {
        // Show a confirmation dialog before allowing the pop
        final shouldPop = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Exit'),
            content: Text('Do you really want to go back?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // Don't pop
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // Allow pop
                child: Text('Yes'),
              ),
            ],
          ),
        );

        return shouldPop ?? false; // Return false if dialog is dismissed
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Barcode Scanner'),
        ),
        body: Column(
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: (barcodeCapture) {
                        if (_isScanning && barcodeCapture.barcodes.isNotEmpty) {
                          final String barcode = barcodeCapture.barcodes.first
                              .rawValue ?? '';
                          if (!_canScan) return;
                          _canScan = false;
                          setState(() {
                            _isScanning = true;
                          });
                          _fetchProductDetails(barcode);
                          Future.delayed(Duration(seconds: 6), () {
                            setState(() {
                              _canScan =
                              true; // Re-enable scanning after 6 seconds
                            });
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                //padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _upcController,
                        decoration: InputDecoration(
                          labelText: 'UPC',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: _getFieldColor(_upcController),
                        ),
                      ),
                      SizedBox(height: 16),

                      // TextField(
                      //   controller: _departmentController,
                      //   decoration: InputDecoration(
                      //     labelText: 'Department',
                      //     border: OutlineInputBorder(),
                      //     filled: true,
                      //     fillColor: _getFieldColor(_departmentController),
                      //   ),
                      //   readOnly: _productFound,
                      //   onTap: () {
                      //     if (_productFound) {
                      //       _showAlert('Cannot edit department field');
                      //     }
                      //   },
                      // ),

// Widget using DropdownSearch
                  TypeAheadFormField<Department>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _departmentController,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        hintText: 'Enter Department to search...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _departmentController.clear();
                          },
                        ),
                      ),
                    ),
                    suggestionsCallback: (pattern) async {
                      return await fetchDepartments(pattern);
                    },
                    itemBuilder: (context, Department suggestion) {
                      return ListTile(
                        leading: Icon(Icons.business, color: Colors.blueAccent),
                        title: Text(
                          suggestion.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text('ID: ${suggestion.id}', style: TextStyle(color: Colors.grey)),
                      );
                    },
                    onSuggestionSelected: (Department suggestion) {
                      _departmentController.text = suggestion.name; // Display name
                      _selectedDepartment = suggestion; // Store department object for ID access
                    },
                    noItemsFoundBuilder: (context) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'No departments found',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    suggestionsBoxDecoration: SuggestionsBoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      elevation: 4.0,
                      shadowColor: Colors.black38,
                    ),
                  ),
                  SizedBox(height: 10),

                      SizedBox(height: 16),
                      TextField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: _getFieldColor(_priceController),
                        ),
                        readOnly: _productFound,
                        onTap: () {
                          if (_productFound) {
                            _showAlert('Cannot edit price field');
                          }
                        },
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: _getFieldColor(_descriptionController),
                        ),
                        readOnly: _productFound,
                        onTap: () {
                          if (_productFound) {
                            _showAlert('Cannot edit description field');
                          }
                        },
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // "-" button
                          SizedBox(
                            width: 50,
                            height: 50, // Equal width and height for round shape
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  int currentQuantity = int.tryParse(
                                      _quantityController.text) ?? 1;
                                  if (currentQuantity > 1) {
                                    _quantityController.text =
                                        (currentQuantity - 1).toString();
                                  }
                                });
                              },
                              child: Icon(Icons.remove, color: Colors.black),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white, // White background
                                shape: CircleBorder(), // Round shape
                                elevation: 4, // Slight elevation for shadow effect
                                padding: EdgeInsets.all(8), // Padding for smooth UI
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          // Quantity TextField
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _quantityController,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: _getFieldColor(_quantityController),
                              ),
                              keyboardType: TextInputType.number,
                              onTap: () {
                                setState(() {
                                  _canScan = false; // Prevent scanning while entering quantity
                                });
                              },
                              onSubmitted: (value) {
                                setState(() {
                                  _canScan = true; // Allow scanning again after submitting quantity
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          // "+" button
                          SizedBox(
                            width: 50,
                            height: 50, // Equal width and height for round shape
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  int currentQuantity = int.tryParse(
                                      _quantityController.text) ?? 1;
                                  _quantityController.text =
                                      (currentQuantity + 1).toString();
                                });
                              },
                              child: Icon(Icons.add, color: Colors.black),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white, // White background
                                shape: CircleBorder(), // Round shape
                                elevation: 4, // Slight elevation for shadow effect
                                padding: EdgeInsets.all(8), // Padding for smooth UI
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16), // Add space before the buttons

                      // Buttons for End Session and Submit
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // End Scan Button
                          ElevatedButton(
                            onPressed: _endZone,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[300],
                            ),
                            child: Text(
                              'End Zone',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          // Submit Button
                          ElevatedButton(
                            onPressed: _submitScan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[300],
                            ),
                            child: Text(
                              'Submit',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          // End Session Button
                          IconButton(
                            icon: Icon(Icons.clear, color: Colors.red),
                            onPressed: _clearFields,
                            tooltip: 'Clear All Fields',
                            iconSize: 30,
                          ),
                        ],
                      ),
                      // ElevatedButton(
                      //   onPressed: _endSession,
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Colors.red[300],
                      //   ),
                      //   child: Text(
                      //     'End Session',
                      //     style: TextStyle(color: Colors.white),
                      //   ),
                      // ),

                      SizedBox(height: 20),



                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class ScannedItem {
  final String upc;
  final String department;
  final int quantity;
  final double price;
  final double totalPrice;

  ScannedItem({
    required this.upc,
    required this.department,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  @override
  String toString() {
    return 'UPC: $upc, Department: $department, Quantity: $quantity, Price: $price, Total Price: $totalPrice';
  }
}
class Department {
  final int id;
  final String name;

  Department({required this.id, required this.name});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  @override
  String toString() => name;
}