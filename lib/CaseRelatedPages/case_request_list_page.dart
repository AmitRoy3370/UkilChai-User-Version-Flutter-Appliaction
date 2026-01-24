import 'package:advocatechai/Auth/AuthService.dart';
import 'package:flutter/material.dart';
import './case_request.dart';
import './case_request_service.dart';
import './case_request_details_page.dart';
import '../Utils/AdvocateSpeciality.dart';

class CaseRequestListPage extends StatefulWidget {
  const CaseRequestListPage({super.key});

  @override
  State<CaseRequestListPage> createState() => _CaseRequestListPageState();
}

class _CaseRequestListPageState extends State<CaseRequestListPage> {
  final service = CaseRequestService();
  List<CaseRequest> list = [];
  bool loading = true;
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() => loading = true);
    list = await service.getAll();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Case Requests")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(
                labelText: "Search case",
                suffixIcon: Icon(Icons.search),
              ),
              onSubmitted: (v) async {
                setState(() => loading = true);
                list = await service.searchByName(v);
                setState(() => loading = false);
              },
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final c = list[i];
                return Card(
                  child: ListTile(
                    title: Text(c.caseName),
                    subtitle: Text(c.caseType.label),
                    trailing: Text(
                      c.requestDate.toLocal().toString().split(" ").first,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CaseRequestDetailsPage(caseRequest: c),
                        ),
                      );
                    },
                  ),

                );
              },
            ),
          )
        ],
      ),
    );
  }
}
