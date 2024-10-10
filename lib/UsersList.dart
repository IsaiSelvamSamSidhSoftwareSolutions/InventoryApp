import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Dio dio = Dio();
      final String url = 'https://iscandata.com/api/v1/users/';

      // Retrieve the JWT token from GetStorage
      final String token = GetStorage().read('token') ?? ''; // Assuming you stored it under the key 'token'

      // Add the JWT token to the headers
      dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _users = response.data['data']['users'];
          _filteredUsers = _users;
        });
      } else {
        // Handle error here
        print('Error fetching users: ${response.statusMessage}');
      }
    } catch (e) {
      print('Error fetching users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      _filteredUsers = _users.where((user) {
        final userName = user['userName'].toLowerCase();
        final userId = user['_id'].toLowerCase();
        return userName.contains(query.toLowerCase()) ||
            userId.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _updateUser(String userId, Map<String, dynamic> updatedData) async {
    try {
      final Dio dio = Dio();
      final String url = 'https://iscandata.com/api/v1/users/$userId';

      // Retrieve the JWT token from GetStorage
      final String token = GetStorage().read('token') ?? ''; // Assuming you stored it under the key 'token'

      // Add the JWT token to the headers
      dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await dio.patch(url, data: updatedData);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User updated successfully')),
        );
        fetchUsers(); // Refresh the user list after updating
      } else {
        print('Error updating user: ${response.statusMessage}');
      }
    } catch (e) {
      print('Error updating user: $e');
    }
  }

  void _copyToClipboard(String data) {
    Clipboard.setData(ClipboardData(text: data));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data copied to clipboard')),
    );
  }

  void _showEditDialog(Map<String, dynamic> user) {
    TextEditingController userNameController =
    TextEditingController(text: user['userName']);
    TextEditingController emailController = TextEditingController(text: user['email']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userNameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final updatedData = {
                  'userName': userNameController.text,
                  'email': emailController.text,
                };
                _updateUser(user['_id'], updatedData);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
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
        title: Text('User List' ,style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterUsers,
              decoration: InputDecoration(
                labelText: 'Search by Name or ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                final cardColor = index % 2 == 0
                    ? Colors.white
                    : Colors.blue[50];

                return Card(
                  color: cardColor,
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(user['userName']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${user['_id']}'),
                        Text('Email: ${user['email']}'),
                        Text('Role: ${user['role']}'),
                        SizedBox(height: 8),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.copy),
                          onPressed: () => _copyToClipboard(user['_id']),
                          tooltip: 'Copy ID',
                        ),
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _showEditDialog(user),
                          tooltip: 'Edit',
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
    );
  }
}

class OrderedList extends StatelessWidget {
  final List<dynamic> zones;

  const OrderedList({Key? key, required this.zones}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(zones.length, (index) {
        return Text('${index + 1}. ${zones[index]}');
      }),
    );
  }
}
