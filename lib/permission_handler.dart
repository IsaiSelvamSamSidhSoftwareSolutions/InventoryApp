import 'package:permission_handler/permission_handler.dart';

Future<void> _requestCameraPermission() async {
  final status = await Permission.camera.request();
  if (status.isGranted) {
    // Permission granted, proceed with camera functionality
  } else if (status.isDenied) {
    // Permission denied, handle accordingly
  } else if (status.isPermanentlyDenied) {
    // Permission permanently denied, redirect to app settings
    openAppSettings();
  }
}

@override
void initState() {
  super.initState();
  _requestCameraPermission();
}
