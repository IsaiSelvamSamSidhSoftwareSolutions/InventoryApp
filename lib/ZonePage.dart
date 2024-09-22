import 'dart:async'; // Added for Timer
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';


void main() async {
  await GetStorage.init(); // Initialize GetStorage for storing the token
  runApp(ZonePage());
}

class Zonepage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zone Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ZonePage(),
    );
  }
}

class ZonePage extends StatefulWidget {
  @override
  _ZonePageState createState() => _ZonePageState();
}

class _ZonePageState extends State<ZonePage> {
  final storage = GetStorage();
  bool isLoading = false;
  List<dynamic> zones = [];
  Timer? _timer; // Timer for polling

  @override
  void initState() {
    super.initState();
    _fetchZones(); // Fetch zones when the page is initialized
    _startPolling(); // Start polling for automatic updates
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  // Start polling the API every 10 seconds for updates
  void _startPolling() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchZones();
    });
  }

  // Fetch zones from the API
  Future<void> _fetchZones() async {
    setState(() {
      isLoading = true;
    });

    final url = 'https://iscandata.com/api/v1/zones'; // Replace with your API URL
    String? token = storage.read('token');

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
        // Decode the JSON response
        final jsonResponse = jsonDecode(response.body);

        // Access the 'zones' list inside 'data'
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

  // Add a new zone
  Future<void> _addZone(String name, String description) async {
    setState(() {
      isLoading = true;
    });

    final url = 'https://iscandata.com/api/v1/zones'; // Replace with your API URL
    String? token = storage.read('token');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'description': description}),
      );

      if (response.statusCode == 201) {
        _fetchZones(); // Refresh the zone list after adding a new zone
        _showSuccessAlert('Zone Added Successfully');
      }
    } catch (e) {
      _showErrorAlert('Something went wrong! Exception: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Update an existing zone
  Future<void> _updateZone(String id, String name, String description) async {
    setState(() {
      isLoading = true;
    });

    final url = 'https://iscandata.com/api/v1/zones/$id'; // Replace with your API URL
    String? token = storage.read('token');

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'description': description}),
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

  // Delete a zone
  Future<void> _deleteZone(String id) async {
    setState(() {
      isLoading = true;
    });

    final url = 'https://iscandata.com/api/v1/zones/$id'; // Replace with your API URL
    String? token = storage.read('token');

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        _fetchZones(); // Refresh the zone list after deletion
        _showSuccessAlert('Zone Deleted Successfully');
      } else {
        _showErrorAlert('Error deleting zone: ${response.body}');
      }
    } catch (e) {
      _showErrorAlert('Something went wrong! Exception: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Show dialog to add or update a zone
  void _showZoneDialog({String? id, String? existingName, String? existingDescription}) {
    final nameController = TextEditingController(text: existingName ?? '');
    final descriptionController = TextEditingController(text: existingDescription ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(id == null ? 'Add Zone' : 'Update Zone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Zone Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Zone Description'),
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (nameController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                  if (id == null) {
                    _addZone(nameController.text, descriptionController.text);
                  } else {
                    _updateZone(id, nameController.text, descriptionController.text);
                  }
                }
              },
              child: Text(id == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  // Show success alert
  void _showSuccessAlert(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Show error alert
  void _showErrorAlert(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
      appBar: AppBar(
        title: Text('Zone Management',style:TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: EdgeInsets.all(8.0),
        itemCount: zones.length,
        itemBuilder: (context, index) {
          final zone = zones[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            elevation: 4,
            child: ListTile(
              contentPadding: EdgeInsets.all(16.0),
              title: Text(zone['name'], style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(zone['description']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      _showZoneDialog(
                        id: zone['_id'],
                        existingName: zone['name'],
                        existingDescription: zone['description'],
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteZone(zone['_id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showZoneDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}
