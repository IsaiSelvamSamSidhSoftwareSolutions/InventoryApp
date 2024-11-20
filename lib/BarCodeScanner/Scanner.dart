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
import 'Bluetoothscanner.dart';
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
  Future<bool> _showEndZoneConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('End Zone'),
          content: Text(
            'Do you want to end this zone? If you end the zone, you can either end the inventory or select another zone from the dropdown menu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('End Zone'),
            ),
          ],
        );
      },
    ) ??
        false; // Default to false if the dialog is dismissed
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
               // _endSession(); // End the session
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

  void _clearFields() {
    setState(() {
      _upcController.clear();
      _quantityController.text = '1'; // Reset quantity to default of 1
      _departmentController.clear();
      _priceController.clear();
      _descriptionController.clear();
    });
  }
  Widget _buildToggleButton(BuildContext context,
      {required String label, required bool isSelected, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: isSelected ? null : onPressed, // Disable tap if selected
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent, // Highlight active button
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey, // Border for inactive buttons
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black, // Text color based on state
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
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
        appBar:AppBar(
          title: Text('Scanner'),
          centerTitle: true,
          actions: [
            Container(
              margin: EdgeInsets.only(right: 16), // Add some margin for aesthetics
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.grey[200], // Light background for the toggle container
              ),
              padding: EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildToggleButton(
                    context,
                    label: "Mobile Scanner",
                    isSelected: widget is BarcodeScanPage,
                    onPressed: () {
                      if (widget is! BarcodeScanPage) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BarcodeScanPage(
                              zoneId: widget.zoneId,
                              sessionId: widget.sessionId,
                              onZoneEnded: widget.onZoneEnded,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _buildToggleButton(
                    context,
                    label: "Bluetooth Scanner",
                    isSelected: widget is Bluetoothscanner,
                    onPressed: () {
                      if (widget is! Bluetoothscanner) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Bluetoothscanner(
                              zoneId: widget.zoneId,
                              sessionId: widget.sessionId,
                              onZoneEnded: widget.onZoneEnded,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
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
                            onPressed: () async {
                              bool confirm = await _showEndZoneConfirmation();
                              if (confirm) {
                                _endZone(); // Call the method to end the zone
                              }
                            },
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
  final bool notOnFile; // Add this property

  ScannedItem({
    required this.upc,
    required this.department,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    required this.notOnFile, // Initialize this property
  });

  @override
  String toString() {
    return 'UPC: $upc, Department: $department, Quantity: $quantity, Price: $price, Total Price: $totalPrice ,Not on File: $notOnFile';
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