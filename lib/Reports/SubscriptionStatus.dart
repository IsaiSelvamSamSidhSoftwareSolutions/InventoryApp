import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inventary_app_production/AcceptSubscriptionrequest..dart';
class SubscriptionStatus extends StatefulWidget {
  @override
  _SubscriptionRequestsScreenState createState() =>
      _SubscriptionRequestsScreenState();
}

class _SubscriptionRequestsScreenState
    extends State<SubscriptionStatus> {
  final box = GetStorage();
  List<dynamic> subscriptionRequests = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchSubscriptionRequests();
  }

  Future<void> fetchSubscriptionRequests() async {
    setState(() {
      isLoading = true;
    });

    final token = box.read('token');
    final url =
    Uri.parse('https://iscandata.com/api/v1/subscriptionsRequest?status=pending');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          subscriptionRequests = data['data']['subscriptionRequests'];
        });
      } else {
        final error = jsonDecode(response.body);
        showError('Failed to fetch subscription requests: ${error['message']}');
      }
    } catch (e) {
      showError('An error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showConfirmationDialog(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Status Change'),
          content: Text('Are you sure you want to change the status to "Rejected"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                changeStatus(id, 'rejected');
                Navigator.pop(context);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> changeStatus(String id, String status) async {
    final token = box.read('token');
    final url = Uri.parse('https://iscandata.com/api/v1/subscriptionsRequest/$id');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"status": status}),
      );

      if (response.statusCode == 200) {
        fetchSubscriptionRequests();
      } else {
        final error = jsonDecode(response.body);
        showError('Failed to change status: ${error['message']}');
      }
    } catch (e) {
      showError('An error occurred: $e');
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription Pending'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: subscriptionRequests.length,
        itemBuilder: (context, index) {
          final request = subscriptionRequests[index];
          final user = request['user'];
          final plan = request['plan'];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text('${user['userName']} (${user['email']})'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plan: ${plan['name']}'),
                  Text('Status: ${request['status']}'),
                  Text('Requested At: ${DateTime.parse(request['requestedAt']).toLocal()}'),
                  Text('Subscription ID: ${request['_id']}'),
                ],
              ),
              trailing: Switch(
                value: request['status'] == 'rejected',
                activeColor: Colors.red, // Set active color to red
                inactiveThumbColor: Colors.red, // Optional: Color for inactive thumb
                inactiveTrackColor: Colors.grey[300], // Optional: Color for inactive track
                onChanged: (value) {
                  if (!value) return; // Only allow toggle to "rejected"
                  showConfirmationDialog(request['_id']);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
