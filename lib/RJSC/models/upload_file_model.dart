// lib/RJSC/models/upload_file_model.dart
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Universal file model — Web এবং Mobile উভয়েই কাজ করে
class UploadFileModel {
  final String fileName;
  final Uint8List? bytes;   // Web-এ এটিই ব্যবহার হবে
  final String? path;       // Mobile-এ এটিই ব্যবহার হবে

  UploadFileModel({
    required this.fileName,
    this.bytes,
    this.path,
  });

  /// ✅ FIXED: FilePicker এর PlatformFile থেকে তৈরি
  /// Web-এ path access করা যাবে না, তাই kIsWeb চেক করে নিতে হবে
  factory UploadFileModel.fromPlatformFile(PlatformFile file) {
    if (kIsWeb) {
      // Web-এ শুধু bytes ব্যবহার করব — path access করব না
      return UploadFileModel(
        fileName: file.name,
        bytes: file.bytes,
        path: null,
      );
    } else {
      // Mobile-এ path ব্যবহার করব
      return UploadFileModel(
        fileName: file.name,
        bytes: file.bytes,
        path: file.path,
      );
    }
  }

  /// Mobile-এর জন্য (dart:io File থেকে)
  factory UploadFileModel.fromPath(String filePath, String fileName) {
    return UploadFileModel(
      fileName: fileName,
      path: filePath,
    );
  }

  /// Extension বের করা
  String get extension {
    if (fileName.contains('.')) {
      return fileName.split('.').last.toLowerCase();
    }
    return '';
  }
}