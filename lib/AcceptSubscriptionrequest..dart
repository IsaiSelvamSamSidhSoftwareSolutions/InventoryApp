import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class  AcceptSubscriptionRequest extends StatefulWidget {
  @override
  _CreateSubscriptionScreenState createState() =>
      _CreateSubscriptionScreenState();
}

class _CreateSubscriptionScreenState extends State<AcceptSubscriptionRequest> {
  final box = GetStorage();

  // Controllers for input fields
  final TextEditingController planIdController = TextEditingController();
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController requestIdController = TextEditingController();

  String selectedAction = 'accept'; // Default action

  bool isLoading = false;

  Future<void> createSubscription() async {
    final token = box.read('token');
    final url = Uri.parse('https://iscandata.com/api/v1/subscriptions/fromRequest');

    final body = {
      "planId": planIdController.text.trim(),
      "userId": userIdController.text.trim(),
      "requestId": requestIdController.text.trim(),
      "action": selectedAction,
    };

    // Validation for empty fields
    if (body.values.any((value) => value.isEmpty)) {
      showError('All fields are required');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        showSuccess('Subscription created successfully!');
        clearFields();
      } else {
        final error = jsonDecode(response.body);
        showError('Failed to create subscription: ${error['message']}');
      }
    } catch (e) {
      showError('An error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void clearFields() {
    planIdController.clear();
    userIdController.clear();
    requestIdController.clear();
    setState(() {
      selectedAction = 'accept'; // Reset action dropdown
    });
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Subscription'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Before Approval:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16 , color: Colors.redAccent),
            ),
            SizedBox(height: 8),
            Text(
              'Make sure all payments are verified and approved.',
              style: TextStyle(fontSize: 14, color: Colors.redAccent),
            ),
            SizedBox(height: 16),
            TextField(
              controller: planIdController,
              decoration: InputDecoration(
                labelText: 'Plan ID',
                hintText: 'Copy from Plans Menu',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: userIdController,
              decoration: InputDecoration(
                labelText: 'User ID',
                hintText: 'Provided in the request Mail',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: requestIdController,
              decoration: InputDecoration(
                labelText: 'Request ID',
                hintText: 'Provided in the request Mail',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedAction,
              items: ['accept', 'reject'].map((action) {
                return DropdownMenuItem(
                  value: action,
                  child: Text(action),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedAction = value!;
                });
              },
              decoration: InputDecoration(
                labelText: 'Action',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 32),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: createSubscription,
              child: Text('Create Subscription'),
            ),
          ],
        ),
      ),
    );
  }
}