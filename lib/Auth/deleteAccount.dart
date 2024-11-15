import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'login_page.dart';

class DeleteAccountPage extends StatefulWidget {
  @override
  _DeleteAccountPageState createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  bool _isLoading = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: AppBar(
        title: Text('Delete Account'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _isLoading ? null : () => _confirmDeleteAccount(context),
          child: _isLoading
              ? CircularProgressIndicator()
              : Text('Delete My Account'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[100], // Set button color to indicate deletion
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            textStyle: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Important Notice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You are about to delete your account. This action cannot be undone, and you will lose all your report data.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'We are committed to providing you with the best experience, and this step is irreversible. Please consider this decision carefully.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text('Do you wish to proceed?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _deleteAccount(); // Call the delete account function
              },
              child: Text('Yes, Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isLoading = true; // Set loading state
    });

    try {
      final token = GetStorage().read('token'); // Get the token from GetStorage

      if (token == null) {
        _showAlert('No valid token found. Please log in again.');
        return;
      }

      final response = await http.delete(
        Uri.parse('https://iscandata.com/api/v1/users/deleteAccount'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Navigate to the login page after successful deletion and clear all back stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false, // Remove all routes
        );
      } else {
        _showAlert('Failed to delete account. Please try again.');
      }
    } catch (e) {
      print('An error occurred: $e'); // Print caught error
      _showAlert('An error occurred while deleting the account.');
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state
      });
    }
  }

  void _showAlert(String message) {
    // Use the scaffold messenger key to show the alert
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }
}