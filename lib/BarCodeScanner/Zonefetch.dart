// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:get_storage/get_storage.dart';
// import 'Scanner.dart';// Ensure this import path is correct
// import 'package:inventary_app_production/ZonePage.dart';
// class ZoneSelectionScreen extends StatefulWidget {
//   @override
//   _ZoneSelectionScreenState createState() => _ZoneSelectionScreenState();
// }
//
// class _ZoneSelectionScreenState extends State<ZoneSelectionScreen> {
//   final _storage = GetStorage(); // Assuming GetStorage is being used
//   Map<String, String> zoneIdMap = {};
//   String? selectedZoneId;
//   String? sessionId;
//   @override
//   void initState() {
//     super.initState();
//     _fetchZoneIds();
//   }
//
//   Future<void> _fetchZoneIds() async {
//     final token = _storage.read('token') as String;
//     try {
//       final response = await http.get(
//         Uri.parse('https://iscandata.com/api/v1/zones/notUsedZones'),
//         headers: {
//           'Authorization': 'Bearer $token',
//         },
//       );
//       final responseBody = jsonDecode(response.body);
//       print('Fetch Zones Response: $responseBody');
//
//       if (responseBody['status'] == 'success') {
//         final zonesData = responseBody['data']['zones'] as List;
//         setState(() {
//           zoneIdMap = {
//             for (var zone in zonesData) zone['name']: zone['_id'],
//           };
//         });
//
//       } else if (response.statusCode == 401) {
//         Future.delayed(Duration(seconds: 2), () {
//           Navigator.of(context).pushReplacementNamed('/login'); // Adjust route name accordingly
//         });
//         return;
//        }
//       // else {
//       // //   _showBottomSheet('Failed to fetch zones. Make sure you have uploaded product XML files and added zones.');
//       // // }
//
//       else {
//         showModalBottomSheet(
//           context: context,
//           builder: (BuildContext context) {
//             return Padding(
//               padding: const EdgeInsets.all(20.0),
//
//               child: Column(
//
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     'Before scanning, you must add a zone.',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   Icon(
//                     Icons.warning_amber_rounded,
//                     size: 50,
//                     color: Colors.orangeAccent,
//                   ),
//                   SizedBox(height: 30),
//                   ElevatedButton.icon(
//
//                     onPressed: () {
//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(builder: (context) => ZonePage()), // Navigate directly to ZonePage
//                       ); // Navigate to your ZonePage using named route
//                     },
//                     icon: Icon(Icons.add_location_alt, color: Colors.white),
//                     label: Text(
//
//                       'Add Zone',
//                       style: TextStyle(
//                         fontSize: 15,
//                         color: Colors.white,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       padding: EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.blueAccent, // Button background color
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   Text(
//                     'Please ensure a zone is added before proceeding to scanning.',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey[700],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       }
//     } catch (e) {
//       print('Error details: $e');
//     }
//   }
//
//   void _showBottomSheet(String message) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Text(message),
//       ),
//     );
//   }
//   // Define the _showAlert method
//   void _showAlert(String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Alert'),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<void> _startSession() async {
//     if (selectedZoneId == null) {
//
//       _showAlert('Please select a zone before starting the session.');
//       return;
//     }
//
//     final token = _storage.read('token') as String;
//     try {
//       final response = await http.post(
//         Uri.parse('https://iscandata.com/api/v1/sessions/scan/start'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({"selectedZone": selectedZoneId}),
//       );
//       final responseBody = jsonDecode(response.body);
//       print('Start Session Response: $responseBody');
//
//       if (responseBody['status'] == 'success') {
//         setState(() {
//           sessionId = responseBody['sessionId'];
//         });
//         print('Session ID: $sessionId');
//       } else if (response.statusCode == 401) {
//         Future.delayed(Duration(seconds: 2), () {
//           Navigator.of(context).pushReplacementNamed(
//               '/login'); // Adjust route name accordingly
//         });
//         return;
//       } else {
//         _showBottomSheet('Failed to start session');
//       }
//     } catch (e) {
//       print('Error details of: $e');
//     }
//   }
//
//   void _navigateToScan() {
//     if (selectedZoneId != null && sessionId != null) {
//       // Navigate to BarcodeScanPage with actual selected zone ID and session ID
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => BarcodeScanPage(
//             zoneId: selectedZoneId!,  // Pass the selected zone ID
//             sessionId: sessionId!,    // Pass the session ID
//           ),
//         ),
//       );
//     } else {
//       _showAlert('Please select a zone and ensure the session has started.');
//     }
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//           title: Text('Select Zone' ,),
//           backgroundColor: Colors.blueAccent,
//       ),
//
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               if (zoneIdMap.isNotEmpty)
//                 Column(
//                   children: [
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: 10),
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.black54),
//                         borderRadius: BorderRadius.circular(5),
//                       ),
//                       child: DropdownButton<String>(
//                         isExpanded: true,
//                         value: selectedZoneId,
//                         hint: Text('Select Zone'),
//                         items: zoneIdMap.entries.map((entry) {
//                           return DropdownMenuItem<String>(
//                             value: entry.value,
//                             child: Text(entry.key),
//                           );
//                         }).toList(),
//                         onChanged: (value) {
//                           setState(() {
//                             selectedZoneId = value;
//                             print("Selected Zone ID -- $selectedZoneId");
//                           });
//                         },
//                       ),
//                     ),
//                     SizedBox(height: 20),
//                   ],
//                 )
//               else
//                 CircularProgressIndicator(),
//
//               GestureDetector(
//                 onTap: () async {
//                   // Start the session
//                   await _startSession();
//                   // Check if the session ID was successfully set
//                   if (sessionId != null) {
//                     _navigateToScan(); // Only navigate if session ID is not null
//                   }
//                 },
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Container(
//                     width: 200,
//                     height: 50,
//                     decoration: BoxDecoration(
//                       color: Colors.blue,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           Icons.qr_code,
//                           color: Colors.white,
//                           size: 24,
//                         ),
//                         SizedBox(width: 8),
//                         Text(
//                           'Start Scanning',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 20),
//               if (selectedZoneId == null)
//                 Text(
//                   'Please select a zone to start scanning and ensure upload XML file is done before scan',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 14, color: Colors.black54),
//                 ),
//             ],
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
import 'package:permission_handler/permission_handler.dart'; // Add this import
import 'Scanner.dart'; // Ensure this import path is correct
import 'package:inventary_app_production/ZonePage.dart';

class ZoneSelectionScreen extends StatefulWidget {
  @override
  _ZoneSelectionScreenState createState() => _ZoneSelectionScreenState();
}

class _ZoneSelectionScreenState extends State<ZoneSelectionScreen> {
  final _storage = GetStorage(); // Assuming GetStorage is being used
  Map<String, String> zoneIdMap = {};
  String? selectedZoneId;
  String? sessionId;

  @override
  void initState() {
    super.initState();
    _fetchZoneIds();
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
          Navigator.of(context).pushReplacementNamed('/login'); // Adjust route name accordingly
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
          Navigator.of(context).pushReplacementNamed('/login'); // Adjust route name accordingly
        });
        return;
      } else {
        _showAlert('Failed to start session');
      }
    } catch (e) {
      print('Error details of: $e');
    }
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
      // Check camera permission
      final status = await Permission.camera.request();
      if (status.isGranted) {
        // Permission granted, navigate to BarcodeScanPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BarcodeScanPage(
              zoneId: selectedZoneId!,  // Pass the selected zone ID
              sessionId: sessionId!,     // Pass the session ID
            ),
          ),
        );
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

              GestureDetector(
                onTap: () async {
                  // Start the session
                  await _startSession();
                  // Check if the session ID was successfully set
                  if (sessionId != null) {
                    _navigateToScan(); // Only navigate if session ID is not null
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 200,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Start Scanning',
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
