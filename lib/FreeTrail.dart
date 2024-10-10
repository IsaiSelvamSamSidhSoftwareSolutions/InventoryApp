//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:get_storage/get_storage.dart';
// import 'dart:convert';
//
// class Freetrail extends StatefulWidget {
//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<Freetrail> {
//   String _name = '';
//   int _maxDevices = 0;
//   String _planType = '';
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchPlanData();
//   }
//
//   Future<void> _fetchPlanData() async {
//     try {
//       final token = GetStorage().read('token'); // Get the token from GetStorage
//       final response = await http.get(
//         Uri.parse('https://iscandata.com/api/v1/plans/freeTypePlan'),
//         headers: {
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       print('API Response: ${response.body}'); // Print API response
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           _name = data['data']['plans'][0]['name'];
//           _maxDevices = data['data']['plans'][0]['maxDevices'];
//           _planType = data['data']['plans'][0]['planType'];
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _isLoading = false;
//         });
//         print('Error: ${response.body}'); // Print error response
//         _showAlert('Failed to fetch plan data');
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       print('An error occurred: $e'); // Print caught error
//       _showAlert('An error occurred while fetching plan data');
//     }
//   }
//
//   Future<void> _activateFreeTrial() async {
//     try {
//       final userId = GetStorage().read('userId');
//       final response = await http.post(
//         Uri.parse('https://iscandata.com/api/v1/subscriptions/freetrial'),
//         headers: {
//           'Authorization': 'Bearer ${GetStorage().read('token')}', // Your JWT token
//           'Content-Type': 'application/json',
//         },
//         body: json.encode({'userId': userId}),
//       );
//
//       print('API Response: ${response.body}'); // Print API response
//
//       if (response.statusCode == 201) {
//         Navigator.pushReplacementNamed(context, '/dashboard');
//         _showAlert('Free Trial has been activated!');
//       } else {
//         print('Error: ${response.body}'); // Print error response
//         _showAlert('Failed to activate Free Trial');
//       }
//     } catch (e) {
//       print('An error occurred: $e'); // Print caught error
//       _showAlert('An error occurred while activating Free Trial');
//     }
//   }
//
//   void _showAlert(String message) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Notification'),
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
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: _isLoading
//             ? CircularProgressIndicator()
//             : Card(
//           color: Colors.blue[100], // Change this to your desired color
//           elevation: 4,
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Text(
//                   _name,
//                   style: TextStyle(
//                       fontWeight: FontWeight.bold, fontSize: 20),
//                 ),
//                 SizedBox(height: 10),
//                 Text(
//                   'Max Devices: $_maxDevices',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 10),
//                 Text(
//                   'Plan Type: $_planType',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: _activateFreeTrial,
//                   child: Text('Get Free Trial'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'dart:convert';

class Freetrail extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<Freetrail> {
  String _name = '';
  int _maxDevices = 0;
  String _planType = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlanData();
  }

  Future<void> _fetchPlanData() async {
    try {
      final token = GetStorage().read('token'); // Get the token from GetStorage
      final response = await http.get(
        Uri.parse('https://iscandata.com/api/v1/plans/freeTypePlan'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('API Response: ${response.body}'); // Print API response

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _name = data['data']['plans'][0]['name'];
          _maxDevices = data['data']['plans'][0]['maxDevices'];
          _planType = data['data']['plans'][0]['planType'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print('Error: ${response.body}'); // Print error response
        _showAlert('Failed to fetch plan data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('An error occurred: $e'); // Print caught error
      _showAlert('An error occurred while fetching plan data');
    }
  }

  Future<void> _activateFreeTrial() async {
    try {
      final userId = GetStorage().read('userId');
      final response = await http.post(
        Uri.parse('https://iscandata.com/api/v1/subscriptions/freetrial'),
        headers: {
          'Authorization': 'Bearer ${GetStorage().read('token')}', // Your JWT token
          'Content-Type': 'application/json',
        },
        body: json.encode({'userId': userId}),
      );

      print('API Response: ${response.body}'); // Print API response

      if (response.statusCode == 201) {
        Navigator.pushReplacementNamed(context, '/dashboard');
        _showAlert('Free Trial has been activated!');
      } else {
        print('Error: ${response.body}'); // Print error response
        _showAlert('Failed to activate Free Trial');
      }
    } catch (e) {
      print('An error occurred: $e'); // Print caught error
      _showAlert('An error occurred while activating Free Trial');
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Notification'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blueAccent, // Starting color of the gradient
              Colors.lightBlueAccent, // Ending color of the gradient
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator()
              : Card(
            color: Colors.white.withOpacity(0.8), // Slightly transparent card background
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Max Devices: $_maxDevices',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Plan Type: $_planType',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _activateFreeTrial,
                    child: Text('Get Free Trial'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
