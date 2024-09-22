// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:get_storage/get_storage.dart';
//
// class PlansScreen extends StatefulWidget {
//   @override
//   _PlansScreenState createState() => _PlansScreenState();
// }
//
// class _PlansScreenState extends State<PlansScreen> {
//   List<dynamic> plans = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchPlans();
//   }
//
//   Future<void> fetchPlans() async {
//     final box = GetStorage();
//     final String? token = box.read('token');
//
//     final response = await http.get(
//       Uri.parse('https://iscandata.com/api/v1/plans'),
//       headers: {
//         'Authorization': 'Bearer $token',
//       },
//     );
//
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       setState(() {
//         plans = data['data']['plans'];
//         isLoading = false;
//       });
//     } else if (response.statusCode == 401) {
//       // Redirect to login on unauthorized access
//       Navigator.of(context).pushReplacementNamed('/login');
//     } else {
//       setState(() {
//         isLoading = false;
//       });
//       print('Error fetching plans: ${response.statusCode}');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Subscription Plans"),
//         backgroundColor: Colors.deepPurple,
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           children: plans.map((plan) => _buildPlanCard(plan)).toList(),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPlanCard(dynamic plan) {
//     Color cardColor = plan['planType'] == 'free'
//         ? Colors.greenAccent
//         : Colors.orangeAccent;
//
//     // Label for free plans
//     String priceLabel = plan['price'] == 0 ? "Free" : "\$${plan['price']}";
//
//     return Card(
//       elevation: 4,
//       margin: EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               plan['name'],
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               "Max Devices: ${plan['maxDevices']}",
//               style: TextStyle(fontSize: 16),
//             ),
//             SizedBox(height: 16),
//             Align(
//               alignment: Alignment.center,
//               child: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: cardColor,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   priceLabel,
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 16),
//             Center(
//               child: ElevatedButton(
//                 onPressed: () {
//                   // Implement purchase logic here
//                 },
//                 child: Text("Choose Plan" , style: TextStyle(color: Colors.white),),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blueAccent,
//                   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
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

  @override
  void initState() {
    super.initState();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    final box = GetStorage();
    final String? token = box.read('token');

    final response = await http.get(
      Uri.parse('https://iscandata.com/api/v1/plans'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        plans = data['data']['plans'];
        isLoading = false;
      });
    } else if (response.statusCode == 401) {
      // Redirect to login on unauthorized access
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      setState(() {
        isLoading = false;
      });
      print('Error fetching plans: ${response.statusCode}');
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
        title: Text("Subscription Plans",style:TextStyle(color: Colors.white)),
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
    final box = GetStorage(); // Initialize GetStorage here

    Color cardColor = plan['planType'] == 'free'
        ? Colors.greenAccent
        : Colors.orangeAccent;

    // Label for free plans
    String priceLabel = plan['price'] == 0 ? "Free" : "\$${plan['price']}";

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
                onPressed: () {
                  // Store plan ID in GetStorage
                  box.write('selectedPlanId', plan['_id']); // Use '_id' instead of 'id'
                  subscribeToPlan(plan['_id']); // Use '_id' instead of 'id'
                },
                child: Text("Choose Plan", style: TextStyle(color: Colors.white)),
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

    final response = await http.post(
      Uri.parse('https://iscandata.com/api/v1/subscriptionsRequest'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'planId': planId}), // planId should be correct now
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      _showAlert(responseData['message']);
    } else {
      print('Error subscribing to plan: ${response.statusCode}');
      _showAlert('Something went wrong! Please try again.');
    }
  }
}