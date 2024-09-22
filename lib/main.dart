import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ActiveDevice.dart';
import 'Report.dart';
import 'Nof_Genereatedreport.dart';
import 'ZonePage.dart';
import 'Department_general_report.dart';
import 'Zone_and_dep_report.dart';
import 'heartbeat_task.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';
import 'reset_password_page.dart';
import 'Uploadxml.dart';
import 'department_page.dart';
import 'Scanner.dart';
import 'Manualdataenrty.dart';
import 'scantiming.dart';
import 'Plans.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(); // Initialize GetStorage for token and deviceId storage
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false); // Initialize Workmanager
  Workmanager().registerPeriodicTask(
    "heartbeatTaskId", // Unique ID for the task
    simpleTaskKey, // The task key to be executed
    frequency: const Duration(minutes: 3), // Repeat every 3 minutes
    initialDelay: const Duration(minutes: 3),
    constraints: Constraints(
      networkType: NetworkType.connected, // Ensure the task runs only when the device is connected to the internet
    ),
    // Optional: delay before the first task execution
  );

  runApp(MyApp());
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
      // It's important to ensure this is only triggered when the app is in the foreground
      navigatorKey.currentState?.pushReplacementNamed('/login');
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/forgotPassword': (context) => ForgotPasswordPage(),
        '/resetPassword': (context) => ResetPasswordPage(),
        '/UploadXml': (context) => UploadAndFetchPage(),
        '/department_page': (context) => DepartmentPage(),
        '/scanner': (context) => BarcodeScanPage(),
        '/NOF': (context) => ManualDataEntry(),
        '/dashboard': (context) => DashboardPage(),
        '/departmentReport': (context) => DepartmentGeneralReportPage(),
        '/zoneAndDepReport': (context) => DetailedZoneReportPage(),
        '/Fullreport': (context) => ReportPage(),
        '/Nof_ReportPage': (context) => Nof_ReportPage(),
        '/ActiveDevice': (context) => ActiveDevicesPage(),
        '/ScanTiming': (context) => ScanTiming(),
        '/Plans': (context) => PlansScreen(),
      },
    );
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

  final List<Widget> _pages = [
    BarcodeScanPage(),
    UploadAndFetchPage(),
    DepartmentPage(),
    ZonePage(),
  ];

  @override
  void initState() {
    super.initState();
    userName = storage.read('userName') ?? 'User';
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome $userName'),
        backgroundColor: Colors.white,
      ),
      drawer: AppDrawer(onLogout: _logout),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.upload_file), label: 'Upload'),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Department'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Zone'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final Future<void> Function() onLogout;

  AppDrawer({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blueAccent,
            ),
            child: Center(
              child: Text(
                'Inventory  Maintaince App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.add_chart),
            title: Text('Full Report'),
            onTap: () {
              Navigator.pushNamed(context, '/Fullreport');
            },
          ),
          ListTile(
            leading: Icon(Icons.file_open),
            title: Text('Not on File'),
            onTap: () {
              Navigator.pushNamed(context, '/Nof_ReportPage');
            },
          ),
          ListTile(
            leading: Icon(Icons.area_chart),
            title: Text('Department Report'),
            onTap: () {
              Navigator.pushNamed(context, '/departmentReport');
            },
          ),
          ListTile(
            leading: Icon(Icons.map),
            title: Text('Zone and Department Report'),
            onTap: () {
              Navigator.pushNamed(context, '/zoneAndDepReport');
            },
          ),
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
            title: Text('Plans and Subcriptions'),
            onTap: () {
              Navigator.pushNamed(context, '/Plans');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
