// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:get_storage/get_storage.dart';
//
// void main() async {
//   await GetStorage.init(); // Initialize GetStorage for storing the token
//   runApp(ZonePage());
// }
//
// class ZonePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Zone Management',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: ZoneManagementScreen(),
//     );
//   }
// }
//
// class ZoneManagementScreen extends StatefulWidget {
//   @override
//   _ZoneManagementScreenState createState() => _ZoneManagementScreenState();
// }
//
// class _ZoneManagementScreenState extends State<ZoneManagementScreen> {
//   final storage = GetStorage();
//   bool isLoading = false;
//   List<dynamic> zones = [];
//   Timer? _timer; // Timer for polling
//   String? userRole;
//   TextEditingController userIdController = TextEditingController(); // User ID controller
//
//   @override
//   void initState() {
//     super.initState();
//     userRole = storage.read('UserRole'); // Get user role from GetStorage
//     print('User Role: $userRole'); // Debug print
//     _fetchZones(); // Fetch zones when the page is initialized
//     _startPolling(); // Start polling for automatic updates
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel(); // Cancel the timer when the widget is disposed
//     userIdController.dispose(); // Dispose the User ID controller
//     super.dispose();
//   }
//
//   // Start polling the API every 10 seconds for updates
//   void _startPolling() {
//     _timer = Timer.periodic(Duration(seconds: 10), (timer) {
//       _fetchZones(isManualFetch: false); // Automatic polling
//     });
//   }
//
//   // Fetch zones from the API
//   Future<void> _fetchZones({bool isManualFetch = true}) async {
//     setState(() {
//       isLoading = true;
//     });
//
//     String? token = storage.read('token');
//     String? userId;
//
//     // If user role is admin, fetch the User ID from the text field
//     if (userRole == 'admin' && userIdController.text.isNotEmpty) {
//       userId = userIdController.text;
//     }
//
//     // Build the API URL with userId as a query parameter if the role is admin
//     String url = 'https://iscandata.com/api/v1/zones';
//     if (userRole == 'admin' && userId != null) {
//       url += '?userId=$userId';
//     }
//
//     try {
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       print('Response Status Code: ${response.statusCode}');
//       print('Response Body: ${response.body}');
//
//       if (response.statusCode == 200) {
//         final jsonResponse = jsonDecode(response.body);
//         setState(() {
//           zones = jsonResponse['data']['zones'];
//         });
//
//         print('Zones fetched successfully: $zones');
//       } else {
//         print('Error fetching zones: ${response.body}');
//       }
//     } catch (e) {
//       print('Something went wrong! Exception: $e');
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _addZone(String name, String description,
//       [String? userId]) async {
//     setState(() {
//       isLoading = true;
//     });
//
//     final url = 'https://iscandata.com/api/v1/zones'; // Replace with your API URL
//     String? token = storage.read('token');
//
//     // Create the body for the request
//     Map<String, dynamic> body = {
//       'name': name,
//       'description': description,
//     };
//
//     // Add the 'user' field if the role is admin
//     if (userRole == 'admin' && userId != null) {
//       body['user'] = userId; // Include the user ID in the request
//     }
//
//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode(body),
//       );
//
//       if (response.statusCode == 201) {
//         _fetchZones(); // Refresh the zone list after adding a new zone
//         _showSuccessAlert('Zone Added Successfully');
//       } else {
//         _showErrorAlert('Error adding zone: ${response.body}');
//       }
//     } catch (e) {
//       _showErrorAlert('Something went wrong! Exception: $e');
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _updateZone(String id, String name, String description,
//       String? userId) async {
//     setState(() {
//       isLoading = true;
//     });
//
//     String? token = await storage.read(
//         'token'); // Ensure token is read asynchronously
//
//     // Create the body for the request
//     Map<String, dynamic> body = {
//       'name': name,
//       'description': description,
//     };
//
//     // Add the 'user' field if the role is admin
//     if (userRole == 'admin' && userId != null) {
//       body['user'] = userId; // Include the user ID in the request
//     }
//
//     try {
//       // Build the URL dynamically based on the user role
//       final response = await http.patch(
//         Uri.parse('https://iscandata.com/api/v1/zones/$id${userRole == 'admin'
//             ? '?userId=$userId'
//             : ''}'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode(body),
//       );
//
//       if (response.statusCode == 200) {
//         _fetchZones(); // Refresh the zone list after updating
//         _showSuccessAlert('Zone Updated Successfully');
//       } else {
//         _showErrorAlert('Error updating zone: ${response.body}');
//       }
//     } catch (e) {
//       _showErrorAlert('Something went wrong! Exception: $e');
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _deleteZone(String idOrName, String? userId,
//       {bool isByName = false}) async {
//     setState(() {
//       isLoading = true;
//     });
//
//     final url = isByName
//         ? 'https://iscandata.com/api/v1/zones/?name=$idOrName&userId=$userId' // Delete by name
//         : 'https://iscandata.com/api/v1/zones/$idOrName?userId=$userId'; // Delete by ID
//     String? token = storage.read('token');
//
//     try {
//       final response = await http.delete(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $token',
//           if (userRole == 'admin' && userId != null) 'user': userId,
//           // Include userId for admin
//         },
//       );
//
//       if (response.statusCode == 200) {
//         _fetchZones(); // Refresh the zone list after deletion
//         _showSuccessAlert('Zone Deleted Successfully');
//       } else {
//         print('Error deleting zone: ${response.body}');
//         _showErrorAlert('Error deleting zone: ${response.body}');
//       }
//     } catch (e) {
//       print('Something went wrong! Exception: $e');
//       _showErrorAlert('Something went wrong! Exception: $e');
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   void _showZoneDialog({
//     String? id,
//     String? existingName,
//     String? existingDescription,
//   }) {
//     final nameController = TextEditingController(text: existingName);
//     final descriptionController = TextEditingController(
//         text: existingDescription);
//     final userIdController = TextEditingController(); // Assuming userId is needed for admin role
//
//     // Reset user ID if editing
//     if (userRole == 'admin') {
//       userIdController.text = ''; // Clear the user ID field for editing
//     }
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text(id == null ? 'Add Zone' : 'Update Zone'),
//           // Title for the dialog
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextFormField(
//                   controller: nameController,
//                   decoration: InputDecoration(labelText: 'Zone Name'),
//                   validator: (value) =>
//                   value!.isEmpty
//                       ? 'Please enter a name'
//                       : null,
//                 ),
//                 TextFormField(
//                   controller: descriptionController,
//                   decoration: InputDecoration(labelText: 'Zone Description'),
//                   validator: (value) =>
//                   value!.isEmpty
//                       ? 'Please enter a description'
//                       : null,
//                 ),
//                 if (userRole == 'admin') ...[
//                   TextFormField(
//                     controller: userIdController,
//                     decoration: InputDecoration(labelText: 'User ID'),
//                     validator: (value) =>
//                     value!.isEmpty
//                         ? 'Please enter a user ID'
//                         : null,
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 if (id == null) {
//                   _addZone(nameController.text, descriptionController.text,
//                       userRole == 'admin' ? userIdController.text : null);
//                 } else {
//                   _updateZone(
//                       id, nameController.text, descriptionController.text,
//                       userRole == 'admin' ? userIdController.text : null);
//                 }
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: Text(id == null ? 'Add' : 'Update'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog without action
//               },
//               child: Text('Cancel'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _showSuccessAlert(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message)));
//   }
//
//   void _showErrorAlert(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message)));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Zone Management'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: _fetchZones, // Refresh zones when tapped
//           ),
//         ],
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : Column(
//         children: [
//           if (userRole == 'admin') // Show userId text box only for admin
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: TextField(
//                 controller: userIdController, // Use the userId controller
//                 decoration: InputDecoration(
//                   labelText: 'Enter User ID',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: zones.length,
//               itemBuilder: (context, index) {
//                 final zone = zones[index];
//                 return Card(
//                   child: ListTile(
//                     title: Text(zone['name']),
//                     subtitle: Text(zone['description']),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         IconButton(
//                           icon: Icon(Icons.edit),
//                           onPressed: () =>
//                               _showZoneDialog(
//                                 id: zone['_id'],
//                                 // Use _id for unique identification
//                                 existingName: zone['name'],
//                                 existingDescription: zone['description'],
//                               ),
//                         ),
//                         IconButton(
//                           icon: Icon(Icons.delete),
//                           onPressed: () {
//                             // Prompt for confirmation before deletion
//                             showDialog(
//                               context: context,
//                               builder: (context) {
//                                 return AlertDialog(
//                                   title: Text('Confirm Deletion'),
//                                   content: Text(
//                                       'Are you sure you want to delete this zone?'),
//                                   actions: [
//                                     TextButton(
//                                       onPressed: () {
//                                         Navigator.of(context)
//                                             .pop(); // Close the dialog
//                                         _deleteZone(zone['_id'],
//                                             userRole == 'admin'
//                                                 ? userIdController.text
//                                                 : null); // Delete by _id
//                                       },
//                                       child: Text('Delete'),
//                                     ),
//                                     TextButton(
//                                       onPressed: () =>
//                                           Navigator.of(context).pop(),
//                                       // Close the dialog
//                                       child: Text('Cancel'),
//                                     ),
//                                   ],
//                                 );
//                               },
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showZoneDialog(), // Show dialog to add a new zone
//         child: Icon(Icons.add),
//       ),
//     );
//   }
// }

// Import necessary packages
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

void main() async {
  await GetStorage.init(); // Initialize GetStorage for storing the token
  runApp(ZonePage());
}

class ZonePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zone Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ZoneManagementScreen(),
    );
  }
}

class ZoneManagementScreen extends StatefulWidget {
  @override
  _ZoneManagementScreenState createState() => _ZoneManagementScreenState();
}

class _ZoneManagementScreenState extends State<ZoneManagementScreen> {
  final storage = GetStorage();
  bool isLoading = false;
  List<dynamic> zones = [];
  Timer? _timer; // Timer for polling
  String? userRole;
  TextEditingController userIdController = TextEditingController(); // User ID controller

  @override
  void initState() {
    super.initState();
    userRole = storage.read('UserRole'); // Get user role from GetStorage
    print('User  Role: $userRole'); // Debug print
    _fetchZones(); // Fetch zones when the page is initialized
    _startPolling(); // Start polling for automatic updates
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    userIdController.dispose(); // Dispose the User ID controller
    super.dispose();
  }

  // Start polling the API every 10 seconds for updates
  void _startPolling() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchZones(isManualFetch: false); // Automatic polling
    });
  }

  // Fetch zones from the API
  Future<void> _fetchZones({bool isManualFetch = true}) async {
    setState(() {
      isLoading = true;
    });

    String? token = storage.read('token');
    String? userId;

    // If user role is admin, fetch the User ID from the text field
    if (userRole == 'admin' && userIdController.text.isNotEmpty) {
      userId = userIdController.text;
    }

    // Build the API URL with userId as a query parameter if the role is admin
    String url = 'https://iscandata.com/api/v1/zones';
    if (userRole == 'admin' && userId != null) {
      url += '?userId=$userId';
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          zones = jsonResponse['data']['zones'];
        });

        print('Zones fetched successfully: $zones');
      } else {
        print('Error fetching zones: ${response.body}');
      }
    } catch (e) {
      print('Something went wrong! Exception: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addZone(String name, String description,
      [String? userId]) async {
    setState(() {
      isLoading = true;
    });

    final url = 'https://iscandata.com/api/v1/zones'; // Replace with your API URL
    String? token = storage.read('token');

    // Create the body for the request
    Map<String, dynamic> body = {
      'name': name,
      'description': description,
    };

    // Add the 'user' field if the role is admin
    if (userRole == 'admin' && userId != null) {
      body['user'] = userId; // Include the user ID in the request
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        _fetchZones(); // Refresh the zone list after adding a new zone
        _showSuccessAlert('Zone Added Successfully');
      } else {
        _showErrorAlert('Error adding zone: ${response.body}');
      }
    } catch (e) {
      _showErrorAlert('Something went wrong! Exception: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateZone(String id, String name, String description,
      String? userId) async {
    setState(() {
      isLoading = true;
    });

    String? token = await storage.read(
        'token'); // Ensure token is read asynchronously

    // Create the body for the request
    Map<String, dynamic> body = {
      'name': name,
      'description': description,
    };

    // Add the 'user' field if the role is admin
    if (userRole == 'admin' && userId != null) {
      body['user'] = userId; // Include the user ID in the request
    }

    try {
      // Build the URL dynamically based on the user role
      final response = await http.patch(
        Uri.parse('https://iscandata.com/api/v1/zones/$id${userRole == 'admin'
            ? '?userId=$userId'
            : ''}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        _fetchZones(); // Refresh the zone list after updating
        _showSuccessAlert('Zone Updated Successfully');
      } else {
        _showErrorAlert('Error updating zone: ${response.body}');
      }
    } catch (e) {
      _showErrorAlert('Something went wrong! Exception: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteZone(String idOrName, String? userId,
      {bool isByName = false}) async {
    setState(() {
      isLoading = true;
    });

    final url = isByName
        ? 'https://iscandata.com/api/v1/zones/?name=$idOrName&userId=$userId' // Delete by name
        : 'https://iscandata.com/api/v1/zones/$idOrName?userId=$userId'; // Delete by ID
    String? token = storage.read('token');

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          if (userRole == 'admin' && userId != null) 'user': userId,
          // Include userId for admin
        },
      );

      if (response.statusCode == 200) {
        _fetchZones(); // Refresh the zone list after deletion
        _showSuccessAlert('Zone Deleted Successfully');
      } else {
        print('Error deleting zone: ${response.body}');
        _showErrorAlert('Error deleting zone: ${response.body}');
      }
    } catch (e) {
      print('Something went wrong! Exception: $e');
      _showErrorAlert('Something went wrong! Exception: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showZoneDialog({
    String? id,
    String? existingName,
    String? existingDescription,
  }) {
    final nameController = TextEditingController(text: existingName);
    final descriptionController = TextEditingController(
        text: existingDescription);
    final userIdController = TextEditingController(); // Assuming userId is needed for admin role

    // Reset user ID if editing
    if (userRole == 'admin') {
      userIdController.text = ''; // Clear the user ID field for editing
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(id == null ? 'Add Zone' : 'Update Zone'),
          // Title for the dialog
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Zone Name'),
                  validator: (value) =>
                  value!.isEmpty
                      ? 'Please enter a name'
                      : null,
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Zone Description'),
                  validator: (value) =>
                  value!.isEmpty
                      ? 'Please enter a description'
                      : null,
                ),
                if (userRole == 'admin') ...[
                  TextFormField(
                    controller: userIdController,
                    decoration: InputDecoration(labelText: 'User ID'),
                    validator: (value) =>
                    value!.isEmpty
                        ? 'Please enter a user ID'
                        : null,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (id == null) {
                  _addZone(nameController.text, descriptionController.text,
                      userRole == 'admin' ? userIdController.text : null);
                } else {
                  _updateZone(
                      id, nameController.text, descriptionController.text,
                      userRole == 'admin' ? userIdController.text : null);
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(id == null ? 'Add' : 'Update'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without action
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessAlert(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)));
  }

  void _showErrorAlert(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zone Management'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchZones, // Refresh zones when tapped
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (userRole == 'admin') // Show userId text box only for admin
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: userIdController, // Use the userId controller
                decoration: InputDecoration(
                  labelText: 'Enter User ID',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.search), // Add search icon
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: zones.length,
              itemBuilder: (context, index) {
                final zone = zones[index];
                return Card(
                  color: index % 2 == 0 ? Colors.blue[100] : Colors.lightBlue[50], // Alternate colors
                  child: ListTile(
                    title: Text(zone['name']),
                    subtitle: Text(zone['description']),
                    trailing: userRole == 'admin'
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.green), // Edit icon in green
                          onPressed: () => _showZoneDialog(
                            id: zone['_id'], // Use _id for unique identification
                            existingName: zone['name'],
                            existingDescription: zone['description'],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red), // Delete icon in red
                          onPressed: () {
                            // Prompt for confirmation before deletion
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('Confirm Deletion'),
                                  content: Text(
                                    'Are you sure you want to delete this zone? \n'
                                        'If you delete this record, it will be removed for the associated user.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Close the dialog
                                        _deleteZone(zone['_id'], userIdController.text); // Delete by _id
                                      },
                                      child: Text('Delete'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(), // Close the dialog
                                      child: Text('Cancel'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    )
                        : SizedBox.shrink(), // No buttons for non-admin users
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showZoneDialog(), // Show dialog to add a new zone
        child: Icon(Icons.add),
      ),
    );
  }
}