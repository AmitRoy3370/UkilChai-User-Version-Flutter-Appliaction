import 'dart:io';
import 'package:advocatechai/Auth/AuthService.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:advocatechai/Utils/BaseURL.dart' as BASE_URL;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/AdvocateSpeciality.dart';
import 'package:advocatechai/Utils/AdvocateSpeciality.dart';

class AddCaseRequestPage extends StatefulWidget {
  final String userId;

  const AddCaseRequestPage({super.key, required this.userId});

  @override
  State<AddCaseRequestPage> createState() => _AddCaseRequestPageState();
}

class _AddCaseRequestPageState extends State<AddCaseRequestPage> {
  final TextEditingController caseNameController = TextEditingController();

  List<PlatformFile> selectedFiles = [];

  bool loading = false;

  /// ⚠️ MUST match your enum names exactly
  AdvocateSpeciality? selectedCaseType;


  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true, // 👈 VERY IMPORTANT for Web
    );

    if (result != null) {
      setState(() {
        selectedFiles = result.files;
      });
    }
  }


  Future<void> submitCaseRequest() async {
    if (caseNameController.text.isEmpty || selectedCaseType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final uri = Uri.parse(
        "${BASE_URL.Urls().baseURL}case-request/add",
      );

      final request = http.MultipartRequest("POST", uri);

      request.fields["caseName"] = caseNameController.text.trim();
      request.fields["caseType"] = selectedCaseType!.apiValue;

      request.fields["userId"] = widget.userId;

      for (var file in selectedFiles) {
        if (file.bytes != null) {
          // ✅ WEB
          request.files.add(
            http.MultipartFile.fromBytes(
              "files",
              file.bytes!,
              filename: file.name,
            ),
          );
        } else if (file.path != null) {
          // ✅ ANDROID / IOS
          request.files.add(
            await http.MultipartFile.fromPath(
              "files",
              file.path!,
            ),
          );
        }
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';


      request.headers["Authorization"] = "Bearer $token";

      print("token from add case request :- $token");

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print("response status code :- ${response.statusCode}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Case request submitted successfully")),
        );
        Navigator.pop(context);
      } else {
        throw Exception(responseBody);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Case Request"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Case Name
            TextField(
              controller: caseNameController,
              decoration: const InputDecoration(
                labelText: "Case Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// Case Type
            DropdownButtonFormField<AdvocateSpeciality>(
              value: selectedCaseType,
              items: AdvocateSpeciality.values
                  .map(
                    (type) => DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 18),
                      const SizedBox(width: 8),
                      Text(type.label),
                    ],
                  ),
                ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() => selectedCaseType = value);
              },
              decoration: const InputDecoration(
                labelText: "Case Type",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null ? "Please select case type" : null,
            ),


            const SizedBox(height: 16),

            /// Attachments
            ElevatedButton.icon(
              onPressed: pickFiles,
              icon: const Icon(Icons.attach_file),
              label: const Text("Add Attachments"),
            ),

            if (selectedFiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: selectedFiles
                      .map((f) => ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(f.name),

                  ))
                      .toList(),
                ),
              ),

            const SizedBox(height: 24),

            /// Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : submitCaseRequest,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Case Request"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
