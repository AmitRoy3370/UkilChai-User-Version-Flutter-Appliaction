import 'package:advocatechai/Utils/AdvocateSpeciality.dart';
import 'package:flutter/material.dart';
import './case_request.dart';
import './case_request_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Utils/BaseURL.dart' as BASE_URL;

class CaseRequestDetailsPage extends StatelessWidget {
  final CaseRequest caseRequest;
  final service = CaseRequestService();

  CaseRequestDetailsPage({super.key, required this.caseRequest});

  void openAttachment(String id) {
    launchUrl(
      Uri.parse("${BASE_URL.Urls().baseURL}case-request/attachment/view/$id"),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Case Details")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            Text("Case Name", style: Theme.of(context).textTheme.titleMedium),
            Text(caseRequest.caseName),
            const Divider(),

            Text("Case Type"),
            Chip(label: Text(caseRequest.caseType.label)),
            const Divider(),

            Text("Requested By"),
            Text(caseRequest.userId),
            const Divider(),

            Text("Attachments"),
            caseRequest.attachmentId.isEmpty
                ? const Text("No attachments")
                : Column(
              children: caseRequest.attachmentId.map((id) {
                return ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: Text(id),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => openAttachment(id),
                  ),
                );
              }).toList(),
            ),

            /*const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Accept Case"),
              onPressed: () async {
                // pass logged-in advocate userId
                await service.acceptCase(caseRequest.id, "ADVOCATE_USER_ID");
                Navigator.pop(context);
              },
            ),*/
          ],
        ),
      ),
    );
  }
}
