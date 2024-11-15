import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:inventary_app_production/UsersList.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

// Import your pages and other components
import 'FreeTrail.dart';
import 'ActiveDevice.dart';
import 'Reports/ClientReport.dart';
import 'Reports/Report.dart';
import 'Reports/Nof_Genereatedreport.dart';
import 'Reports/Department_general_report.dart';
import 'Reports/Zone_and_dep_report.dart';
import 'ZonePage.dart';
import 'Auth/heartbeat_task.dart';
import 'Auth/login_page.dart';
import 'Auth/signup_page.dart';
import 'Auth/forgot_password_page.dart';
import 'Auth/reset_password_page.dart';
import 'Uploadxml.dart';
import 'department_page.dart';
import 'BarCodeScanner/Scanner.dart';
import 'BarCodeScanner/Manualdataenrty.dart';
import 'BarCodeScanner/scantiming.dart';
import 'Plans.dart';
import 'Auth/deleteAccount.dart';
import 'BarCodeScanner/Zonefetch.dart';
import 'Subscriptions.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().registerPeriodicTask(
    'sessionKeepAlive',
    'sessionKeepAliveTask',
    frequency: Duration(minutes: 30), // Run every 30 minutes, adjust up to 60 if needed
  );

  // Check subscriptions and decide initial route
  final storage = GetStorage();

  print("Dynamic sub");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Inventory App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.lightBlue.shade50,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey.shade600,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),
      ),
      home: LoginPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/forgotPassword': (context) => ForgotPasswordPage(),
        '/resetPassword': (context) => ResetPasswordPage(),
        '/UploadXml': (context) => UploadAndFetchPage(),
        '/department_page': (context) => DepartmentPage(),
        '/scanner': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>;
          final String zoneId = args['zoneId']!;
          final String sessionId = args['sessionId']!;
          return BarcodeScanPage(zoneId: zoneId, sessionId: sessionId);
        },
        '/NOF': (context) => ManualDataEntry(),
        '/dashboard': (context) => DashboardPage(),
        '/departmentReport': (context) => DepartmentGeneralReportPage(),
        '/zoneAndDepReport': (context) => DetailedZoneReportPage(),
        '/Fullreport': (context) => ReportPage(),
        '/Nof_ReportPage': (context) => Nof_ReportPage(),
        '/ActiveDevice': (context) => ActiveDevicesPage(),
        '/ScanTiming': (context) => ScanTiming(),
        '/Plans': (context) => PlansScreen(),
        '/DeleteAccount': (context) => DeleteAccountPage(),
        '/Zoneselection': (context) => WelcomeScreen(),
        '/Subscriptions': (context) => SubscriptionsScreen(),
        '/zonePage': (context) => ZonePage(),
        '/FreeTrial': (context) => Freetrail(),
        '/DeleteAccount': (context) => DeleteAccountPage(),
        '/User  ListScreen' : (context) => UserListScreen(),
        '/ReportScreen' : (context) => ReportPageClient(),// Add FreeTrial route
      },
    );
  }
}
class PermissionChecker extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  PermissionChecker({required this.onPermissionsGranted});

  @override
  _PermissionCheckerState createState() => _PermissionCheckerState();
}

class _PermissionCheckerState extends State<PermissionChecker> {
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    print("Starting permission check...");
    checkPermissions();
  }

  Future<void> checkPermissions() async {
    print("Checking permissions...");
    await requestCameraPermission();
    await requestStoragePermission();

    if (_hasPermission) {
      print("Permissions granted, navigating...");
      widget.onPermissionsGranted();
    } else {
      print("Permissions not granted.");
    }
  }

  Future<void> requestCameraPermission() async {
    var status = await Permission.camera.status;
    print("Camera permission status: $status");

    if (status.isDenied || status.isPermanentlyDenied) {
      final permissionStatus = await Permission.camera.request();
      print("Camera permission request result: $permissionStatus");

      if (permissionStatus.isGranted) {
        setState(() {
          _hasPermission = true;
        });
        print("Camera permission granted.");
      } else if (permissionStatus.isPermanentlyDenied) {
        showPermissionSettingsDialog();
        print("Camera permission permanently denied.");
      } else {
        setState(() {
          _hasPermission = false;
        });
        print("Camera permission denied.");
      }
    } else if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      print("Camera permission already granted.");
    }
  }

  Future<void> requestStoragePermission() async {
    var status = await Permission.storage.status;
    print("Storage permission status: $status");

    if (status.isDenied || status.isPermanentlyDenied) {
      final permissionStatus = await Permission.storage.request();
      print("Storage permission request result: $permissionStatus");

      if (permissionStatus.isGranted) {
        setState(() {
          _hasPermission = true;
        });
        print("Storage permission granted.");
      } else if (permissionStatus.isPermanentlyDenied) {
        showPermissionSettingsDialog();
        print("Storage permission permanently denied.");
      } else {
        setState(() {
          _hasPermission = false;
        });
        print("Storage permission denied.");
      }
    } else if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      print("Storage permission already granted.");
    }
  }

  void showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Permission Required'),
          content: Text(
              'Permission has been permanently denied. Please enable it in the app settings.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings(); // Open the app settings
              },
              child: Text('Open Settings'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Permission Checker'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text('Permission Checker'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              print("Requesting permissions...");
              checkPermissions();
            },
            child: Text('Request Permissions'),
          ),
        ),
      );
    }
  }
}

Future<void> checkSession() async {
  final storage = GetStorage();
  final token = storage.read('token');

  // Check if token is null or expired, and redirect to login if necessary
  if (token == null) {
    navigatorKey.currentState?.pushReplacementNamed('/login');
    return;
  }

  final url = 'https://iscandata.com/api/v1/sessions/heartbeat';

  try {
    final response = await ApiService.get(url, token: token);

    if (response.statusCode == 401 && response.body.contains('Token is blacklisted')) {
      // Token is blacklisted, remove sensitive data and navigate to login
      storage.remove('token');
      storage.remove('userId');
      storage.remove('deviceId');

      // Show a dialog if the token is blacklisted
      showBlacklistedTokenDialog();
    }
  } catch (e) {
    // Handle any errors silently for background tasks
    print('Error while checking session: $e');
  }
}

void showBlacklistedTokenDialog() {
  if (navigatorKey.currentContext != null) {
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Session Expired'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your session has expired. The token is blacklisted.'),
              SizedBox(height: 16),
              Text('Redirecting to login page in 3 seconds...'),
            ],
          ),
        );
      },
    );

    Future.delayed(Duration(seconds: 3), () {
      navigatorKey.currentState?.pushReplacementNamed('/login');
    });
  }
}

class ApiService {
  static Future<http.Response> get(String url, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );
      return response;
    } catch (e) {
      throw Exception('Error while making GET request: $e');
    }
  }

  static Future<http.Response> post(String url, {required Map<String, dynamic> body, String? token}) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body.isNotEmpty ? jsonEncode(body) : null,
      );
      return response;
    } catch (e) {
      throw Exception('Error while making POST request: $e');
    }
  }
}

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final storage = GetStorage();
  String userName = '';
  String userRole = '';
  List<Widget> _pages = []; // Class-level list

  @override
  void initState() {
    super.initState();
    userName = storage.read('email') ?? 'User  ';
    userRole = storage.read('UserRole') ?? 'User  ';

    // Initialize the class-level _pages list
    _pages = [
      WelcomeScreen(),
      DepartmentPage(),
      ZonePage(),
      UploadAndFetchPage(),
    ];

    // Add UserListScreen if the user is an Admin
    if (userRole == 'admin') {
      print('userRole $userRole');
      _pages.add(UserListScreen());
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      final token = storage.read('token');
      if (token != null) {
        final url = 'https://iscandata.com/api/v1/users/logout';
        try {
          var response = await ApiService.post(url, body: {}, token: token);

          if (response.statusCode == 200) {
            storage.remove('token');
            storage.remove('userId');
            storage.remove('deviceId');
            Navigator.pushReplacementNamed(context, '/login');
          } else if (response.statusCode == 401) {
            Future.delayed(Duration(seconds: 2), () {
              Navigator.pushReplacementNamed(context, '/login');
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Logout failed: ${response.body}')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error while logging out')),
          );
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
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
        appBar: AppBar(
          title: Text('Inventory Maintaince'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(userName),
                accountEmail: Text(storage.read('email') ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '',
                    style: TextStyle(fontSize: 40.0, color: Colors.white),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.add_chart),
                title: Text('client Report'),
                onTap: () {
                  Navigator.pushNamed(context, '/ReportScreen');
                },
              ),
              // ListTile(
              //   leading: Icon(Icons.add_chart),
              //   title: Text('Full Report'),
              //   onTap: () {
              //     Navigator.pushNamed(context, '/Fullreport');
              //   },
              // ),
              // ListTile(
              //   leading: Icon(Icons.file_open),
              //   title: Text('Not on File'),
              //   onTap: () {
              //     Navigator.pushNamed(context, '/Nof_ReportPage');
              //   },
              // ),
              // ListTile(
              //   leading: Icon(Icons.area_chart),
              //   title: Text('Department Report'),
              //   onTap: () {
              //     Navigator.pushNamed(context, '/departmentReport');
              //   },
              // ),
              // ListTile(
              //   leading: Icon(Icons.map),
              //   title: Text('Zone and Department Report'),
              //   onTap: () {
              //     Navigator.pushNamed(context, '/zoneAndDepReport');
              //   },
              // ),
              ListTile(
                leading: Icon(Icons.timer),
                title: Text('Scanning Time Report'),
                onTap: () {
                  Navigator.pushNamed(context, '/ScanTiming');
                },
              ),
              ListTile(
                leading: Icon(Icons.device_unknown_rounded),
                title: Text('Device Status'),
                onTap: () {
                  Navigator.pushNamed(context, '/ActiveDevice');
                },
              ),
              ListTile(
                leading: Icon(Icons.wallet_rounded),
                title: Text('Plans'),
                onTap: () {
                  Navigator.pushNamed(context, '/Plans');
                },
              ),
              ListTile(
                leading: Icon(Icons.wallet_rounded),
                title: Text('Subcriptions'),
                onTap: () {
                  Navigator.pushNamed(context, '/Subscriptions');
                },
              ),
              ListTile(
                leading : Icon(Icons.delete, color: Colors.redAccent), // Icon for delete account
                title: Text('Delete Account', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pushNamed(context, '/DeleteAccount'); // Navigate to DeleteAccountPage
                },
              ),
            ],
          ),
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items:  [
            BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_outlined), label: 'Scanner'),
            BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Department'),
            BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Zones'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_rounded), label: 'Products'),
            if (userRole == 'admin') // Conditionally add this item
              BottomNavigationBarItem(icon: Icon(Icons.supervised_user_circle), label: 'User'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await GetStorage.init();
    final box = GetStorage();
    String? token = box.read('token');  // Read token from storage
    String? deviceId = box.read('deviceId');  // Read device ID from storage

    if (task == simpleTaskKey) {  // Check if the task matches the heartbeat task key
      if (token != null && deviceId != null) {  // Ensure token and device ID are available
        var connectivityResult = await (Connectivity().checkConnectivity());  // Check network connectivity

        if (connectivityResult != ConnectivityResult.none){  // Proceed only if there's internet
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
              box.remove('logout_needed');  // Clear logout_needed flag

              // Provide feedback to the user (consider using a local notification or callback)

            } else {
              print("Received status code: ${response.statusCode}. Checking if logout is needed.");
              handleApiError(response, box); // Handle API errors
            }
          } catch (e) {
            // Handle any exceptions during the API call
            print("Heartbeat API failed: $e");
            box.write('logout_needed', true);  // Set logout_needed flag on exception


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

// Function to handle API errors and logout logic
void handleApiError(http.Response response, GetStorage box) {
  if (response.body.contains('Token is blacklisted')) {
    box.write('logout_needed', true);  // Indicate that logout is needed
    handleLogout();  // Trigger logout immediately if token is blacklisted
    notifyUser("Session expired. Please log in again.");
  } else {
    box.write('logout_needed', true);  // Indicate that logout is needed

  }
}

// Function to notify the user (consider using a local notification package or dialog)
void notifyUser(String message) {
  // Implement your notification logic here (e.g., using Flutter local notifications)
  print(message);  // For demonstration purposes, print the message to the console
}