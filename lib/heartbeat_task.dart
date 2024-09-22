import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'main.dart';

const simpleTaskKey = "heartbeatTask";

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Initialize GetStorage within the callbackDispatcher
    await GetStorage.init();
    await checkSession();
    if (task == simpleTaskKey) {
      final box = GetStorage();
      String? token = box.read('token');
      String? deviceId = box.read('deviceId');

      // Check if token and deviceId are available
      if (token != null && deviceId != null) {
        List<ConnectivityResult> connectivity = await Connectivity().checkConnectivity();

        // Only send heartbeat if there is a network connection
        if (connectivity != ConnectivityResult.none) {
          try {
            final response = await http.post(
              Uri.parse('https://iscandata.com/api/v1/sessions/heartbeat'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                "deviceId": deviceId,
              }),
            );

            if (response.statusCode == 200) {
              var jsonResponse = json.decode(response.body);
              print("Heartbeat updated successfully: ${jsonResponse['message']}");
            } else if (response.statusCode == 401 && response.body.contains('Token is blacklisted')) {
              print('Token is blacklisted, logging out.');
              // Set a flag in GetStorage to handle logout in the foreground
              box.write('logout_needed', true);
            } else {
              print("Error in Heartbeat update: ${response.body}");
            }
          } catch (e) {
            print("Heartbeat API failed: $e");
          }
        } else {
          print('No network available to send the heartbeat.');
        }
      } else {
        print('Token or device ID missing.');
      }
    }

    return Future.value(true);
  });
}

// Function to handle logout (triggered when the app is in the foreground)
Future<void> handleLogout(BuildContext context) async {
  final box = GetStorage();
  String? token = box.read('token');

  // Proceed with logout if token exists
  if (token != null) {
    try {
      final response = await http.post(
        Uri.parse('https://iscandata.com/api/v1/users/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Handle successful logout
      if (response.statusCode == 200) {
        print('Logged out successfully.');
        box.remove('token');
        box.remove('deviceId');
        box.remove('logout_needed'); // Clear the logout flag

        // Navigate to the login page
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        print('Failed to log out: ${response.body}');
      }
    } catch (e) {
      print('Error while logging out: $e');
    }
  } else {
    print('No token found, cannot log out.');
  }
}

// In your main widget or wherever you handle app lifecycle
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Listen to changes in the app lifecycle to check if logout is needed
    WidgetsBinding.instance.addObserver(
      LifecycleEventHandler(onResume: _checkForLogout),
    );
  }

  // Check if logout is required when the app resumes
  Future<void> _checkForLogout() async {
    final box = GetStorage();
    bool? logoutNeeded = box.read('logout_needed');
    if (logoutNeeded == true) {
      await handleLogout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        appBar: AppBar(title: Text('Heartbeat and Logout')),
        body: Center(child: Text('App content goes here')),
      ),
    );
  }
}

// Handles app lifecycle changes
class LifecycleEventHandler extends WidgetsBindingObserver {
  final Future<void> Function() onResume;

  LifecycleEventHandler({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}
