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
  String? userRole; // Declare userRole as a class variable
 ////
  bool isLoading = false;
  List<Map<String, dynamic>> departments = [];
  List<Map<String, dynamic>> filteredDepartments = [];///
  @override
  void initState() {
    super.initState();
    userRole = _storage.read('UserRole');
    // Initialize userRole
  }

  // Automatically fetch data when returning to the page
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    if (userRole == 'admin') {
      _userIdController.text = '';
    } else {
      fetchData('');
    }
  }
  Future<void> _fetchDepartments({String? userId}) async {
    setState(() {
      isLoading = true;
    });

    String baseUrl = 'https://iscandata.com/api/v1/departments';
    String? token = _storage.read('token');
    final url = userId != null ? '$baseUrl?userId=$userId' : baseUrl;

    print('Fetching from URL: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('data') && data['data']['departments'] is List) {
          setState(() {
            departments = List<Map<String, dynamic>>.from(data['data']['departments']);
            filteredDepartments = departments;
          });
        } else {
          setState(() {
            departments = [];
            filteredDepartments = [];
          });
        }
      } else if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        print('Failed to fetch departments. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during department fetch: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> uploadXML() async {
    try {
      // Check user role and fetch departments
      String? userId;
      if (userRole == 'admin') {
        userId = await _promptForUserId();
        if (userId == null || userId.isEmpty) {
          _showSnackBar('User ID is required for admins.');
          return;
        }
      }

      // Fetch departments with the provided userId (for admin)
      await _fetchDepartments(userId: userId);

      // Check if departments are empty
      if (departments.isEmpty) {
        _showAlert('No Departments Found', 'You must add or upload departments before uploading products.');
        return;
      }

      // File selection
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml'],
      );

      if (result == null) {
        _showSnackBar('No file selected.');
        return;
      }

      if (result.files.length > 1) {
        _showSnackBar('Please select only one XML file.');
        return;
      }

      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      if (!fileName.endsWith('.xml')) {
        _showSnackBar('Please select a valid XML file.');
        return;
      }

      String? token = _storage.read('token');
      if (token == null || token.isEmpty) {
        _showSnackBar('No token found. Please log in.');
        return;
      }

      setState(() {
        _isUploading = true;
      });

      // Prepare form data
      Map<String, dynamic> formDataMap = {
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType('application', 'xml'),
        ),
      };

      if (userRole == 'admin') {
        formDataMap['userId'] = userId;
      }

      FormData formData = FormData.fromMap(formDataMap);

      // API request
      var response = await Dio().post(
        'https://iscandata.com/api/v1/products/upload-xml',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      // Handle response
      if (response.statusCode == 200) {
        _showSuccessDialog(response.data);

        // Fetch products automatically after successful upload
        if (userId != null) {
          fetchData(userId);
        } else {
          fetchData('');
        }
      } else {
        final errorMessage = response.data['message'] ?? 'Upload failed.';
        _showSnackBar(errorMessage);
        print('Error: $errorMessage');
      }
    } catch (e) {
      // Error handling
      if (e is DioError) {
        print('DioError: ${e.response?.data}');
        _showSnackBar('Error uploading file: ${e.response?.data ?? e.message}');
      } else {
        print('Unexpected error: $e');
        _showSnackBar('Unexpected error: $e');
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

// Helper to show success dialog
  void _showSuccessDialog(dynamic data) {
    var updatedCount = data['updatedCount'];
    var newCount = data['newCount'];
    var departmentNotFoundCount = data['departmentNotFoundCount'];
    var departmentNotFound = data['departmentNotFound'];
    var updatedProducts = data['updatedProducts'];

    String resultMessage = '''
XML uploaded successfully!
Updated count: $updatedCount
New count: $newCount
Department not found count: $departmentNotFoundCount
''';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Upload Status'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resultMessage),
                if (departmentNotFound != null && departmentNotFound.isNotEmpty) ...[
                  SizedBox(height: 10),
                  Text('Department Not Found Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  DataTable(
                    columns: [
                      DataColumn(label: Text('UPC')),
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
                if (updatedProducts != null && updatedProducts.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Text('Updated Products:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  DataTable(
                    columns: [
                      DataColumn(label: Text('UPC')),
                      DataColumn(label: Text('New Price')),
                      DataColumn(label: Text('Previous Price')),
                    ],
                    rows: updatedProducts.map<DataRow>((item) {
                      return DataRow(cells: [
                        DataCell(Text(item['upc'].toString())),
                        DataCell(Text(item['newPrice'].toString())),
                        DataCell(Text(item['previousPrice'].toString())),
                      ]);
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

// Helper to show SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      String url = 'https://iscandata.com/api/v1/products/${userRole == 'admin' ? '?userId=$userId' : ''}';
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

    var url = 'https://iscandata.com/api/v1/products/$upc?userId=$userId';
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
    };

    try {
      var response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product deleted successfully!')),
        );
        fetchData(userId); // Refresh the product list after deletion
      } else {
        var errorMessage = jsonDecode(response.body)['message'] ?? 'Delete failed.';
        print("ERROR MESSAGE DELETE $errorMessage");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$errorMessage')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting product: $e')),
      );
      print("Error deleting product: $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
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
          ElevatedButton.icon(
            onPressed: _isUploading ? null : uploadXML,
            icon: _isUploading
                ? CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            )
                : Icon(Icons.upload_file),
            label: Text(
              _isUploading ? 'Uploading...' : 'Upload XML File',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
            ),
          ),
          if (userRole == 'admin')
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () async {
                  String? userId = await _promptForUserId();
                  if (userId != null) {
                    fetchData(userId); // Fetch products with the provided userId
                  }
                },
                child: Text('Fetch Products'),
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
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No products to show.\n',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (userRole == 'admin') // Display this message only for admins
                    Text(
                      'Enter User ID to fetch the data.\nHit the "Fetch" button and enter the User ID.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            )
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