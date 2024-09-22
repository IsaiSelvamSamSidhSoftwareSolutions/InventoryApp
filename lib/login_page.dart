import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true; // State to toggle password visibility
  final storage = GetStorage();
  String? selectedDeviceId;
  String? email;
  List<Map<String, dynamic>> devices = [];
  String? selectedDeviceName;

  @override
  void initState() {
    super.initState();
  }

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty || selectedDeviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter email, password, and select a device')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final url = 'https://iscandata.com/api/v1/users/login';
      Map<String, String> data = {
        "email": emailController.text,
        "password": passwordController.text,
        "deviceId": selectedDeviceId!,
      };

      var response = await http.post(
        Uri.parse(url),
        body: json.encode(data),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        var token = jsonResponse['token'];
        var user = jsonResponse['data']['user'];
        var userId = user != null ? user['_id'] : null;

        if (token != null && userId != null) {
          storage.write('token', token);
          storage.write('userId', userId);
          storage.write('deviceId', selectedDeviceId);
          storage.write('email', email);

          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: Invalid response')),
          );
        }
      } else if (response.statusCode == 403) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['message'] == 'This device is already logged in. Please log out from the previously logged-in device.') {
          await _logoutFromPreviousDevice();
          await login();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${jsonResponse['message']}')),
          );
        }
      } else {
        var jsonResponse = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${jsonResponse['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _logoutFromPreviousDevice() async {
    final token = storage.read('token');
    if (token != null) {
      final url = 'https://iscandata.com/api/v1/users/logout';
      var response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        storage.remove('token');
        storage.remove('userId');
        storage.remove('deviceId');
      } else {
        print('Failed to log out: ${response.body}');
      }
    }
  }
  // Future<void> _fetchDevices(String email) async {
  //   if (email.isEmpty) {
  //     // Handle empty email scenario
  //     print('Email is empty');
  //     return;
  //   }
  //
  //   final deviceUrl = 'https://iscandata.com/api/v1/devices/activenotloggedIn';
  //
  //   try {
  //     var deviceResponse = await http.get(
  //       Uri.parse('$deviceUrl?email=$email'), // Correctly include email as a query parameter
  //       headers: {'Content-Type': 'application/json'},
  //     );
  //
  //     if (deviceResponse.statusCode == 200) {
  //       var deviceJson = json.decode(deviceResponse.body);
  //       var devicesList = deviceJson['data']['devices'] as List;
  //       print("devicesList $devicesList");
  //       setState(() {
  //         devices = devicesList.map((device) => device as Map<String, dynamic>).toList();
  //         if (devices.isNotEmpty) {
  //           // Set the initial selected deviceId
  //           selectedDeviceId = devices.first['deviceId'];
  //           selectedDeviceName = devices.first['deviceName'];
  //         } else {
  //           selectedDeviceId = null;
  //           selectedDeviceName = null;
  //         }
  //       });
  //     } else {
  //       print('Failed to fetch devices: ${deviceResponse.body}');
  //     }
  //   } catch (e) {
  //     print('Error while fetching devices: $e');
  //   }
  // }
  Future<void> _fetchDevices(String email) async {
    if (email.isEmpty) {
      // Handle empty email scenario
      print('Email is empty');
      return;
    }

    // Check if the email has a valid format including a domain part after ".com"
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]{2,}$');
    if (!emailRegExp.hasMatch(email)) {
      print('Email does not contain a valid domain part after ".com"');
      return;
    }

    // URL encode the email to handle special characters
    final encodedEmail = Uri.encodeComponent(email);
    final deviceUrl = 'https://iscandata.com/api/v1/devices/activenotloggedIn';

    try {
      // Build the full request URL
      final requestUrl = '$deviceUrl?email=$encodedEmail';
      print('Request URL: $requestUrl'); // Log the request URL

      var deviceResponse = await http.get(
        Uri.parse(requestUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (deviceResponse.statusCode == 200) {
        var deviceJson = json.decode(deviceResponse.body);
        var devicesList = deviceJson['data']['devices'] as List;
        print("devicesList: $devicesList"); // Log the fetched devices list

        setState(() {
          devices = devicesList.map((device) => device as Map<String, dynamic>).toList();
          if (devices.isNotEmpty) {
            // Set the initial selected deviceId
            selectedDeviceId = devices.first['deviceId'];
            selectedDeviceName = devices.first['deviceName'];
          } else {
            selectedDeviceId = null;
            selectedDeviceName = null;
          }
        });
      } else {
        print('Failed to fetch devices: ${deviceResponse.body}'); // Log error response
      }
    } catch (e) {
      print('Error while fetching devices: $e'); // Log exceptions
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Login', style:TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      _fetchDevices(value);
                    } else {
                      setState(() {
                        devices.clear();
                        selectedDeviceId = null;
                        selectedDeviceName = null;
                      });
                    }
                  },
                ),
                SizedBox(height: 20),
                if (devices.isNotEmpty)
                  // DropdownButtonFormField<String>(
                  //   value: selectedDeviceId,
                  //   decoration: InputDecoration(
                  //     labelText: 'Select Device',
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(10),
                  //     ),
                  //     filled: true,
                  //     fillColor: Colors.grey[200],
                  //   ),
                  //   items: devices.map((device) {
                  //     // Safely extract values with null checks and defaults
                  //     final deviceId = device['deviceId'] as String?;
                  //     final deviceName = device['deviceName'] as String? ?? 'Unknown Device';
                  //     final isLoggedIn = device['isLoggedIn'] as bool? ?? false;
                  //
                  //     return DropdownMenuItem<String>(
                  //       value: deviceId,
                  //
                  //       child: Container(
                  //
                  //         color: isLoggedIn ? Colors.red[100] : Colors.green[100],
                  //         padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  //         child: Text(
                  //           deviceName,
                  //           style: TextStyle(
                  //             color: isLoggedIn ? Colors.red : Colors.green,
                  //           ),
                  //         ),
                  //       ),
                  //     );
                  //   }).toList(),
                  //   onChanged: (value) {
                  //     setState(() {
                  //       selectedDeviceId = value;
                  //       selectedDeviceName = devices.firstWhere(
                  //             (device) => device['deviceId'] == value,
                  //         orElse: () => {'deviceName': 'Unknown Device'},
                  //       )['deviceName'];
                  //     });
                  //   },
                  // ),
                  DropdownButtonFormField<String>(
                    value: selectedDeviceId,
                    decoration: InputDecoration(
                      labelText: 'Select Device',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    items: [
                      // Placeholder item
                      DropdownMenuItem<String>(
                        value: null, // Represents no selection
                        child: Text(
                          'Select Device', // Placeholder text
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      // Device items
                      ...devices.map((device) {
                        final deviceId = device['deviceId'] as String?;
                        final deviceName = device['deviceName'] as String? ?? 'Unknown Device';

                        return DropdownMenuItem<String>(
                          value: deviceId,
                          child: Text(
                            deviceName, // Display only device name
                            style: TextStyle(color: Colors.black), // Default text color
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedDeviceId = value;
                        selectedDeviceName = devices.firstWhere(
                              (device) => device['deviceId'] == value,
                          orElse: () => {'deviceName': 'Unknown Device'},
                        )['deviceName'];
                      });
                    },
                    hint: Text('Select Device', style: TextStyle(color: Colors.grey)), // Placeholder when nothing is selected
                  ),

                SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.blueAccent,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                SizedBox(height: 20),
                isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/resetPassword');
                      },
                      child: Text('Reset Password?', style: TextStyle(color: Colors.blueAccent)),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: Text('Create an Account', style: TextStyle(color: Colors.blueAccent)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
