
// import 'package:flutter/material.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class AdminPlanCreation extends StatefulWidget {
//   @override
//   _AdminPlanCreationState createState() => _AdminPlanCreationState();
// }
//
// class _AdminPlanCreationState extends State<AdminPlanCreation> {
//   final box = GetStorage();
//   List<dynamic> plans = [];
//   bool isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchPlans();
//   }
//
//   Future<void> fetchPlans() async {
//     setState(() {
//       isLoading = true;
//     });
//
//     final token = box.read('token');
//     final url = Uri.parse('https://iscandata.com/api/v1/plans');
//
//     try {
//       final response = await http.get(url, headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       });
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           plans = data['data']['plans'];
//         });
//       } else {
//         final error = jsonDecode(response.body);
//         showError('Failed to fetch plans: ${error['message']}');
//       }
//     } catch (e) {
//       showError('An error occurred: $e');
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   void showUpdateDialog(String id, String currentMaxDevices) {
//     final TextEditingController maxDevicesController =
//     TextEditingController(text: currentMaxDevices);
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Update Max Devices'),
//           content: TextField(
//             controller: maxDevicesController,
//             keyboardType: TextInputType.number,
//             decoration: InputDecoration(
//               labelText: 'Max Devices',
//               border: OutlineInputBorder(),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 String newMaxDevices = maxDevicesController.text.trim();
//                 if (newMaxDevices.isNotEmpty) {
//                   updatePlan(id, newMaxDevices);
//                   Navigator.pop(context);
//                 } else {
//                   showError('Please enter a valid number');
//                 }
//               },
//               child: Text('Update'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<void> updatePlan(String id, String maxDevices) async {
//     final token = box.read('token');
//     final url = Uri.parse('https://iscandata.com/api/v1/plans/$id');
//
//     try {
//       final response = await http.patch(
//         url,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({"maxDevices": maxDevices}),
//       );
//
//       if (response.statusCode == 200) {
//         fetchPlans();
//       } else {
//         final error = jsonDecode(response.body);
//         showError('Failed to update plan: ${error['message']}');
//       }
//     } catch (e) {
//       showError('An error occurred: $e');
//     }
//   }
//
//   Future<void> deletePlan(String id) async {
//     final token = box.read('token');
//     final url = Uri.parse('https://iscandata.com/api/v1/plans/$id');
//
//     try {
//       final response = await http.delete(url, headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       });
//
//       if (response.statusCode == 200) {
//         fetchPlans();
//       } else {
//         final error = jsonDecode(response.body);
//         showError('Failed to delete plan: ${error['message']}');
//       }
//     } catch (e) {
//       showError('An error occurred: $e');
//     }
//   }
//
//   void showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Plan Management'),
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         itemCount: plans.length,
//         itemBuilder: (context, index) {
//           final plan = plans[index];
//           return Card(
//             margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: ListTile(
//               title: Text(plan['name']),
//               subtitle: Text(
//                   'Devices: ${plan['maxDevices']} - Price: \$${plan['price']}'),
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   IconButton(
//                     icon: Icon(Icons.edit),
//                     onPressed: () {
//                       showUpdateDialog(
//                         plan['_id'],
//                         plan['maxDevices'].toString(),
//                       );
//                     },
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.delete),
//                     onPressed: () {
//                       deletePlan(plan['_id']);
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // Add Plan Feature
//         },
//         child: Icon(Icons.add),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart'; // For Clipboard functionality

class AdminPlanCreation extends StatefulWidget {
  @override
  _AdminPlanCreationState createState() => _AdminPlanCreationState();
}

class _AdminPlanCreationState extends State<AdminPlanCreation> {
  final box = GetStorage();
  List<dynamic> plans = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    setState(() {
      isLoading = true;
    });

    final token = box.read('token');
    final url = Uri.parse('https://iscandata.com/api/v1/plans');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          plans = data['data']['plans'];
        });
      } else {
        final error = jsonDecode(response.body);
        showError('Failed to fetch plans: ${error['message']}');
      }
    } catch (e) {
      showError('An error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showUpdateDialog(String id, String currentMaxDevices) {
    final TextEditingController maxDevicesController =
    TextEditingController(text: currentMaxDevices);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Max Devices'),
          content: TextField(
            controller: maxDevicesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Max Devices',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String newMaxDevices = maxDevicesController.text.trim();
                if (newMaxDevices.isNotEmpty) {
                  updatePlan(id, newMaxDevices);
                  Navigator.pop(context);
                } else {
                  showError('Please enter a valid number');
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updatePlan(String id, String maxDevices) async {
    final token = box.read('token');
    final url = Uri.parse('https://iscandata.com/api/v1/plans/$id');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"maxDevices": maxDevices}),
      );

      if (response.statusCode == 200) {
        fetchPlans();
      } else {
        final error = jsonDecode(response.body);
        showError('Failed to update plan: ${error['message']}');
      }
    } catch (e) {
      showError('An error occurred: $e');
    }
  }

  Future<void> deletePlan(String id) async {
    final token = box.read('token');
    final url = Uri.parse('https://iscandata.com/api/v1/plans/$id');

    try {
      final response = await http.delete(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        fetchPlans();
      } else {
        final error = jsonDecode(response.body);
        showError('Failed to delete plan: ${error['message']}');
      }
    } catch (e) {
      showError('An error occurred: $e');
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void copyToClipboard(String planID) {
    Clipboard.setData(ClipboardData(text: planID));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Plan ID copied to clipboard')));
  }
  Future<void> addPlan(String name, String maxDevices, String price, String planType) async {
    final token = box.read('token');
    final url = Uri.parse('https://iscandata.com/api/v1/plans');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "name": name,
          "maxDevices": maxDevices,
          "price": price,
          "planType": planType,
        }),
      );

      if (response.statusCode == 201) {
        fetchPlans(); // Refresh plans list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plan added successfully!')),
        );
      } else {
        final error = jsonDecode(response.body);
        showError('Failed to add plan: ${error['message']}');
      }
    } catch (e) {
      showError('An error occurred: $e');
    }
  }

  void showAddPlanBottomSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController maxDevicesController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final List<String> planTypes = ['monthly', '3months', '6months', 'yearly'];
    String? selectedPlanType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add New Plan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Plan Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: maxDevicesController,
                  decoration: InputDecoration(
                    labelText: 'Max Devices',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPlanType,
                  decoration: InputDecoration(
                    labelText: 'Plan Type',
                    border: OutlineInputBorder(),
                  ),
                  items: planTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedPlanType = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a plan type';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final maxDevices = maxDevicesController.text.trim();
                    final price = priceController.text.trim();

                    if (name.isNotEmpty &&
                        maxDevices.isNotEmpty &&
                        price.isNotEmpty &&
                        selectedPlanType != null) {
                      addPlan(name, maxDevices, price, selectedPlanType!);
                      Navigator.pop(context); // Close the bottom sheet
                    } else {
                      showError('All fields are required');
                    }
                  },
                  child: Text('Add Plan'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plan Management'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(plan['name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plan ID: ${plan['_id']}'),
                  Text('Devices: ${plan['maxDevices']}'),
                  Text('Price: \$${plan['price']}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.content_copy),
                    onPressed: () {
                      copyToClipboard(plan['_id']);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      showUpdateDialog(
                        plan['_id'],
                        plan['maxDevices'].toString(),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      deletePlan(plan['_id']);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add Plan Feature
          showAddPlanBottomSheet();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
