// // import 'dart:convert';
// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:file_picker/file_picker.dart';
// // import 'package:dio/dio.dart';
// // import 'package:get_storage/get_storage.dart';
// // import 'package:http_parser/http_parser.dart';
// // import 'package:flutter/scheduler.dart';
// // import 'package:http/http.dart' as http;
// // class UploadAndFetchPage extends StatefulWidget {
// //   @override
// //   _UploadAndFetchPageState createState() => _UploadAndFetchPageState();
// // }
// //
// // class _UploadAndFetchPageState extends State<UploadAndFetchPage> {
// //   bool _isUploading = false;
// //   bool _isFetching = false;
// //   List<dynamic> _products = [];
// //   List<dynamic> _filteredProducts = [];
// //   final TextEditingController _searchController = TextEditingController();
// //   bool _isSearching = false;
// //   final TextEditingController _userIdController = TextEditingController();
// //   final GetStorage _storage = GetStorage();
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     //fetchData(); // Fetch data when the page loads
// //   }
// //
// //   // Automatically fetch data when returning to the page
// //   @override
// //   void didChangeDependencies() {
// //     super.didChangeDependencies();
// //     fetchData();
// //   }
// //
// //   // Use this method if you need to ensure fetching data
// //   @override
// //   void didUpdateWidget(UploadAndFetchPage oldWidget) {
// //     super.didUpdateWidget(oldWidget);
// //     fetchData();
// //   }
// //   Future<void> uploadXML() async {
// //     FilePickerResult? result = await FilePicker.platform.pickFiles(
// //       type: FileType.custom,
// //       allowedExtensions: ['xml'],
// //     );
// //
// //     if (result == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('No file selected.')),
// //       );
// //       return;
// //     }
// //
// //     if (result.files.length > 1) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Please select only one XML file.')),
// //       );
// //       return;
// //     }
// //
// //     File file = File(result.files.single.path!);
// //     String fileName = result.files.single.name;
// //
// //     if (!fileName.endsWith('.xml')) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Please select a valid XML file.')),
// //       );
// //       return;
// //     }
// //
// //     String url = 'https://iscandata.com/api/v1/products/upload-xml';
// //     String? token = _storage.read('token');
// //
// //     if (token == null || token.isEmpty) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('No token found. Please log in.')),
// //       );
// //       return;
// //     }
// //
// //     setState(() {
// //       _isUploading = true;
// //     });
// //
// //     String? userRole = _storage.read('UserRole');
// //     String? userId; // Variable to hold userId for admin
// //
// //     // If the user is an admin, prompt for the userId
// //     if (userRole == 'admin') {
// //       userId = await _promptForUserId();
// //       if (userId == null) {
// //         setState(() {
// //           _isUploading = false;
// //         });
// //         return; // Exit if no userId is provided
// //       }
// //     }
// //
// //     try {
// //       Map<String, dynamic> formDataMap = {
// //         'file': await MultipartFile.fromFile(
// //           file.path,
// //           filename: fileName,
// //           contentType: MediaType('application', 'xml'),
// //         ),
// //       };
// //
// //       // Include userId if the user is an admin
// //       if (userRole == 'admin') {
// //         formDataMap['userId'] = userId;
// //       }
// //
// //       FormData formData = FormData.fromMap(formDataMap);
// //
// //       var response = await Dio().post(
// //         url,
// //         data: formData,
// //         options: Options(
// //           headers: {'Authorization': 'Bearer $token'},
// //           validateStatus: (status) => status! < 500,
// //         ),
// //       );
// //
// //       if (response.statusCode == 200) {
// //         var message = response.data['message'];
// //         var uploadedCount = response.data['uploadedCount'];
// //         var departmentNotFoundCount = response.data['departmentNotFoundCount'];
// //         var timeTaken = response.data['timeTaken'];
// //         var alreadyExistingCount = response.data['alreadyExistingCount'];
// //         var departmentNotFound = response.data['departmentNotFound'];
// //
// //         // Constructing the result message
// //         String resultMessage =
// //             "XML uploaded successfully!\n"
// //             "Time taken: $timeTaken seconds\n"
// //             "Uploaded count: $uploadedCount\n"
// //             "Already existing count: $alreadyExistingCount\n"
// //             "Department not found count: $departmentNotFoundCount\n";
// //
// //         // Showing the alert dialog
// //         showDialog(
// //           context: context,
// //           builder: (BuildContext context) {
// //             return AlertDialog(
// //               title: Text('Upload Status'),
// //               content: SingleChildScrollView(
// //                 child: Column(
// //                   children: <Widget>[
// //                     Text(resultMessage),
// //                     SizedBox(height: 10), // Add some space
// //                     Text('Department Not Found Details:',
// //                         style: TextStyle(fontWeight: FontWeight.bold)),
// //                     SizedBox(height: 10),
// //                     DataTable(
// //                       columns: [
// //                         DataColumn(label: Text('UPC')),
// //                         DataColumn(label: Text('DeptId')),
// //                       ],
// //                       rows: departmentNotFound.map<DataRow>((
// //                           item) { // Ensure proper mapping to DataRow
// //                         return DataRow(cells: [
// //                           DataCell(Text(item['upc'].toString())),
// //                           // UPC column
// //                           DataCell(Text(item['departmentId'].toString())),
// //                           // Department ID column
// //                         ]);
// //                       }).toList(),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               actions: <Widget>[
// //                 TextButton(
// //                   child: Text('OK'),
// //                   onPressed: () {
// //                     Navigator.of(context).pop(); // Close the dialog
// //                     fetchData(); // Automatically fetch data after successful upload
// //                   },
// //                 ),
// //               ],
// //             );
// //           },
// //         );
// //       } else {
// //         var errorMessage = response.data['message'] ?? 'Upload failed.';
// //         print(' $errorMessage');
// //
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('$errorMessage')),
// //         );
// //       }
// //     } catch (e) {
// //       if (e is DioError) {
// //         print('Dio error: ${e.response?.data}');
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text(
// //               'Error uploading file: ${e.response?.data ?? e.message}')),
// //         );
// //       } else {
// //         print('Unexpected error: $e');
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Unexpected error: $e')),
// //         );
// //       }
// //     } finally {
// //       setState(() {
// //         _isUploading = false;
// //       });
// //     }
// //   }
// //
// // // Helper function to show an alert dialog for userId input
// //   Future<String?> _promptForUserId() async {
// //     TextEditingController userIdController = TextEditingController();
// //     String? userId;
// //
// //     await showDialog<String>(
// //       context: context,
// //       builder: (BuildContext context) {
// //         return AlertDialog(
// //           title: Text('Enter Admin UserId'),
// //           content: TextField(
// //             controller: userIdController,
// //             decoration: InputDecoration(
// //               labelText: 'UserId',
// //             ),
// //           ),
// //           actions: <Widget>[
// //             TextButton(
// //               child: Text('Cancel'),
// //               onPressed: () {
// //                 Navigator.of(context).pop(null); // Return null if canceled
// //               },
// //             ),
// //             TextButton(
// //               child: Text('Submit'),
// //               onPressed: () {
// //                 userId = userIdController.text;
// //                 Navigator.of(context).pop(userId);
// //               },
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //
// //     return userId;
// //   }
// //   Future<void> fetchData() async {
// //     setState(() {
// //       _isFetching = true;
// //     });
// //
// //     var client = http.Client();
// //
// //     try {
// //       String url = 'https://iscandata.com/api/v1/products/';
// //       String? token = _storage.read('token');
// //
// //       if (token == null || token.isEmpty) {
// //         // Schedule the snack bar to appear after the build frame
// //         SchedulerBinding.instance.addPostFrameCallback((_) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(content: Text('No token found. Please log in.')),
// //           );
// //         });
// //         return;
// //       }
// //
// //       String? userId;
// //       String? userRole = _storage.read('UserRole');
// //
// //       // Get User ID from text field if user is admin
// //       if (userRole == 'admin') {
// //         userId = _userIdController.text;
// //         if (userId.isEmpty) {
// //           // Schedule the snack bar to appear after the build frame
// //           SchedulerBinding.instance.addPostFrameCallback((_) {
// //             ScaffoldMessenger.of(context).showSnackBar(
// //               SnackBar(content: Text('Please enter User ID.')),
// //             );
// //           });
// //           return; // Exit if no user ID is provided
// //         }
// //       }
// //
// //       // Use http's `Client` class to send a GET request with query parameters
// //       var headers = {
// //         'Authorization': 'Bearer $token',
// //       };
// //       var params = {
// //         'userId': userId,
// //       };
// //
// //       var uri = Uri.parse(url);
// //       var requestUri = uri.replace(queryParameters: params);
// //
// //       print('Request URL: $requestUri');
// //       print('Request Headers: $headers');
// //
// //       var response = await client.get(
// //         requestUri,
// //         headers: headers,
// //       );
// //
// //       print('Response Status Code: ${response.statusCode}');
// //       print('Response Body: ${response.body}');
// //
// //       if (response.statusCode == 200) {
// //         setState(() {
// //           _products = jsonDecode(response.body)['data']['products'] ?? [];
// //           _filteredProducts = _products; // Show all data initially
// //         });
// //         // Schedule the snack bar to appear after the build frame
// //         SchedulerBinding.instance.addPostFrameCallback((_) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(content: Text('Data fetched successfully!')),
// //           );
// //         });
// //       } else if (response.statusCode == 401) {
// //         Future.delayed(Duration(seconds: 2), () {
// //           Navigator.of(context).pushReplacementNamed('/login');
// //         });
// //         return;
// //       } else {
// //         var errorMessage = jsonDecode(response.body)['message'] ?? 'Fetch failed.';
// //         print('$errorMessage --$errorMessage');
// //         // Schedule the snack bar to appear after the build frame
// //         SchedulerBinding.instance.addPostFrameCallback((_) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(content: Text('$errorMessage')),
// //           );
// //         });
// //       }
// //     } catch (e) {
// //       print("ERROR FETCHING --Error fetching data: $e ");
// //       // Schedule the snack bar to appear after the build frame
// //       SchedulerBinding.instance.addPostFrameCallback((_) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Error fetching data: $e')),
// //         );
// //       });
// //     } finally {
// //       setState(() {
// //         _isFetching = false;
// //       });
// //       client.close();
// //     }
// //   }
// //   void _startSearch() {
// //     setState(() {
// //       _isSearching = true;
// //     });
// //   }
// //
// //   void _endSearch() {
// //     setState(() {
// //       _isSearching = false;
// //       _searchController.clear();
// //       _filteredProducts = _products; // Reset the filtered products
// //     });
// //   }
// //
// //   void _searchProducts(String query) {
// //     final filtered = _products.where((product) {
// //       return product['upc']?.toString().contains(query) ?? false;
// //     }).toList();
// //
// //     setState(() {
// //       _filteredProducts = filtered;
// //     });
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     String? userRole = _storage.read('UserRole'); // Get user role to determine UI changes
// //
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Upload XML and Fetch Products', style: TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.blueAccent,
// //         actions: [
// //           IconButton(
// //             icon: Icon(Icons.search),
// //             onPressed: _startSearch,
// //           ),
// //         ],
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           children: [
// //             if (userRole == 'admin') // Show User ID text field only for admin
// //               Padding(
// //                 padding: const EdgeInsets.only(bottom: 16.0),
// //                 child: TextField(
// //                   controller: _userIdController,
// //                   decoration: InputDecoration(
// //                     border: OutlineInputBorder(),
// //                     labelText: 'Enter User ID',
// //                     hintText: 'User ID for Admin',
// //                   ),
// //                 ),
// //               ),
// //             Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 ElevatedButton.icon(
// //                   onPressed: _isUploading ? null : uploadXML,
// //                   icon: _isUploading
// //                       ? CircularProgressIndicator(
// //                     valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
// //                   )
// //                       : Icon(Icons.upload_file),
// //                   label: Text(
// //                     _isUploading ? 'Uploading...' : 'Upload XML File',
// //                     style: TextStyle(color: Colors.white),
// //                   ),
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: Colors.blueAccent,
// //                   ),
// //                 ),
// //                 IconButton(
// //                   icon: Icon(Icons.refresh),
// //                   onPressed: _isFetching ? null : () {
// //                     fetchData();
// //                   },
// //                   tooltip: 'Refresh Data',
// //                 ),
// //               ],
// //             ),
// //             SizedBox(height: 20),
// //             _isFetching
// //                 ? Center(child: CircularProgressIndicator())
// //                 : Expanded(
// //               child: ListView.builder(
// //                 itemCount: _filteredProducts.length,
// //                 itemBuilder: (context, index) {
// //                   final product = _filteredProducts[index];
// //                   return Card(
// //                     margin: EdgeInsets.symmetric(vertical: 8),
// //                     color: index % 2 == 0 ? Colors.blue[100] : Colors.blue[200],
// //                     child: ListTile(
// //                       title: Text(
// //                         'Description: ${product['description'] ?? 'No description'}',
// //                         style: TextStyle(
// //                           color: Colors.black,
// //                           fontSize: 15,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                       subtitle: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Text('UPC: ${product['upc'] ?? 'N/A'}'),
// //                           Text('Department ID: ${product['department']?['id'] ?? 'N/A'}'),
// //                           Text('Price: \$${product['price'] ?? 'N/A'}'),
// //                         ],
// //                       ),
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;

class UploadAndFetchPage extends StatefulWidget {
  @override
  _UploadAndFetchPageState createState() => _UploadAndFetchPageState();
}

class _UploadAndFetchPageState extends State<UploadAndFetchPage> {
  bool _isUploading = false;
  bool _isFetching = false;
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final TextEditingController _userIdController = TextEditingController();
  final GetStorage _storage = GetStorage();

  @override
  void initState() {
    super.initState();
    //fetchData(); // Fetch data when the page loads
  }

  // Automatically fetch data when returning to the page
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    String? userRole = _storage.read('User Role');
    if (userRole == 'admin') {
      _userIdController.text = '';
    } else {
      fetchData('');
    }
  }

  // Use this method if you need to ensure fetching data
  @override
  void didUpdateWidget(UploadAndFetchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    String? userRole = _storage.read('User Role');
    if (userRole == 'admin') {
      _userIdController.text = '';
    } else {
      fetchData('');
    }
  }

  Future<void> uploadXML(String userId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
    );

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file selected.')),
      );
      return;
    }

    if (result.files.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select only one XML file.')),
      );
      return;
    }

    File file = File(result.files.single.path!);
    String fileName = result.files.single.name;

    if (!fileName.endsWith('.xml')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a valid XML file.')),
      );
      return;
    }

    String url = 'https://iscandata.com/api/v1/products/upload-xml';
    String? token = _storage.read('token');

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No token found. Please log in.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      Map<String, dynamic> formDataMap = {
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType('application', ' xml'),
        ),
      };

      // Include userId if the user is an admin
      if (userId.isNotEmpty) {
        formDataMap['userId'] = userId;
      }

      FormData formData = FormData.fromMap(formDataMap);

      var response = await Dio().post(
        url,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        var message = response.data['message'];
        var uploadedCount = response.data['uploadedCount'];
        var departmentNotFoundCount = response.data['departmentNotFoundCount'];
        var timeTaken = response.data['timeTaken'];
        var alreadyExistingCount = response.data['alreadyExistingCount'];
        var departmentNotFound = response.data['departmentNotFound'];

        // Constructing the result message
        String resultMessage =
            "XML uploaded successfully!\n"
            "Time taken: $timeTaken seconds\n"
            "Uploaded count: $uploadedCount\n"
            "Already existing count: $alreadyExistingCount\n"
            "Department not found count: $departmentNotFoundCount\n";

        // Showing the alert dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Upload Status'),
              content: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Text(resultMessage),
                    SizedBox(height: 10), // Add some space
                    Text('Department Not Found Details:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    DataTable(
                      columns: [
                        DataColumn(label: Text ('UPC')),
                        DataColumn(label: Text('DeptId')),
                      ],
                      rows: departmentNotFound.map<DataRow>((item) {
                        return DataRow(cells: [
                          DataCell(Text(item['upc'].toString())),
                          DataCell(Text(item['departmentId'].toString())),
                        ]);
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    fetchData(userId); // Automatically fetch data after successful upload
                  },
                ),
              ],
            );
          },
        );
      } else {
        var errorMessage = response.data['message'] ?? 'Upload failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$errorMessage')),
        );
      }
    } catch (e) {
      if (e is DioError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: ${e.response?.data ?? e.message}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Helper function to show an alert dialog for userId input
  Future<String?> _promptForUserId() async {
    TextEditingController userIdController = TextEditingController();
    String? userId;

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Admin UserId'),
          content: TextField(
            controller: userIdController,
            decoration: InputDecoration(
              labelText: 'UserId',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null); // Return null if canceled
              },
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                userId = userIdController.text;
                Navigator.of(context).pop(userId);
              },
            ),
          ],
        );
      },
    );

    return userId;
  }

  Future<void> fetchData(String userId) async {
    setState(() {
      _isFetching = true;
    });

    var client = http.Client();
    try {
      String url = 'https://iscandata.com/api/v1/products/?userId=$userId';
      String? token = _storage.read('token');

      if (token == null || token.isEmpty) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No token found. Please log in.')),
          );
        });
        return;
      }

      var headers = {'Authorization': 'Bearer $token'};
      var response = await client.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        setState(() {
          _products = jsonDecode(response.body)['data']['products'] ?? [];
          _filteredProducts = _products;
        });
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Products fetched successfully!')),
          );
        });
      } else {
        var errorMessage = jsonDecode(response.body)['message'] ?? 'Fetch failed.';
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$errorMessage')),
          );
        });
      }
    } catch (e) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      });
    } finally {
      setState(() {
        _isFetching = false;
      });
      client.close();
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _endSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _filteredProducts = _products;
    });
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _products;
      });
    } else {
      setState(() {
        _filteredProducts = _products.where((product) {
          final nameLower = product['description'].toLowerCase();
          final upcLower = product['upc'].toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return nameLower.contains(searchLower) || upcLower.contains(searchLower);
        }).toList();
      });
    }
  }

  Future<void> _updateProduct(String upc, String description, String userId) async {
    setState(() {
      _isUploading = true;
    });

    var url = 'https://iscandata.com/api/v1/products/$upc';
    String? token = _storage.read ('token');

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No token found. Please log in.')),
      );
      setState(() {
        _isUploading = false;
      });
      return;
    }

    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    var body = jsonEncode({
      'description': description,
      'userId': userId, // Include the userId in the request body
    });

    try {
      var response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product updated successfully!')),
        );
        fetchData(userId); // Refresh the product list after update
      } else {
        var errorMessage = jsonDecode(response.body)['message'] ?? 'Update failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$errorMessage')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating product: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _deleteProduct(String upc, String userId) async {
    setState(() {
      _isUploading = true;
    });

    var url = 'https://iscandata.com/api/v1/products/$upc';
    String? token = _storage.read('token');

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No token found. Please log in.')),
      );
      setState(() {
        _isUploading = false;
      });
      return;
    }

    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    var body = jsonEncode({
      'userId': userId, // Include the userId in the request body
    });

    try {
      var response = await http.delete(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product deleted successfully!')),
        );
        fetchData(userId); // Refresh the product list after deletion
      } else {
        var errorMessage = jsonDecode(response.body)['message'] ?? 'Delete failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$errorMessage')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting product: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? userRole = _storage.read('User Role');
    return Scaffold(
      appBar: AppBar(
        title: Text('List of Products'),
        backgroundColor: Colors.blue,
        actions: [
          // Refresh icon to refetch products for the same user
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              if (userRole == 'admin') {
                String userId = _userIdController.text;
                if (userId.isNotEmpty) {
                  fetchData(userId);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a User ID first')),
                  );
                }
              } else {
                fetchData('');
              }
            },
          ),
        ],
      ),
      body: _isFetching
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (userRole == 'admin')
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _userIdController,
                decoration: InputDecoration(
                  labelText: 'Enter User ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      String userId = _userIdController.text;
                      if (userId.isNotEmpty) {
                        fetchData(userId);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter a User ID')),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          _products.isNotEmpty
              ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search products by description or UPC',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterProducts,
            ),
          )
              : Container(),
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center (child: Text('No products available'))
                : ListView.builder(
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  color: index % 2 == 0 ? Colors.blue[100] : Colors.blue[200],
                  child: ListTile(
                    title: Text(
                      'Description: ${product['description'] ?? 'No description'}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('UPC: ${product['upc'] ?? 'N/A'}'),
                        Text('Department ID: ${product['department']?['id'] ?? 'N/A'}'),
                        Text('Price: \$${product['price'] ?? 'N/A'}'),
                      ],
                    ),
                    trailing: userRole == 'admin'
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () async {
                            var userId = product['userId'];
                            var newDescription =
                            await _promptForNewDescription(
                                product['description']);
                            if (newDescription != null) {
                              _updateProduct(product['upc'], newDescription,
                                  userId);
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            var userId = product['userId'];
                            _deleteProduct(product['upc'], userId);
                          },
                        ),
                      ],
                    )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to show a dialog for updating the product description
  Future<String?> _promptForNewDescription(String currentDescription) async {
    TextEditingController descriptionController =
    TextEditingController(text: currentDescription);
    String? newDescription;

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Product Description'),
          content: TextField(
            controller: descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null); // Return null if canceled
              },
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                newDescription = descriptionController.text;
                Navigator.of(context).pop(newDescription);
              },
            ),
          ],
        );
      },
    );

    return newDescription;
  }
}