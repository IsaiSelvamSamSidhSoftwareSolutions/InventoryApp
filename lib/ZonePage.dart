//
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
//     print('User  Role: $userRole'); // Debug print
//     _fetchZones(); // Fetch zones when the page is initialized
//     //_startPolling(); // Start polling for automatic updates
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
//   //
//   // void _showZoneDialog({
//   //   String? id,
//   //   String? existingName,
//   //   String? existingDescription,
//   // }) {
//   //   final nameController = TextEditingController(text: existingName);
//   //   final descriptionController = TextEditingController(
//   //       text: existingDescription);
//   //   final userIdController = TextEditingController(); // Assuming userId is needed for admin role
//   //
//   //   // Reset user ID if editing
//   //   if (userRole == 'admin') {
//   //     userIdController.text = ''; // Clear the user ID field for editing
//   //   }
//   //
//   //   showDialog(
//   //     context: context,
//   //     builder: (context) {
//   //       return AlertDialog(
//   //         title: Text(id == null ? 'Add Zone' : 'Update Zone'),
//   //         // Title for the dialog
//   //         content: SingleChildScrollView(
//   //           child: Column(
//   //             mainAxisSize: MainAxisSize.min,
//   //             children: [
//   //               TextFormField(
//   //                 controller: nameController,
//   //                 decoration: InputDecoration(labelText: 'Zone Name'),
//   //                 validator: (value) =>
//   //                 value!.isEmpty
//   //                     ? 'Please enter a name'
//   //                     : null,
//   //               ),
//   //               TextFormField(
//   //                 controller: descriptionController,
//   //                 decoration: InputDecoration(labelText: 'Zone Description'),
//   //                 validator: (value) =>
//   //                 value!.isEmpty
//   //                     ? 'Please enter a description'
//   //                     : null,
//   //               ),
//   //               if (userRole == 'admin') ...[
//   //                 TextFormField(
//   //                   controller: userIdController,
//   //                   decoration: InputDecoration(labelText: 'User ID'),
//   //                   validator: (value) =>
//   //                   value!.isEmpty
//   //                       ? 'Please enter a user ID'
//   //                       : null,
//   //                 ),
//   //               ],
//   //             ],
//   //           ),
//   //         ),
//   //         actions: [
//   //           TextButton(
//   //             onPressed: () {
//   //               if (id == null) {
//   //                 _addZone(nameController.text, descriptionController.text,
//   //                     userRole == 'admin' ? userIdController.text : null);
//   //               } else {
//   //                 _updateZone(
//   //                     id, nameController.text, descriptionController.text,
//   //                     userRole == 'admin' ? userIdController.text : null);
//   //               }
//   //               Navigator.of(context).pop(); // Close the dialog
//   //             },
//   //             child: Text(id == null ? 'Add' : 'Update'),
//   //           ),
//   //           TextButton(
//   //             onPressed: () {
//   //               Navigator.of(context).pop(); // Close the dialog without action
//   //             },
//   //             child: Text('Cancel'),
//   //           ),
//   //         ],
//   //       );
//   //     },
//   //   );
//   // }
//   void _showZoneDialog({
//     String? id,
//     String? existingName,
//     String? existingDescription,
//   }) {
//     final nameController = TextEditingController(text: existingName);
//     final descriptionController = TextEditingController(text: existingDescription);
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text(id == null ? 'Add Zone' : 'Update Zone'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Name field for admin
//                 if (userRole == 'admin')
//                   TextFormField(
//                     controller: nameController,
//                     decoration: InputDecoration(labelText: 'Zone Name'),
//                   ),
//                 // Description field for both admin and users
//                 TextFormField(
//                   controller: descriptionController,
//                   decoration: InputDecoration(labelText: 'Zone Description'),
//                   validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 // Check for duplicate zone names and generate a unique sequence
//                 String zoneName = userRole == 'admin' ? nameController.text : _generateUniqueZoneName();
//
//                 if (id == null) {
//                   // Add new zone with unique name
//                   _addZone(zoneName, descriptionController.text, userRole == 'admin' ? userIdController.text : null);
//                 } else {
//                   // Update existing zone (only admins can edit name)
//                   _updateZone(id, userRole == 'admin' ? nameController.text : '', descriptionController.text, userRole == 'admin' ? userIdController.text : null);
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
// // Function to generate a unique zone name by skipping numbers already in use
//   String _generateUniqueZoneName() {
//     // Collect existing zone numbers from the zone names
//     List<int> existingNumbers = zones
//         .map((zone) {
//       final name = zone['name'] as String;
//       final regex = RegExp(r'^Zone (\d+)$'); // Matches "Zone <number>"
//       final match = regex.firstMatch(name);
//
//       if (match != null) {
//         return int.tryParse(match.group(1)!); // Extract the number part
//       }
//       return null;
//     })
//         .where((number) => number != null)
//         .cast<int>()
//         .toList();
//
//     // Sort the list of existing numbers
//     existingNumbers.sort();
//
//     // Find the first missing number in the sequence
//     int sequence = 1;
//     for (int number in existingNumbers) {
//       if (number == sequence) {
//         sequence++;
//       } else {
//         break;
//       }
//     }
//
//     return 'Zone $sequence';
//   }
//   void _showSuccessAlert(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message)));
//   }
//
//   void _showErrorAlert(String message) {
//     print("error $message");
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Zone Management'),
//         backgroundColor: Colors.blueAccent,
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
//                   suffixIcon: Icon(Icons.search), // Add search icon
//                 ),
//               ),
//             ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: zones.length,
//               itemBuilder: (context, index) {
//                 final zone = zones[index];
//                 return Card(
//                   color: index % 2 == 0 ? Colors.blue[100] : Colors
//                       .lightBlue[50], // Alternate colors
//                   child: ListTile(
//                     title: Text(zone['name']),
//                     subtitle: Text(zone['description']),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         IconButton(
//                           icon: Icon(Icons.edit, color: Colors.green),
//                           // Edit icon in green
//                           onPressed: () =>
//                               _showZoneDialog(
//                                 id: zone['_id'],
//                                 // Use _id for unique identification
//                                 existingName: zone['name'],
//                                 existingDescription: zone['description'],
//                               ),
//                         ),
//                         if (userRole ==
//                             'admin') // Delete option only for admins
//                           IconButton(
//                             icon: Icon(Icons.delete, color: Colors.red),
//                             // Delete icon in red
//                             onPressed: () {
//                               // Prompt for confirmation before deletion
//                               showDialog(
//                                 context: context,
//                                 builder: (context) {
//                                   return AlertDialog(
//                                     title: Text('Confirm Deletion'),
//                                     content: Text(
//                                       'Are you sure you want to delete this zone? \n'
//                                           'If you delete this record, it will be removed for the associated user.',
//                                     ),
//                                     actions: [
//                                       TextButton(
//                                         onPressed: () {
//                                           Navigator.of(context)
//                                               .pop(); // Close the dialog
//                                           _deleteZone(zone['_id'],
//                                               userIdController
//                                                   .text); // Delete by _id
//                                         },
//                                         child: Text('Delete'),
//                                       ),
//                                       TextButton(
//                                         onPressed: () =>
//                                             Navigator.of(context).pop(),
//                                         // Close the dialog
//                                         child: Text('Cancel'),
//                                       ),
//                                     ],
//                                   );
//                                 },
//                               );
//                             },
//                           ),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class ZonePage extends StatefulWidget {
  @override
  _ZoneManagementScreenState createState() => _ZoneManagementScreenState();
}

class _ZoneManagementScreenState extends State<ZonePage> {
  final storage = GetStorage();
  List<dynamic> zones = [];
  bool isLoading = false;
  String? userRole;
  TextEditingController userIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    userRole = storage.read('UserRole');
    print('User Role: $userRole');
    _fetchZones();
  }

  // Fetch zones with User ID for Admins
  Future<void> _fetchZones() async {
    setState(() => isLoading = true);

    String url = 'https://iscandata.com/api/v1/zones';
    String? token = storage.read('token');
    String? userId;

    if (userRole == 'admin' && userIdController.text.isNotEmpty) {
      userId = userIdController.text;
      url += '?userId=$userId';
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          zones = jsonDecode(response.body)['data']['zones'];
        });
      } else {
        print('Error fetching zones: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<String?> _getUserId() async {
    String? userId;
    await showDialog(
      context: context,
      builder: (context) {
        final userIdController = TextEditingController();
        return AlertDialog(
          title: Text('Enter User ID'),
          content: TextField(
            controller: userIdController,
            decoration: InputDecoration(labelText: 'User ID'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                userId = userIdController.text.trim(); // Capture User ID
                Navigator.of(context).pop();
              },
              child: Text('Submit'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel the dialog
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
    return userId; // Return the User ID or null if canceled
  }

// Function to add a new zone
  Future<void> _addZone(String description, {String? userId}) async {
    setState(() => isLoading = true);

    String url = 'https://iscandata.com/api/v1/zones';
    String? token = storage.read('token');

    // Prepare the request body
    Map<String, dynamic> body = {
      'description': description,
      if (userRole == 'admin' && userId != null) 'user': userId,
      // Include 'user' only if admin
    };

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
        _fetchZones(); // Refresh the list of zones
        _showSuccessMessage('Zone added successfully.');
      } else {
        var errorMessage = jsonDecode(response.body)['message'] ??
            'Error adding zone.';
        _showErrorMessage(errorMessage);
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Update a zone
  Future<void> _updateZone(String idOrName, String description,
      {bool byName = false}) async {
    setState(() => isLoading = true);

    String url = byName
        ? 'https://iscandata.com/api/v1/zones/?name=$idOrName'
        : 'https://iscandata.com/api/v1/zones/$idOrName';

    if (userRole == 'admin' && userIdController.text.isNotEmpty) {
      url += '?userId=${userIdController.text}';
    }

    String? token = storage.read('token');

    Map<String, dynamic> body = {
      'description': description,
    };

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        _fetchZones();
        _showSuccessMessage('Zone updated successfully.');
      } else {
        _showErrorMessage('Error updating zone: ${response.body}');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Delete a zone
  Future<void> _deleteZone(String idOrName, {bool byName = false}) async {
    setState(() => isLoading = true);

    String url = byName
        ? 'https://iscandata.com/api/v1/zones/?name=$idOrName'
        : 'https://iscandata.com/api/v1/zones/$idOrName';

    if (userRole == 'admin' && userIdController.text.isNotEmpty) {
      url += '?userId=${userIdController.text}';
    }

    String? token = storage.read('token');

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _fetchZones();
        _showSuccessMessage('Zone deleted successfully.');
      } else {
        _showErrorMessage('Error deleting zone: ${response.body}');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }
  void _showZoneDialog({String? id, String? existingDescription}) {
    final descriptionController = TextEditingController(text: existingDescription);
    final userIdController = TextEditingController(); // Controller for User ID

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(id == null ? 'Add Zone' : 'Update Zone'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (userRole == 'admin') // Show User ID field only for admin
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: userIdController,
                        decoration: InputDecoration(
                          labelText: 'User ID',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Zone Description',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final description = descriptionController.text.trim();
                final userId = userIdController.text.trim();

                // Validate fields
                if (description.isEmpty) {
                  _showErrorMessage('Zone Description is required.');
                  return;
                }
                if (userRole == 'admin' && userId.isEmpty) {
                  _showErrorMessage('User ID is required for admin users.');
                  return;
                }

                if (id == null) {
                  // Add Zone
                  if (userRole == 'admin') {
                    _addZone(description, userId: userId);
                  } else {
                    _addZone(description);
                  }
                } else {
                  // Update Zone
                  _updateZone(id, description);
                }

                Navigator.of(context).pop();
              },
              child: Text(id == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)));
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zone Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              if (userRole == 'admin') {
                if (userIdController.text.isNotEmpty) {
                  _fetchZones();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Please enter a User ID to refresh.')),
                  );
                }
              } else {
                _fetchZones();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : zones.isEmpty
          ? Center(
        child: userRole == 'admin'
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No zones available.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // Makes the button full-width
                children: [
                  TextField(
                    controller: userIdController,
                    decoration: InputDecoration(
                      labelText: 'Enter User ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10), // Add spacing between the TextField and the button
                  ElevatedButton(
                    onPressed: () {
                      if (userIdController.text.isNotEmpty) {
                        _fetchZones();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter a User ID to refresh.')),
                        );
                      }
                    },
                    child: Text('Get Zones'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Admin should enter the User ID to fetch and add new zones.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No zones available.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Please add zones to proceed.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showZoneDialog(),
              child: Text('Add Zone'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          if (userRole == 'admin')
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: userIdController,
                decoration: InputDecoration(
                  labelText: 'Enter User ID',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search_outlined),
                    onPressed: () {
                      if (userIdController.text.isNotEmpty) {
                        _fetchZones();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(
                              'Please enter a User ID to refresh.')),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: zones.length,
              itemBuilder: (context, index) {
                final zone = zones[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      zone['description'],
                      style: TextStyle(
                        fontSize: 18, // Adjust the size
                        fontWeight: FontWeight.bold, // Make it bold
                        color: Colors.black, // Set the color
                      ),
                    ),
                    subtitle: Text(
                      zone['name'],
                      style: TextStyle(
                        fontSize: 16, // Slightly smaller font size
                        fontWeight: FontWeight.w400, // Regular weight
                        color: Colors.grey[600], // Subtle grey for contrast
                        fontStyle: FontStyle.italic, // Optional italic style for variation
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () =>
                              _showZoneDialog(
                                id: zone['_id'],
                                existingDescription: zone['description'],
                              ),
                        ),
                        if (userRole == 'admin')
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteZone(zone['_id']),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showZoneDialog(),
      ),
    );
  }
}