import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inventary_app_production/main.dart';
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  final storage = GetStorage();
  String? selectedDeviceId;
  String? selectedDeviceName;
  List<Map<String, dynamic>> devices = [];
  String? errorMessage;
  String? UserRole;
  List<Map<String, dynamic>> subscriptions  = [];
  @override
  void initState() {
    super.initState();
  }

  Future<void> login() async {

    // Validate inputs
    if (emailController.text.isEmpty || passwordController.text.isEmpty || selectedDeviceId == null) {
      setState(() {
        errorMessage = 'Please enter email, password, and select a device';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null; // Reset error message
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
        var userId = user['_id'];
        var UserRole = user['role'];
        var subscriptions = user['subscriptions'];

        print("subscriptions : $subscriptions");
        storage.write('token', token);
        storage.write('userId', userId);
        storage.write('deviceId', selectedDeviceId!);
        storage.write('email', user['email']);
        storage.write('UserRole' , UserRole);
        storage.write('subscriptions', subscriptions);

        // Navigate based on subscriptions
        if (response.statusCode == 200) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PermissionChecker(
              onPermissionsGranted: () {
                final storage = GetStorage();
                var subscriptions = storage.read('subscriptions');
                if ((subscriptions as List).isEmpty) {
                  Navigator.pushReplacementNamed(context, '/FreeTrial');
                } else {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                }
              },
            )),
          );
        }
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        var jsonResponse = json.decode(response.body);
        setState(() {
          errorMessage = jsonResponse['message'];
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
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
                        _fetchDevices(value);
                      },
                    ),
                    SizedBox(height: 20),
                    if (devices.isNotEmpty)
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
                        items: devices.map((device) {
                          return DropdownMenuItem<String>(
                            value: device['deviceId'],
                            child: Text(device['deviceName']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDeviceId = value;
                          });
                        },
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
                    if (errorMessage != null)
                      Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    SizedBox(height: 10),
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
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/forgotPassword');
                          },
                          child: Text('Forgot Password?', style: TextStyle(color: Colors.blueAccent)),
                        ),
                        SizedBox(width: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: Text('Create an Account', style: TextStyle(color: Colors.blueAccent)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
