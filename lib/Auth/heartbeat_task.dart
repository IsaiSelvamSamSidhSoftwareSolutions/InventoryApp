import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../main.dart';

const simpleTaskKey = "heartbeatTask";
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await GetStorage.init();
    final box = GetStorage();
    String? token = box.read('token');  // Read token from storage
    String? deviceId = box.read('deviceId');  // Read device ID from storage

    if (task == simpleTaskKey) {  // Check if the task matches the heartbeat task key
      if (token != null && deviceId != null) {  // Ensure token and device ID are available
        var connectivityResult = await (Connectivity().checkConnectivity());  // Check network connectivity

        if (connectivityResult != ConnectivityResult.none) {  // Proceed only if there's internet
          try {
            // Send a POST request to the heartbeat API
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

            // Check if the heartbeat API response is successful
            if (response.statusCode == 200) {
              var jsonResponse = json.decode(response.body);
              print("Heartbeat updated successfully: ${jsonResponse['message']}");
              // Reset the logout flag since heartbeat is successful
              box.remove('logout_needed');  // Clear logout_needed flag if heartbeat is successful
            } else {
              // For any non-200 response, set logout_needed flag
              print("Received status code: ${response.statusCode}. Logging out.");
              box.write('logout_needed', true);  // Indicate that logout is needed

              // Optionally, perform logout logic here (e.g., clear token and navigate to login)
            }
          } catch (e) {
            // Handle any exceptions during the API call
            print("Heartbeat API failed: $e");
            box.write('logout_needed', true);  // Set logout_needed flag on exception

            // You may want to perform logout logic here as well
          }
        } else {
          print('No network available to send the heartbeat.');  // Handle no connectivity case
        }
      } else {
        print('Token or device ID missing.');  // Handle missing token or device ID
      }
    }

    return Future.value(true);  // Indicate task completion
  });
}
Future<void> handleLogout(BuildContext context) async {
  final box = GetStorage();
  String? token = box.read('token');
  box.erase();

  if (token != null) {
    try {
      final response = await http.post(
        Uri.parse('https://iscandata.com/api/v1/users/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('Logged out successfully.');
        box.remove('token');
        box.remove('deviceId');
        box.remove('logout_needed');

        Navigator.pushReplacementNamed(context, '/login');
      } else {
        print('Failed to log out: ${response.body}');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Error while logging out: $e');
      Navigator.pushReplacementNamed(context, '/login');
    }
  } else {
    print('No token found, cannot log out.');
    Navigator.pushReplacementNamed(context, '/login');
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
