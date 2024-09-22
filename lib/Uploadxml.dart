import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http_parser/http_parser.dart';

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

  final GetStorage _storage = GetStorage();

  @override
  void initState() {
    super.initState();
    fetchData(); // Fetch data when the page loads
  }
  Future<void> uploadXML() async {
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
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType('application', 'xml'),
        ),
      });

      var response = await Dio().post(
        url,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('XML uploaded successfully!')),
        );
        fetchData(); // Automatically fetch data after successful upload
      } else {
        var errorMessage = response.data['message'] ?? 'Upload failed.';
        print('Upload failed: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $errorMessage')),
        );
      }
    } catch (e) {
      if (e is DioError) {
        // Log detailed error information
        print('Dio error: ${e.response?.data}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: ${e.response?.data ?? e.message}')),
        );
      } else {
        print('Unexpected error: $e');
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
  Future<void> fetchData() async {
    setState(() {
      _isFetching = true;
    });

    try {
      String url = 'https://iscandata.com/api/v1/products/';
      String? token = _storage.read('token');

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No token found. Please log in.')),
        );
        return;
      }

      var response = await Dio().get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _products = response.data['data']['products'] ?? [];
          _filteredProducts = _products; // Show all data initially
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data fetched successfully!')),
        );
      } else if (response.statusCode == 401) {
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pushReplacementNamed('/login');
        });
        return;
      } else {
        var errorMessage = response.data['message'] ?? 'Fetch failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fetch failed: $errorMessage')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    } finally {
      setState(() {
        _isFetching = false;
      });
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _products.where((product) {
        final upc = product['upc'] ?? '';
        return upc.contains(query);
      }).toList();
    });
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
      _filteredProducts = _products; // Show all data when search is cleared
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload XML and Fetch Products'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _startSearch,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Search by UPC',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: _filterProducts,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: _endSearch,
                    ),
                  ],
                ),
              ),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : uploadXML,
              icon: _isUploading
                  ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : Icon(Icons.upload_file),
              label: Text(_isUploading ? 'Uploading...' : 'Upload XML File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 20),
            _isFetching
                ? Center(
              child: CircularProgressIndicator(),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    color: index % 2 == 0
                        ? Colors.blue[100]
                        : Colors.blue[200],
                    child: ListTile(
                      title: Text(product['department']?['name'] ?? 'No name'),
                      subtitle: Text(
                        'UPC: ${product['upc']}\n'
                            'Department ID: ${product['department']?['id'] ?? 'N/A'}\n'
                            'Price: \$${product['price'] ?? '0.00'}\n'
                            'Description: ${product['description'] ?? 'No description'}',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
