import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'Departmentxmlupload.dart';
class DepartmentPage extends StatefulWidget {
  @override
  _DepartmentPageState createState() => _DepartmentPageState();
}

class _DepartmentPageState extends State<DepartmentPage> {
  final storage = GetStorage();
  bool isLoading = false;
  List<Map<String, dynamic>> departments = [];
  List<Map<String, dynamic>> filteredDepartments = [];
  String searchQuery = '';
  String? selectedDepartmentId;
  String selectedDepartmentName = '';
  final TextEditingController idController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  String? highlightedDepartmentId;
  String? userEmail;
  String? userRole;
  Future<void> _getUserEmail() async {
    setState(() {
      userEmail = storage.read('email');
      userRole = storage.read('UserRole');
      print("UserEmail -- $userEmail");// Assuming email is stored in GetStorage
    });
  }
  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _getUserEmail();
  }

  Future<void> _fetchDepartments() async {
    setState(() {
      isLoading = true;
    });

    final url = 'https://iscandata.com/api/v1/departments'; // Replace with your API URL
    String? token = storage.read('token');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('data') && data['data']['departments'] is List) {
          setState(() {
            departments = List<Map<String, dynamic>>.from(data['data']['departments']);
            filteredDepartments = departments;
          });
        }
      } else if (response.statusCode == 401) {
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pushReplacementNamed('/login');
        });
      }
    } catch (e) {
      print('Error during department fetch: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addDepartment(String id, String name) async {
    setState(() {
      isLoading = true;
    });

    final url = 'https://iscandata.com/api/v1/departments';
    String? token = storage.read('token');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id': id, 'name': name}),
      );

      if (response.statusCode == 201) {
        _showSuccessAlert('Department Added Successfully');
        _highlightDepartment(id);
        _fetchDepartments();
      }
    } catch (e) {
      print('Error during department addition: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateDepartment(String id, String name) async {
    setState(() {
      isLoading = true;
    });

    final url = 'https://iscandata.com/api/v1/departments/$id';
    String? token = storage.read('token');

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id': id, 'name': name}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSuccessAlert('Department Updated Successfully');
        _highlightDepartment(id);
        _fetchDepartments();
      } else {
        print('Update failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during department update: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _highlightDepartment(String id) {
    setState(() {
      highlightedDepartmentId = id;
    });
    Future.delayed(Duration(seconds: 5), () {
      setState(() {
        highlightedDepartmentId = null;
      });
    });
  }

  void _showAddDepartmentDialog(BuildContext context,
      {String? departmentId, String? departmentName}) {
    idController.text = departmentId ?? '';
    nameController.text = departmentName ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(departmentId == null ? 'Add Department' : 'Edit Department'),
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  decoration: InputDecoration(
                    labelText: 'Department ID',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  keyboardType: TextInputType.number,
                  enabled: departmentId == null,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Department Name',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (departmentId == null) {
                  _addDepartment(idController.text, nameController.text);
                } else {
                  _updateDepartment(departmentId, nameController.text);
                }
              },
              child: Text(departmentId == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    // Assume that the current user's email is stored in a variable called `userEmail`.
    // Fetch user email from storage (adjust according to your storage mechanism)
     // Replace with actual email fetching logic

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Department Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: _filterDepartments,
              decoration: InputDecoration(
                labelText: 'Search by Department ID', // Update the label text
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: filteredDepartments.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No data uploaded for departments.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'You can upload an XML file to get department data by clicking the blue icon button below.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Alternatively, you can add data manually.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: filteredDepartments.length,
                itemBuilder: (context, index) {
                  final department = filteredDepartments[index];
                  final isHighlighted = department['id'] == highlightedDepartmentId;
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    color: isHighlighted
                        ? Colors.greenAccent.withOpacity(0.5)
                        : Colors.transparent,
                    child: Card(
                      margin: EdgeInsets.symmetric(vertical: 5),
                      elevation: 5,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        title: Text(
                          department['name'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          department['id'].toString(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: userEmail == 'admin@gmail.com'
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                _showAddDepartmentDialog(
                                  context,
                                  departmentId: department['id'].toString(),
                                  departmentName: department['name'],
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _showConfirmDialog(
                                  context,
                                  'Delete Department',
                                  'Are you sure you want to delete this department?',
                                      () => _deleteDepartment(department['id'].toString()),
                                );
                              },
                            ),
                          ],
                        )
                            : null, // Hide buttons if user is not 'admin@gmail.com'
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Colors.blueAccent,
        children: [
          SpeedDialChild(
            child: Icon(Icons.add),
            label: 'Add Department',
            onTap: () {
              _showAddDepartmentDialog(context);
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.upload),
            label: 'Upload XML',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Departmentxmlupload()),
              );
            },
          ),
        ],
      ),
    );
  }
  void _filterDepartments(String query) {
    setState(() {
      searchQuery = query;
      filteredDepartments = departments
          .where((department) =>
          department['id'].toString().contains(query)) // Filtering by Department ID
          .toList();
    });
  }

  Future<void> _deleteDepartment(String id) async {
    setState(() {
      isLoading = true;
    });

    final url = 'https://iscandata.com/api/v1/departments/$id';
    String? token = storage.read('token');

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        _showSuccessAlert('Department Deleted Successfully');
        _fetchDepartments();
      } else {
        print('Delete failed with status code: ${response.statusCode}');
        _showErrorAlert('Failed to delete department. Please try again.');
      }
    } catch (e) {
      print('Error during department deletion: $e');
      print('An error occurred during deletion. Please try again.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  void _showErrorAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmDialog(BuildContext context, String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
