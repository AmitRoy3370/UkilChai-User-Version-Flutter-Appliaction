import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './case_request.dart';
import './case_request_service.dart';
import '../Utils/AdvocateSpeciality.dart';
import 'CaseRequestAttachmentViewer.dart';

class EditCaseRequestPage extends StatefulWidget {
  final CaseRequest caseRequest;

  const EditCaseRequestPage({super.key, required this.caseRequest});

  @override
  State<EditCaseRequestPage> createState() => _EditCaseRequestPageState();
}

class _EditCaseRequestPageState extends State<EditCaseRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final List<PlatformFile> files = [];
  bool loading = false;
  late AdvocateSpeciality selectedType;
  late List<String> existingAttachments;
  final List<PlatformFile> newFiles = [];

  final service = CaseRequestService();

  @override
  void initState() {
    super.initState();
    nameCtrl.text = widget.caseRequest.caseName;
    selectedType = widget.caseRequest.caseType;
    existingAttachments = List.from(widget.caseRequest.attachmentId);
  }

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true, // 🔥 REQUIRED for Web
    );

    if (result != null) {
      setState(() {
        newFiles.addAll(result.files);
      });
    }
  }

  Future<void> deleteExistingAttachment(String id) async {
    final ok = await service.deleteAttachment(id);
    if (ok && mounted) {
      setState(() {
        existingAttachments.remove(id);
      });
    }
  }

  Future<void> update() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final ok = await service.updateCaseRequest(
      caseRequestId: widget.caseRequest.id,
      caseName: nameCtrl.text.trim(),
      caseType: selectedType.apiValue,
      userId: widget.caseRequest.userId,
      existingFiles: existingAttachments, // ✅ String list
      files: newFiles, // ✅ PlatformFile list
    );

    setState(() => loading = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Case updated successfully")),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Case Request")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "Case Name"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<AdvocateSpeciality>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: "Case Type"),
                      items: AdvocateSpeciality.values
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => selectedType = v);
                      },
                    ),

                    const SizedBox(height: 20),

                    /// -------- EXISTING FILES --------
                    const Text(
                      "Existing Attachments",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    if (existingAttachments.isEmpty)
                      const Text("No existing files"),

                    ...existingAttachments.map(
                      (id) => ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: Text(id),
                        onTap: () async {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          String jwtToken = prefs.getString('jwt_token') ?? '';

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CaseRequestAttachmentViewer(
                                attachmentId: id,
                                jwtToken: jwtToken,
                              ),
                            ),
                          );
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteExistingAttachment(id),
                        ),
                      ),
                    ),

                    const Divider(height: 32),

                    /// -------- NEW FILES --------
                    const Text(
                      "New Files",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add Files"),
                      onPressed: pickFiles,
                    ),

                    ...newFiles.asMap().entries.map(
                      (e) => ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(e.value.name),

                        onTap: () async {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          String jwtToken = prefs.getString('jwt_token') ?? '';

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CaseRequestAttachmentViewer(
                                attachmentId: e.value.name,
                                jwtToken: jwtToken,
                              ),
                            ),
                          );
                        },

                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              newFiles.removeAt(e.key);
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: update,
                      child: const Text("Update Case Request"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
