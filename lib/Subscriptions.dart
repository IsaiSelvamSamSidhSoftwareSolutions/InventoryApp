import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Import the intl package

class SubscriptionsScreen extends StatefulWidget {
  @override
  _SubscriptionsScreenState createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final storage = GetStorage();
  List subscriptions = [];
  bool isLoading = true;

  // Function to calculate remaining days
  int calculateRemainingDays(String endDate) {
    final end = DateTime.parse(endDate);
    final today = DateTime.now();
    return end.difference(today).inDays;
  }

  // Function to fetch subscriptions from API
  Future<void> fetchSubscriptions() async {
    String token = storage.read('token'); // Get JWT from GetStorage
    final response = await http.get(
      Uri.parse('https://iscandata.com/api/v1/subscriptions'),
      headers: {
        'Authorization': 'Bearer $token', // Pass the token as Bearer
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      setState(() {
        subscriptions = jsonResponse['data']['subscriptions'];
        isLoading = false;
      });
    } else {
      // Handle error
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch subscriptions!')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    // Getting screen height and width using MediaQuery
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Subscriptions'),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : subscriptions.isEmpty
          ? Center(child: Text('No subscriptions available'))
          : ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: subscriptions.length,
        itemBuilder: (context, index) {
          var subscription = subscriptions[index];
          var plan = subscription['plan'];
          bool isActive = subscription['active'];
          String planName = plan['name'];
          String planType = plan['planType'];
          int maxDevices = subscription['maxDevices'];
          String startDate = subscription['startDate'];
          String endDate = subscription['endDate'];
          int remainingDays = calculateRemainingDays(endDate);

          return Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            width: screenWidth, // Full width container
            height: screenHeight * 0.3, // 30% of the screen height
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.04, // Increased top/bottom padding (4% of screen height)
                  horizontal: 16, // Standard horizontal padding
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Plan name
                    Text(
                      planName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // Plan type
                    Text(
                      'Plan Type: $planType',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    // Max devices
                    Text(
                      'Max Devices: $maxDevices',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    // Active status with green color
                    Row(
                      children: [
                        Text(
                          'Active: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        Icon(
                          isActive ? Icons.check_circle : Icons.cancel,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                    // Start date and end date
                    Text(
                      'Start: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(startDate))}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'End: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(endDate))}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    // Remaining days
                    Text(
                      'Days Left: $remainingDays',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}