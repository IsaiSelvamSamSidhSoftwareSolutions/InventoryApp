import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'Manualdataenrty.dart';

class BarcodeScanPage extends StatefulWidget {
  @override
  _BarcodeScanPageState createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  final GetStorage _storage = GetStorage();
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  late bool isScanning = false;
  Map<String, String> zoneIdMap = {}; // Map for zone names and IDs
  String? selectedZoneId; // Selected zone ID
  String? sessionId; // Session ID for tracking the session
  String? departmentId; // Declare departmentId
  String? currentQuantity;
  @override
  void initState() {
    super.initState();
    _fetchZoneIds(); // Fetch zone IDs when initializing
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Define the _showBottomSheet method
  void _showBottomSheet(String message) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(message, style: TextStyle(fontSize: 18)),
        );
      },
    );
  }

  Future<void> _fetchZoneIds() async {
    final token = _storage.read('token') as String;
    try {
      final response = await http.get(
        Uri.parse('https://iscandata.com/api/v1/zones'),
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
          Navigator.of(context).pushReplacementNamed('/login'); // Adjust route name accordingly
        });
        return;
      } else {
        _showBottomSheet('Failed to fetch zones ,Make Sure You have Uploaded Product XML Files and added Zones');
      }
    } catch (e) {
      print('Error details: $e');
    }
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
          Navigator.of(context).pushReplacementNamed('/login'); // Adjust route name accordingly
        });
        return;
      } else {
        _showBottomSheet('Failed to start session');
      }
    } catch (e) {
      print('Error details: $e');
    }
  }

  void _showPopulatedTextField(String barcode) {

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('No product found for barcode: $barcode'),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _departmentController,
                decoration: InputDecoration(labelText: 'Department ID'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the bottom sheet
                  if (selectedZoneId != null) {
                    _submitScan(barcode, departmentId.toString(), _priceController.text,currentQuantity.toString()).then((_) {// Call to end session after scan
                    });
                  } else {
                    _showAlert('Please select a zone');
                  }
                },
                child: Text('Submit Data'),
              ),

            ],
          ),
        );
      },
    );
  }
  void _showSummaryBottomSheet(String upc, String departmentId, String price, String description) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Product UPC: $upc'),
              Text('Department ID: $departmentId'),
              Text('Price: $price'),
              Text('Description: $description'),
              SizedBox(height: 16.0),
              Row(
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      int currentQuantity = int.tryParse(_quantityController.text) ?? 1;
                      _quantityController.text = (currentQuantity - 1).toString();
                      // Fix: Ensure proper evaluation of the condition
                      if ((int.tryParse(_quantityController.text) ?? 1) < 1) {
                        _quantityController.text = '1';
                      }
                    },
                    child: Text('-'),
                  ),

                  SizedBox(width: 16.0),
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      int currentQuantity = int.tryParse(_quantityController.text) ?? 1;
                      _quantityController.text = (currentQuantity + 1).toString();
                    },
                    child: Text('+'),
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the bottom sheet
                  if (selectedZoneId != null) {
                    _submitScan(upc, departmentId.toString(), price ,currentQuantity.toString()).then((_) {// Call to end session after scan
                    });
                  } else {
                    _showAlert('Please select a zone');
                  }
                },
                child: Text('Submit Data'),
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _submitScan(String upc, String departmentId, String price, String quantityStr) async {
    final token = _storage.read('token') as String;
    if (sessionId == null) return;

    final quantityStr = _quantityController.text;
    final quantity = quantityStr.isNotEmpty ? int.tryParse(quantityStr) ?? 1 : 1;

    print('Submitting scan with UPC: $upc, Quantity: $quantity, Department ID: $departmentId, Price: $price');

    try {
      final response = await http.post(
        Uri.parse('https://iscandata.com/api/v1/scans/scan'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "upc": upc,
          "quantity": quantity.toString(),
          "department": departmentId,
          "price": price,
          "selectedZone": selectedZoneId,
          "sessionId": sessionId,
        }),
      );

      final responseBody = jsonDecode(response.body);
      print('Submit Scan Response: $responseBody');

      if (response.statusCode == 201) {
        _showAlert('Scan submitted successfully!');
        setState(() {
          isScanning = false;
        });
        _scannerController.stop();
      } else {
        print('Error: ${response.statusCode}');
        _showBottomSheet('Error: ${responseBody['message'] ?? 'Failed to submit scan'}');
      }
    } catch (e) {
      print('Error details: $e');
      _showBottomSheet('An error occurred while submitting the scan.');
    }
  }
  Future<void> _fetchProductDetails(String barcode) async {
    final token = _storage.read('token') as String;

    // Convert UPC-E to UPC-A if necessary
    String prefixedUPC = barcode.length == 8 ? convertUpcEToUpcA(barcode) : barcode;

    print('Prefixed UPC: $prefixedUPC');

    try {
      // Make the GET request
      final response = await http.get(
        Uri.parse('https://iscandata.com/api/v1/products/$prefixedUPC'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);
      print('Product Details Response: $responseBody');

      if (response.statusCode == 200) {
        if (responseBody['status'] == 'success') {
          final productData = responseBody['data']['product'] as Map<String, dynamic>?;

          if (productData != null) {
            // Handling department ID (converting int to String if necessary)
            final department = productData['department'] as Map<String, dynamic>? ?? {};
            final departmentId = (department['id'] is int)
                ? department['id'].toString()
                : department['id'] as String? ?? '000';

            // Handling price (checking if it's double or String)
            final price = productData['price'];
            final priceString = (price is double)
                ? price.toStringAsFixed(2)
                : price.toString();

            // Handling description
            final description = productData['description'] as String? ?? 'No description';

            // Show summary bottom sheet
            _showSummaryBottomSheet(prefixedUPC, departmentId, priceString, description);
          } else {
            _showBottomSheet('Product data is missing!');
          }
        } else {
          _showBottomSheet('Product not found!');
        }
      } else if (response.statusCode == 404) {
        _showPopulatedTextField(barcode);
      } else {
        print('Error: ${response.statusCode}');
        _showBottomSheet('Something went wrong! Please try again.');
      }
    } catch (e) {
      debugPrint('Error fetching product details: $e');
      _showBottomSheet('Error fetching product details. Please try again.');
    }
  }
  String convertUpcEToUpcA(String upcE) {
    // Check if the input length is 8, indicating it's a UPC-E
    if (upcE.length != 8) {
      // If not, return the original input as it might already be a valid UPC-A
      return upcE;
    }

    String upcA = '';

    // Extract the core UPC-E digits without the check digit
    String upcEWithoutCheckDigit = upcE.substring(0, 7);

    // Conversion logic for UPC-E to UPC-A
    if (upcE.startsWith('0')) {
      upcA = '00000' + upcEWithoutCheckDigit; // Leading zero for UPC-A
    } else {
      upcA = '0' + upcEWithoutCheckDigit; // Add a leading zero
    }

    // Calculate the check digit for UPC-A
    int sum = 0;
    for (int i = 0; i < upcA.length; i++) {
      int digit = int.parse(upcA[i]);
      if (i % 2 == 0) {
        sum += digit * 3; // Odd position
      } else {
        sum += digit; // Even position
      }
    }

    int checkDigit = (10 - (sum % 10)) % 10;
    upcA += checkDigit.toString(); // Append the check digit

    return upcA;
  }

  // Define the _showAlert method
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

  // Define the _showFailureBottomSheet method
  void _showFailureBottomSheet(String upc, String departmentId, String price) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Failed to submit scan for UPC: $upc'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showAlert('Please enter details manually.');
                },
                child: Text('Enter Details Manually'),
              ),
            ),
          ],
        );
      },
    );
  }
  Future<void> _endSession() async {
    final token = _storage.read('token') as String;
    if (sessionId == null || selectedZoneId == null) return;

    try {
      final response = await http.post(
        Uri.parse('https://iscandata.com/api/v1/sessions/scan/end'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "selectedZone": selectedZoneId,
          "sessionId": sessionId,
        }),
      );

      final responseBody = jsonDecode(response.body);
      print('End Session Response: $responseBody');

      if (response.statusCode == 200) {
        print('Session ended successfully!');
        setState(() {
          sessionId = null; // Clear session ID after ending
        });
      } else {
        print('Failed to end session.');
      }
    } catch (e) {
      print('Error details: $e');
      print('An error occurred while ending the session.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barcode Scan',style:TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          if (zoneIdMap.isNotEmpty)
            DropdownButton<String>(
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
                });
              },
            )
          else
            Center(child: Text('Fetching zones...')),
          SizedBox(height: 20),

          Expanded(
            child: selectedZoneId == null
                ? Center(child: Text('Please select a zone to start scanning and also \n ensure upload XML file is done before Scan' , style:TextStyle(

            ),))
                :  MobileScanner(
              controller: _scannerController,
              onDetect: (barcodeCapture) {
                if (barcodeCapture.barcodes.isNotEmpty && isScanning) {
                  final barcode = barcodeCapture.barcodes.first.rawValue;
                  if (barcode != null) {
                    setState(() {
                      isScanning = false;
                    });
                    _scannerController.stop();
                    print('Scanned Barcode: $barcode');
                    _fetchProductDetails(barcode);
                  }
                }
              },
            ),
          ),
          ElevatedButton(
            onPressed: selectedZoneId == null ? null : () {
              setState(() {
                isScanning = !isScanning;
                if (isScanning) {
                  _startSession();
                  _scannerController.start();
                } else {
                  _scannerController.stop();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // Set the button color to green
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Ensure the button size is not too large
              children: [
                Icon(isScanning ? Icons.stop : Icons.qr_code_scanner_outlined, color: Colors.white), // Change icon color if needed
                SizedBox(width: 8), // Add some space between the icon and text
                Text(
                  isScanning ? 'Stop Scanning' : 'Start Scanning',
                  style: TextStyle(color: Colors.white), // Set text color to white for contrast
                ),
              ],
            ),
          ),
          Container(
           child: Row(
             children: [
               Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: ElevatedButton(
                   onPressed: () {
                     _endSession();
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.red, // Background color
                   ),
                   child: Text(
                     "End Scan",
                     style: TextStyle(
                       color: Colors.white, // Text color
                       fontSize: 16,             // Font size
                       fontWeight: FontWeight.bold, // Optional: make the text bold
                     ),

                   ),
                 ),
               ),
               Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: ElevatedButton(
                   onPressed: () {
                     // Navigate to the ManualDataEntry page when the button is pressed
                     Navigator.push(
                       context,
                       MaterialPageRoute(builder: (context) => ManualDataEntry()),
                     );
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.lightBlueAccent, // Background color
                   ),
                   child: Text(
                     "Enter the Data Manually",
                     style: TextStyle(
                       color: Colors.white, // Text color
                       fontSize: 16,             // Font size
                       fontWeight: FontWeight.bold, // Optional: make the text bold
                     ),

                   ),
                 ),
               ),

             ],
           ),
         )
        ],
      ),
    );
  }
}
