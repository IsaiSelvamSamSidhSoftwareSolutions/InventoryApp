import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  await GetStorage.init(); // Ensure GetStorage is initialized
  runApp(ManualDataEntry());
}

class ManualDataEntry extends StatefulWidget {
  @override
  _ManualDataEntryState createState() => _ManualDataEntryState();
}

class _ManualDataEntryState extends State<ManualDataEntry> {
  final _storage = GetStorage();
  final _upcController = TextEditingController();
  final _quantityController = TextEditingController();
  final _departmentController = TextEditingController();
  final _priceController = TextEditingController();

  bool isLoading = true; // Loading state for zones
  bool isSubmitting = false; // Loading state for submitting scan data
  Map<String, String> zoneIdMap = {}; // Map for zone names and IDs
  String? selectedZoneId; // Selected zone ID
  String? sessionId; // Session ID for tracking the session
  Dio dio = Dio(); // Create a Dio instance

  @override
  void initState() {
    super.initState();
    _fetchZoneIds(); // Fetch zone IDs when initializing
  }

  @override
  void dispose() {
    _upcController.dispose();
    _quantityController.dispose();
    _departmentController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _fetchZoneIds() async {
    final token = _storage.read('token') as String;
    setState(() {
      isLoading = true;
    });

    try {
      final response = await dio.get(
        'https://iscandata.com/api/v1/zones',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      final responseBody = response.data;
      print('Fetch Zones Response: $responseBody');

      if (responseBody['status'] == 'success') {
        final zonesData = responseBody['data']['zones'] as List;
        setState(() {
          zoneIdMap = {
            for (var zone in zonesData) zone['name']: zone['_id'],
          };
          selectedZoneId = zoneIdMap.isNotEmpty ? zoneIdMap.values.first : null;
          _startSession(); // Start the session after fetching zone IDs
        });
      } else if (response.statusCode == 401) {
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pushReplacementNamed('/login');
        });
        return;
      } else {
        print('Failed to fetch zones');
      }
    } catch (e) {
      print('Error fetching zones: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _startSession() async {
    final token = _storage.read('token') as String;
    try {
      final response = await dio.post(
        'https://iscandata.com/api/v1/sessions/scan/start',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {"selectedZone": selectedZoneId},
      );
      final responseBody = response.data;
      print('Start Session Response: $responseBody');

      if (responseBody['status'] == 'success') {
        setState(() {
          sessionId = responseBody['sessionId'];
        });
        print('Session ID: $sessionId');
      } else if (response.statusCode == 401) {
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pushReplacementNamed('/login');
        });
        return;
      } else {
        print('Failed to start session');
      }
    } catch (e) {
      print('Error starting session: $e');
    }
  }
  Future<void> _submitScanData() async {
    if (sessionId == null || selectedZoneId == null) {
      print('Session ID or selected zone is missing.');
      return;
    }

    final token = _storage.read('token') as String;

    if (_upcController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _departmentController.text.isEmpty ||
        _priceController.text.isEmpty) {
      _showAlert('Please fill out all the fields');
      return;
    }

    // Print data to be sent
    debugPrint('Preparing to submit scan data with the following details:');
    debugPrint('UPC: ${_upcController.text}');
    debugPrint('Quantity: ${_quantityController.text}');
    debugPrint('Department: ${_departmentController.text}');
    debugPrint('Price: ${_priceController.text}');
    debugPrint('Selected Zone: $selectedZoneId');
    debugPrint('Session ID: $sessionId');

    setState(() {
      isSubmitting = true;
    });

    try {
      final response = await dio.post(
        'https://iscandata.com/api/v1/scans/scan',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'upc': _upcController.text,
          'quantity': _quantityController.text,
          'department': _departmentController.text,
          'price': _priceController.text,
          'selectedZone': selectedZoneId, // Update field name to match API
          'sessionId': sessionId,
        },
      );

      final responseBody = response.data;
      debugPrint('Submit Scan Data Response: $responseBody');

      if (response.statusCode == 201) {
        _showAlert('Data submitted successfully');
      } else {
        print('Failed to submit data: ${responseBody['message']}');
      }
    } catch (e) {
      if (e is DioError) {
        debugPrint('DioError: ${e.message}');
        if (e.response != null) {
          debugPrint('DioError Response Data: ${e.response?.data}');
          debugPrint('DioError Response Headers: ${e.response?.headers}');
          debugPrint('DioError Response Status Code: ${e.response?.statusCode}');
          print('Error ${e.response?.statusCode}: ${e.response?.data}');
        }
      } else {
        debugPrint('Error submitting scan data: $e');
        _showAlert('An unexpected error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }


  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Alert'),
          content: Text(message),
          actions: <Widget>[
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manual Data Entry' ,style:TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isLoading
                ? Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
              value: selectedZoneId,
              items: zoneIdMap.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.value,
                  child: Text(entry.key),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedZoneId = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Select Zone',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            _buildTextField(_upcController, 'UPC', TextInputType.text),
            SizedBox(height: 16),
            _buildTextField(
                _quantityController, 'Quantity', TextInputType.number),
            SizedBox(height: 16),
            _buildTextField(
                _departmentController, 'Department', TextInputType.text),
            SizedBox(height: 16),
            _buildTextField(_priceController, 'Price',
                TextInputType.numberWithOptions(decimal: true)),
            SizedBox(height: 20),
            isSubmitting
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _submitScanData,
              child: Text('Submit Scan Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      TextInputType keyboardType) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
    );
  }
}
