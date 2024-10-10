import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';

class PlansScreen extends StatefulWidget {
  @override
  _PlansScreenState createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  List<dynamic> plans = [];
  bool isLoading = true;
  List<dynamic> subscriptions = [];

  @override
  void initState() {
    super.initState();
    fetchPlans();
    _loadUserSubscriptions();
  }

  Future<void> fetchPlans() async {
    final box = GetStorage();
    final String? token = box.read('token');

    try {
      final response = await http
          .get(
        Uri.parse('https://iscandata.com/api/v1/plans'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(Duration(seconds: 15));

      print('API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          plans = data['data']['plans']
              .where((plan) => plan['price'] != null && plan['price'] > 0)
              .toList();
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        setState(() {
          isLoading = false;
        });
        _showAlert('Error: ${response.statusCode}, ${response.body}');
        print('Error fetching plans: ${response.statusCode}, ${response.body}');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      _showAlert('Failed to load data. Please try again later.');
      print('Error: $error');
    }
  }

  Future<void> _loadUserSubscriptions() async {
    final box = GetStorage();
    final String? token = box.read('token');

    try {
      final response = await http
          .get(
        Uri.parse('https://iscandata.com/api/v1/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          subscriptions = userData['data']['user']['subscriptions'];
        });
      } else {
        print('Error fetching user data: ${response.statusCode}');
      }
    } catch (error) {
      print('Error loading subscriptions: $error');
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Subscription Status'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Plans", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: plans.map((plan) => _buildPlanCard(plan)).toList(),
        ),
      ),
    );
  }

  Widget _buildPlanCard(dynamic plan) {
    bool isActive = subscriptions.contains(plan['_id']); // Check if the plan is active

    Color cardColor = isActive ? Colors.green.withOpacity(0.3) : Colors.blueAccent;

    String priceLabel = "\$${plan['price']}";

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan['name'],
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Max Devices: ${plan['maxDevices']}",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  priceLabel,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: isActive ? null : () {
                  // Only enable if not active
                  GetStorage().write('selectedPlanId', plan['_id']);
                  subscribeToPlan(plan['_id']);
                },
                child: Text(isActive ? "Activated" : "Choose Plan",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> subscribeToPlan(String planId) async {
    final box = GetStorage();
    final String? token = box.read('token');

    try {
      final response = await http.post(
        Uri.parse('https://iscandata.com/api/v1/subscriptionsRequest'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'planId': planId}),
      ).timeout(Duration(seconds: 15));

      print('Subscription Response: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        GetStorage().write('activeSubscriptionId', planId); // Store the active subscription ID
        _showAlert(responseData['message']);
        setState(() {
          subscriptions.add(planId); // Update the subscriptions list
        });
      } else {
        print('Error subscribing to plan: ${response.statusCode}');
        _showAlert('Something went wrong! Please try again.');
      }
    } catch (error) {
      _showAlert('Failed to subscribe. Please try again later.');
      print('Error during subscription: $error');
    }
  }
}
