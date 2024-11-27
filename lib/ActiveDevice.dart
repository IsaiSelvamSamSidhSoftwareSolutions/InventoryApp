// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:get_storage/get_storage.dart';
//
// class ActiveDevicesPage extends StatefulWidget {
//   @override
//   _ActiveDevicesPageState createState() => _ActiveDevicesPageState();
// }
//
// class _ActiveDevicesPageState extends State<ActiveDevicesPage> {
//   List<dynamic> _devices = [];
//   final box = GetStorage();
//   String? token;
//   String? email;
//   bool isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     token = box.read('token'); // Get JWT token from GetStorage
//     email = box.read('email');
//     print("email is -- $email");// Get email from GetStorage
//   }
//
//   Future<void> _fetchActiveDevices() async {
//     // Validate email format
//     if (email == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email!)) {
//       print('Invalid email format');
//       setState(() {
//         isLoading = false;
//       });
//       return;
//     }
//
//     try {
//       final url = Uri.parse('https://iscandata.com/api/v1/devices/active?email=$email');
//       final headers = {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       };
//
//       final response = await http.get(url, headers: headers);
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           _devices = (data['data']['devices'] as List)
//               .where((device) => device['isActive'] == true)
//               .toList();
//
//           _devices.sort((a, b) {
//             if (a['isLoggedIn'] == b['isLoggedIn']) {
//               return DateTime.parse(b['lastActiveAt']).compareTo(DateTime.parse(a['lastActiveAt']));
//             }
//             return a['isLoggedIn'] ? -1 : 1; // true first
//           });
//
//           isLoading = false;
//         });
//       } else {
//         throw Exception('Failed to load devices: ${response.reasonPhrase}');
//       }
//     } catch (e) {
//       print('Error fetching devices: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Active Devices', style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             ElevatedButton(
//               onPressed: () {
//                 setState(() {
//                   isLoading = true;
//                 });
//                 _fetchActiveDevices();
//               },
//               child: Text('Fetch Active Devices'),
//             ),
//             SizedBox(height: 16),
//             isLoading
//                 ? Center(child: CircularProgressIndicator())
//                 : _devices.isEmpty
//                 ? Center(child: Text('No active devices found'))
//                 : Expanded(
//               child: ListView.builder(
//                 itemCount: _devices.length,
//                 itemBuilder: (context, index) {
//                   var device = _devices[index];
//                   return _buildDeviceTile(device);
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDeviceTile(dynamic device) {
//     Color backgroundColor;
//
//     // Determine background color based on isActive and isLoggedIn
//     if (device['isActive'] == true && device['isLoggedIn'] == true) {
//       backgroundColor = Colors.green[100]!;
//     } else {
//       backgroundColor = Colors.blueAccent.withOpacity(0.1);
//     }
//
//     return Container(
//       color: backgroundColor,
//       margin: EdgeInsets.all(10),
//       child: ListTile(
//         title: Text(device['deviceName']),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Active Status: ${device['isActive']}'),
//             Text('Is Logged In: ${device['isLoggedIn'] ? 'Yes' : 'No'}'),
//             Text('Last Active At: ${device['lastActiveAt']}'),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class ActiveDevicesPage extends StatefulWidget {
  @override
  _ActiveDevicesPageState createState() => _ActiveDevicesPageState();
}

class _ActiveDevicesPageState extends State<ActiveDevicesPage> {
  List<dynamic> _devices = [];
  final box = GetStorage();
  String? token;
  String? email;
  bool isLoading = true; // Set to true initially to show loading indicator

  @override
  void initState() {
    super.initState();
    token = box.read('token'); // Get JWT token from GetStorage
    email = box.read('email');
    print("Email is -- $email");
    _fetchActiveDevices(); // Automatically fetch devices on page load
  }

  Future<void> _fetchActiveDevices() async {
    // Validate email format
    if (email == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email!)) {
      print('Invalid email format');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final url = Uri.parse('https://iscandata.com/api/v1/devices/active?email=$email');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _devices = (data['data']['devices'] as List)
              .where((device) => device['isActive'] == true)
              .toList();

          _devices.sort((a, b) {
            if (a['isLoggedIn'] == b['isLoggedIn']) {
              return DateTime.parse(b['lastActiveAt']).compareTo(DateTime.parse(a['lastActiveAt']));
            }
            return a['isLoggedIn'] ? -1 : 1; // true first
          });

          isLoading = false;
        });
      } else {
        throw Exception('Failed to load devices: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching devices: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Active Devices', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : _devices.isEmpty
            ? Center(child: Text('No active devices found'))
            : ListView.builder(
          itemCount: _devices.length,
          itemBuilder: (context, index) {
            var device = _devices[index];
            return _buildDeviceTile(device);
          },
        ),
      ),
    );
  }

  Widget _buildDeviceTile(dynamic device) {
    Color backgroundColor;

    // Determine background color based on isActive and isLoggedIn
    if (device['isActive'] == true && device['isLoggedIn'] == true) {
      backgroundColor = Colors.green[100]!;
    } else {
      backgroundColor = Colors.blueAccent.withOpacity(0.1);
    }

    return Container(
      color: backgroundColor,
      margin: EdgeInsets.all(10),
      child: ListTile(
        title: Text(device['deviceName']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Status: ${device['isActive']}'),
            Text('Is Logged In: ${device['isLoggedIn'] ? 'Yes' : 'No'}'),
            Text('Last Active At: ${device['lastActiveAt']}'),
          ],
        ),
      ),
    );
  }
}
