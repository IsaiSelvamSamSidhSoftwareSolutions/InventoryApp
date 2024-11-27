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
      print(
          "UserEmail -- $userEmail"); // Assuming email is stored in GetStorage
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _getUserEmail();
  }

  Future<void> _fetchDepartments({String? userId}) async {
    setState(() {
      isLoading = true;
    });

    // Base URL
    String baseUrl = 'https://iscandata.com/api/v1/departments';
    String? token = storage.read('token');

    // Construct the URL with the query parameter
    final url = userId != null ? '$baseUrl?userId=$userId' : baseUrl;

    print('Fetching from URL: $url'); // Debugging URL

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('data') && data['data']['departments'] is List) {
          setState(() {
            departments =
            List<Map<String, dynamic>>.from(data['data']['departments']);
            filteredDepartments = departments;
          });
        } else {
          print('No departments found in the response.');
          setState(() {
            departments = [];
            filteredDepartments = [];
          });
        }
      } else if (response.statusCode == 401) {
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pushReplacementNamed('/login');
        });
      } else {
        print(
            'Failed to fetch departments. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during department fetch: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> _addDepartment(String id, String name, [String? userId]) async {
    setState(() {
      isLoading = true;
    });

    // Base URL for the API
    String url = 'https://iscandata.com/api/v1/departments';
    String? token = storage.read('token');

    // Append User ID as a query parameter if provided
    if (userId != null) {
      url += '?userId=$userId';
    }

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
        _fetchDepartments();
      } else if (response.statusCode == 400) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['message']
            .contains('Department with this ID already exists')) {
          _showErrorAlert('Duplicate Department ID. Please choose another.');
        } else {
          _showErrorAlert('Failed to add department. ${responseBody['message']}');
        }
      } else {
        print('Failed to add department. Status code: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error during department addition: $e');
      _showErrorAlert('An error occurred while adding the department.');
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
    TextEditingController userIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              departmentId == null ? 'Add Department' : 'Edit Department'),
          content: SingleChildScrollView(
            child: Padding(
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
                    keyboardType: TextInputType.text,
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
                    keyboardType: TextInputType.text,
                  ),
                  if (userRole == 'admin') // Show User ID field only for admin
                    Column(
                      children: [
                        SizedBox(height: 10),
                        TextField(
                          controller: userIdController,
                          decoration: InputDecoration(
                            labelText: 'User ID',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                          keyboardType: TextInputType.text,
                        ),
                      ],
                    ),
                ],
              ),
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
                if (idController.text.isEmpty || nameController.text.isEmpty) {
                  _showErrorAlert('Department ID and Name are required.');
                  return;
                }
                if (userRole == 'admin' && userIdController.text.isEmpty) {
                  _showErrorAlert('User ID is required for admin.');
                  return;
                }
                Navigator.of(context).pop();
                if (departmentId == null) {
                  _addDepartment(
                    idController.text,
                    nameController.text,
                    userRole == 'admin' ? userIdController.text : null,
                  );
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
    TextEditingController userIdController = TextEditingController();
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
            if (userRole == 'admin') // Only render for admin users
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextField(
                      controller: userIdController,
                      decoration: InputDecoration(
                        labelText: 'Enter User ID',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final userId = userIdController.text.trim();
                      if (userId.isNotEmpty) {
                        _fetchDepartments(userId: userId);
                      } else {
                        _showErrorAlert('User ID cannot be empty.');
                      }
                    },
                    child: Text('Fetch Departments'),
                  ),
                ],
              ),

            TextField(
              onChanged: _filterDepartments,
              decoration: InputDecoration(
                labelText: 'Search by Department Name or ID', // Updated label text
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: filteredDepartments.isEmpty && searchQuery.isNotEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No department found for the given search.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Please try a different search query.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : filteredDepartments.isEmpty && searchQuery.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (userRole == 'admin')
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No data available for departments.',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Enter the User ID to fetch the data or manually add departments with UserID',
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                        ],
                      )
                    else
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No data available for departments. \nYou can upload an XML file to get department data by clicking the blue icon button below',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'You can add data manually.',
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
                                      () => _deleteDepartment(department['_id'].toString()),
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
              _fetchDepartments();
            },
          ),
        ],
      ),
    );
  }

  // void _filterDepartments(String query) {
  //   setState(() {
  //     searchQuery = query;
  //
  //     // Filter departments by ID and ensure case insensitivity
  //     filteredDepartments = departments
  //         .where((department) =>
  //         department['id']
  //             .toString()
  //             .toLowerCase()
  //             .contains(query.toLowerCase()))
  //         .toList();
  //
  //     // Show SnackBar if no matching departments are found
  //     if (filteredDepartments.isEmpty && query.isNotEmpty) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('No department found for the given search.'),
  //           duration: Duration(seconds: 2),
  //         ),
  //       );
  //     }
  //   });
  // }
  void _filterDepartments(String query) {
    setState(() {
      searchQuery = query;

      // Filter departments by name or ID, ensuring case insensitivity
      filteredDepartments = departments.where((department) {
        final departmentId = department['id'].toString().toLowerCase();
        final departmentName = department['name'].toString().toLowerCase();
        final searchQueryLower = query.toLowerCase();

        return departmentId.contains(searchQueryLower) ||
            departmentName.contains(searchQueryLower);
      }).toList();

      // Show SnackBar if no matching departments are found
      if (filteredDepartments.isEmpty && query.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No department found for the given search.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
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
