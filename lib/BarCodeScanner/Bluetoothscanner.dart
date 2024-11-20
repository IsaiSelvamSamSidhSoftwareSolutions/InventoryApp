import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class Bluetoothscanner extends StatefulWidget {
  final String zoneId;
  final String sessionId;
  final Function? onZoneEnded;

  Bluetoothscanner({required this.zoneId, required this.sessionId, this.onZoneEnded});

  @override
  _BarcodeScanPageState createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<Bluetoothscanner> {
  final GetStorage _storage = GetStorage();
  final TextEditingController _upcController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final FlutterSoundPlayer _soundPlayer = FlutterSoundPlayer();
  bool _isProcessing = false;
  bool _productFound = false;
  FocusNode _focusNode = FocusNode();
  bool _canScan = true;
  bool _isScanning = true; // Control scanning state
  String? productData;
  Color _upcColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
    _initializeSoundPlayer();
    _focusNode.requestFocus(); // Automatically focus the UPC field on screen load
  }

  @override
  void dispose() {
    _upcController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _departmentController.dispose();
    _descriptionController.dispose();
    _soundPlayer.closePlayer();
    super.dispose();
  }

  Future<void> _initializeSoundPlayer() async {
    await _soundPlayer.openPlayer();
  }

  Future<void> _playBeepSound() async {
    try {
      final byteData = await rootBundle.load('assets/beep.mp3');
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/beep.mp3');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      await _soundPlayer.startPlayer(fromURI: tempFile.path, codec: Codec.mp3);
    } catch (e) {
      print('Error playing beep sound: $e');
    }
  }

  Color _getFieldColor(TextEditingController controller) {
    if (controller.text.isEmpty) {
      return Colors.red.shade100; // Red color for empty fields
    } else if (productData == null) {
      return Colors.green.shade100; // Orange color if productData is null
    }
    return Colors.white; // Default color for valid fields
  }
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
  // void _endZone() {
  //   // Notify the parent widget that the zone has been ended
  //   if (widget.onZoneEnded != null) {
  //     widget.onZoneEnded!(widget.zoneId, widget.sessionId); // Pass both zoneId and sessionId
  //   }
  //
  //   // Show success message
  //   _showSnackbar('Zone ended successfully.', Colors.blue);
  //
  //   // Optionally, navigate back or perform other actions
  //   Navigator.of(context).pop();
  // }
  void _endZone({bool fromBluetooth = false}) {
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

          Future.delayed(Duration(milliseconds: 500), () {

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

  Future<void> _submitScan() async {
    final token = _storage.read('token') as String?;
    if (token == null || widget.sessionId.isEmpty || widget.zoneId.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

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
        _showSnackbar('Scan successfully submitted.', Colors.green);
        _resetFields();
      } else {
        _showAlert('Failed to submit scan.');
      }
    } catch (e) {
      _showAlert('An error occurred while submitting the scan.');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
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
  void _resetFields() {
    _upcController.clear();
    _quantityController.text = '1';
    _priceController.clear();
    _departmentController.clear();
    _descriptionController.clear();
    _productFound = false;
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
  void _clearFields() {
    setState(() {
      _upcController.clear();
      _quantityController.text = '1'; // Reset quantity to default of 1
      _departmentController.clear();
      _priceController.clear();
      _descriptionController.clear();
    });
  }

  void _showSnackbar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barcode Scanner (Bluetooth)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              focusNode: _focusNode,
              controller: _upcController,
              decoration: InputDecoration(
                labelText: 'UPC',
                border: OutlineInputBorder(),
                suffixIcon: _isProcessing
                    ? CircularProgressIndicator()
                    : IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    if (_upcController.text.isNotEmpty) {
                      _fetchProductDetails(_upcController.text);
                    }
                  },
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _fetchProductDetails(value);
                }
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TypeAheadFormField(
              textFieldConfiguration: TextFieldConfiguration(
                controller: _departmentController,
                decoration: InputDecoration(
                  labelText: 'Department',
                  hintText: 'Search department...',
                  border: OutlineInputBorder(),
                ),
              ),
              suggestionsCallback: (pattern) async {
                return await fetchDepartments(pattern);
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion.toString()),
                );
              },
              onSuggestionSelected: (suggestion) {
                _departmentController.text = suggestion.toString();
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
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
                      //_endZone(); // Call the method to end the zone
                      _endZone(fromBluetooth: true);
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
      ]
        )
      ),
    );
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