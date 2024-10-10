import 'dart:convert';
import 'dart:io'; // For File handling
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart'; // Importing Flutter Sound
import 'package:path_provider/path_provider.dart'; // For temp directory access
import 'package:flutter/services.dart'; // For rootBundle access

class BarcodeScanPage extends StatefulWidget {
  final String zoneId;
  final String sessionId;

  BarcodeScanPage({required this.zoneId, required this.sessionId});

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
  bool _isScanning = true; // Control scanning state
  bool _productFound = false;
  bool _canScan = true;
  String? productData;
  Color _upcColor = Colors.black;
  final GlobalKey<FormState> _formKey = GlobalKey<
      FormState>(); // Color for UPC text field

  // Initialize FlutterSoundPlayer
  final FlutterSoundPlayer _soundPlayer = FlutterSoundPlayer();

  @override
  void initState() {
    super.initState();
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
          _upcController.text =
              barcode; // Set the UPC text field with the scanned barcode
          _upcColor = Colors.black; // Reset color to black
          _departmentController.text =
              productData['department']['id']?.toString() ?? '000';
          _priceController.text = productData['price']?.toString() ?? '0.00';
          _descriptionController.text =
              productData['description'] ?? 'No description';
          _productFound = true;
        } else {
          setState(() {
            productData == null;
          });
          _productFound = false;
          _upcController.text =
              barcode; // Set the UPC text field with the scanned barcode
          _upcColor = Colors.red; // Set UPC text field color to red
        }
      } else {
        _productFound = false;
        _upcController.text =
            barcode; // Set the UPC text field with the scanned barcode
        _upcColor = Colors.red; // Set UPC text field color to red
        print('Error: ${responseBody['message']}'); // Log API error message
      }
    } catch (e) {
      _productFound = false;
      _upcController.text =
          barcode; // Set the UPC text field with the scanned barcode
      _upcColor = Colors.red; // Set UPC text field color to red
      print('Error fetching product details: $e');
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
          "department": _departmentController.text,
          "price": _priceController.text,
          "description": _descriptionController.text,
          "selectedZone": widget.zoneId,
          "sessionId": widget.sessionId,
        }),
      );

      if (response.statusCode == 201) {
        // Play beep sound on successful scan
       // _showAlert('Scan submitted successfully!');
        _showSnackbar('Scan successfully submitted and stored in Database. For more info, see Reports.', Colors.green);
        _resetFields();
        // Clear previous data from text fields
        _upcController.clear();
        _quantityController.clear();
        _departmentController.clear();
        _priceController.clear();
        _descriptionController.clear();
      } else {
        print('Failed to submit scan: ${response.body}'); // Log failure reason
        _showAlert('Failed to submit scan.');
        _upcController.clear();
        _quantityController.clear();
        _departmentController.clear();
        _priceController.clear();
        _descriptionController.clear();
      }
    } catch (e) {
      print('An error occurred while submitting the scan: $e');
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
        // Extract start and end scan times
        final String startScanTime = responseBody['session']['startScanTime'];
        final String endScanTime = responseBody['session']['endScanTime'];

        // Calculate the time difference between start and end times
        final String timeTakenStr = _calculateTimeDifference(
            startScanTime, endScanTime);

        // Show the custom alert with total time taken
        _showEndSessionAlert(timeTakenStr);
      } else {
        print('Failed to end session: ${responseBody['message']}');
        _showAlert('Failed to end session.');
      }
    } catch (e) {
      print('Error ending session: $e');
      _showAlert('An error occurred while ending the session.');
    }
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
  void _showEndSessionAlert(String timeTaken) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Session Ended'),
          content: Text(
            'Total Time Taken: $timeTaken\n\nThank you! Please choose a zone and start scanning for your next session.\nYou will be redirecting to the zone selection page.',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

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
                          setState(() {});
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
                padding: const EdgeInsets.all(16.0),
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
                    TextField(
                      controller: _departmentController,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: _getFieldColor(_departmentController),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: _getFieldColor(_priceController),
                      ),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _endSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[300],
                          ),
                          child: Text(
                              'End Session', style: TextStyle(color: Colors
                              .white)),
                        ),
                        ElevatedButton(
                          onPressed: _submitScan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[300],
                          ),
                          child: Text('Submit', style: TextStyle(color: Colors
                              .white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
            ),
      );
  }
}

//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Barcode Scanner'),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 1,
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Stack(
//                 children: [
//                   MobileScanner(
//                     controller: _scannerController,
//                     onDetect: (barcodeCapture) {
//                       if (_isScanning && barcodeCapture.barcodes.isNotEmpty) {
//                         final String barcode = barcodeCapture.barcodes.first
//                             .rawValue ?? '';
//                         if (!_canScan) return;
//                         _canScan = false;
//                         setState(() {});
//                         _fetchProductDetails(barcode);
//                         Future.delayed(Duration(seconds: 6), () {
//                           setState(() {
//
//                             _canScan =
//                             true; // Re-enable scanning after 6 seconds
//                           });
//                         });
//                       }
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   TextField(
//                     controller: _upcController,
//                     decoration: InputDecoration(
//                       labelText: 'UPC',
//                       border: OutlineInputBorder(),
//                       filled: true,
//                       fillColor: _getFieldColor(_upcController),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   TextField(
//                     controller: _quantityController,
//                     decoration: InputDecoration(
//                       labelText: 'Quantity',
//                       border: OutlineInputBorder(),
//                       filled: true,
//                       fillColor: _getFieldColor(_quantityController),
//                     ),
//                     keyboardType: TextInputType.number,
//                   ),
//                   SizedBox(height: 16),
//                   TextField(
//                     controller: _departmentController,
//                     decoration: InputDecoration(
//                       labelText: 'Department',
//                       border: OutlineInputBorder(),
//                       filled: true,
//                       fillColor: _getFieldColor(_departmentController),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   TextField(
//                     controller: _priceController,
//                     decoration: InputDecoration(
//                       labelText: 'Price',
//                       border: OutlineInputBorder(),
//                       filled: true,
//                       fillColor: _getFieldColor(_priceController),
//                     ),
//                     keyboardType: TextInputType.number,
//                   ),
//                   SizedBox(height: 16),
//                   TextField(
//                     controller: _descriptionController,
//                     decoration: InputDecoration(
//                       labelText: 'Description',
//                       border: OutlineInputBorder(),
//                       filled: true,
//                       fillColor: _getFieldColor(_descriptionController),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       ElevatedButton(
//                         onPressed: _endSession,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red[300],
//                         ),
//                         child: Text(
//                             'End Session', style: TextStyle(color: Colors
//                             .white)),
//                       ),
//                       ElevatedButton(
//                         onPressed: _submitScan,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue[300],
//                         ),
//                         child: Text('Submit', style: TextStyle(color: Colors
//                             .white)),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Barcode Scanner'),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 1,
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Stack(
//                 children: [
//                   MobileScanner(
//                     controller: _scannerController,
//                     onDetect: (barcodeCapture) {
//                       if (_isScanning && barcodeCapture.barcodes.isNotEmpty) {
//                         final String barcode = barcodeCapture.barcodes.first
//                             .rawValue ?? '';
//                         if (!_canScan) return;
//                         _canScan = false;
//                         setState(() {});
//                         _fetchProductDetails(barcode);
//                         Future.delayed(Duration(seconds: 6), () {
//                           setState(() {
//                             _canScan =
//                             true; // Re-enable scanning after 6 seconds
//                           });
//                         });
//                       }
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   TextField(
//                     controller: _upcController,
//                     decoration: InputDecoration(
//                       labelText: 'UPC',
//                       border: OutlineInputBorder(),
//                       filled: true,
//                       fillColor: _getFieldColor(_upcController),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   TextField(
//                     controller: _departmentController,
//                     decoration: InputDecoration(
//                       labelText: 'Department',
//                       border: OutlineInputBorder(),
//                       filled: true,
//                       fillColor: _getFieldColor(_departmentController),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   TextField(
//                     controller: _priceController,
//                     decoration: InputDecoration(
//                       labelText: 'Price',
//                       border: OutlineInputBorder(),
//                       filled: true,
//                       fillColor: _getFieldColor(_priceController),
//                     ),
//                     keyboardType: TextInputType.number,
//                   ),
//                   SizedBox(height: 16),
//                   TextField(
//                     controller: _descriptionController,
//                     decoration: InputDecoration(
//                       labelText: 'Description',
//                       border: OutlineInputBorder(),
//                       filled: true,
//                       fillColor: _getFieldColor(_descriptionController),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     // Center the entire row
//                     children: [
//                       // "-" button
//                       SizedBox(
//                         width: 60,
//                         height: 50, // Adjust the height if needed
//                         child: ElevatedButton(
//                           onPressed: () {
//                             setState(() {
//                               int currentQuantity = int.tryParse(
//                                   _quantityController.text) ?? 1;
//                               if (currentQuantity > 1) {
//                                 _quantityController.text =
//                                     (currentQuantity - 1).toString();
//                               }
//                             });
//                           },
//                           child: Icon(Icons.remove, color: Colors.white),
//                           // Directly center icon
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.redAccent,
//                             shape: RoundedRectangleBorder( // Make the button a bit rounded
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 16),
//                       // Space between "-" button and text field
//                       // Centered Quantity TextField
//                       SizedBox(
//                         width: 120,
//                         // Make the text field wider for better appearance
//                         child: TextField(
//                           controller: _quantityController,
//                           textAlign: TextAlign.center,
//                           // Center text inside the field
//                           decoration: InputDecoration(
//                             labelText: 'Quantity',
//                             border: OutlineInputBorder(),
//                             filled: true,
//                             fillColor: _getFieldColor(_quantityController),
//                           ),
//                           keyboardType: TextInputType.number,
//                         ),
//                       ),
//                       SizedBox(width: 16),
//                       // Space between text field and "+" button
//                       // "+" button
//                       SizedBox(
//                         width: 60,
//                         height: 50, // Adjust the height if needed
//                         child: ElevatedButton(
//                           onPressed: () {
//                             setState(() {
//                               int currentQuantity = int.tryParse(
//                                   _quantityController.text) ?? 1;
//                               _quantityController.text =
//                                   (currentQuantity + 1).toString();
//                             });
//                           },
//                           child: Icon(Icons.add, color: Colors.white),
//                           // Directly center icon
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.greenAccent,
//                             shape: RoundedRectangleBorder( // Make the button a bit rounded
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//
//
//                   SizedBox(height: 16), // Add space before the buttons
//
//                   // Buttons for End Session and Submit
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       ElevatedButton(
//                         onPressed: _endSession,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red[300],
//                         ),
//                         child: Text(
//                             'End Session', style: TextStyle(color: Colors
//                             .white)),
//                       ),
//                       ElevatedButton(
//                         onPressed: _submitScan,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue[300],
//                         ),
//                         child: Text('Submit', style: TextStyle(color: Colors
//                             .white)),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }