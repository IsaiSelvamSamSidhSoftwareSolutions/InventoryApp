import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'dart:convert';
import 'login_page.dart';
class DeleteAccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delete Account'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _confirmDeleteAccount(context),
          child: Text('Delete My Account'),
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
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()), // Ensure this is your login page
                      (route) => false, // Remove all previous routes
                );// Proceed to delete the account
              },
              child: Text('Yes, Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final token = GetStorage().read('token'); // Get the token from GetStorage
      final response = await http.delete(
        Uri.parse('https://iscandata.com/api/v1/users/deleteAccount'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('API Response: ${response.body}'); // Print API response

      if (response.statusCode == 200) {
        final deletedData = json.decode(response.body)['deletedData'];
        _showDeletedDataAlert(context, deletedData);
      } else {
        print('Error: ${response.body}'); // Print error response
        _showAlert(context, 'Failed to delete account. Please try again.');
      }
    } catch (e) {
      print('An error occurred: $e'); // Print caught error
      _showAlert(context, 'An error occurred while deleting the account.');
    }
  }

  void _showDeletedDataAlert(BuildContext context, Map<String, dynamic> deletedData) {
    String message = "The following data has been deleted:\n\n";

    // Loop through deletedData to create a message string
    deletedData.forEach((key, value) {
      message += '$key: $value\n';
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Deletion Summary'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the alert dialog
                // Optionally, navigate back to the login screen or home page
                // Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Notification'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the alert dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
