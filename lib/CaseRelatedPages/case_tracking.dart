import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:advocatechai/CaseRelatedPages/document_draft_service.dart';
import 'package:advocatechai/CaseRelatedPages/_TimelineStep.dart';

import 'AppealHearingModel.dart';
import 'DocumentDraftAttachmentViewer.dart';
import 'HearingAttachmentViewer.dart';
import 'HearingModel.dart';
import 'appeal_hearing_service.dart';
import 'document_draft.dart';
import 'hearing_service.dart';

class CaseTracking extends StatefulWidget {
  final String? caseId;
  final String? caseName;
  final String? caseLawyer;
  final String? issuedTime;
  final String? token;

  const CaseTracking({
    super.key,
    required this.caseId,
    required this.caseName,
    required this.caseLawyer,
    required this.issuedTime,
    required this.token,
  });

  @override
  State<CaseTracking> createState() => _CaseTrackingState();
}

class _CaseTrackingState extends State<CaseTracking> {
  late Future<void> _loadFuture;
  DocumentDraft? documentDrafts;

  List<TimelineStep> timelineSteps = [];
  List<Hearing> hearings = [];

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadAllData();
  }

  Future<void> _loadAllData() async {
    final draftService = DocumentDraftService(widget.token!);

    // ---------- DOCUMENT DRAFT ----------
    documentDrafts = await draftService.findByCase(widget.caseId!);

    print(
      "${documentDrafts?.caseId} ${documentDrafts?.advocateId} ${documentDrafts?.issuedDate} of case tracking page",
    );

    final hasDraft = documentDrafts != null;

    // ---------- HEARINGS ----------
    hearings = await HearingService.getByCase(widget.token!, widget.caseId!);

    timelineSteps = [
      TimelineStep(
        title: "Case Request Accepted",
        subtitle: "Case is now processing",
        date: widget.issuedTime,
        icon: Icons.check_circle,
        color: Colors.green,
        completed: true,
      ),
      TimelineStep(
        title: "Document Drafting",
        subtitle: hasDraft ? "Status: In Progress" : "Status: Pending",
        date: hasDraft ? _formatDate(documentDrafts!.issuedDate) : null,
        icon: Icons.description,
        color: hasDraft ? Colors.orange : Colors.grey,
        completed: hasDraft,
      ),
      TimelineStep(
        title: "Status",
        subtitle: hearings.isNotEmpty ? "In progress" : "Pending",
        date: hearings.isNotEmpty
            ? _formatDate(hearings.first.issuedDate)
            : null,
        icon: Icons.calendar_today,
        color: hearings.isNotEmpty ? Colors.blue : Colors.grey,
        completed: hearings.isNotEmpty,
      ),
      TimelineStep(
        title: "Case Filing / Registration",
        subtitle: hearings.isNotEmpty ? "In progress" : "Pending",
        date: hearings.isNotEmpty
            ? _formatDate(hearings.first.issuedDate)
            : null,
        icon: Icons.calendar_today,
        color: hearings.isNotEmpty ? Colors.blue : Colors.grey,
        completed: hearings.isNotEmpty,
      ),
      TimelineStep(
        title: "Hearing Date Issued",
        subtitle: hearings.isNotEmpty ? "Scheduled" : "Pending",
        date: hearings.isNotEmpty
            ? _formatDate(hearings.first.issuedDate)
            : null,
        icon: Icons.calendar_today,
        color: hearings.isNotEmpty ? Colors.blue : Colors.grey,
        completed: hearings.isNotEmpty,
      ),
      TimelineStep(
        title: "Paper Finalize",
        subtitle: hearings.isNotEmpty ? "Scheduled" : "Pending",
        date: null,
        icon: Icons.emoji_events,
        color: Colors.grey,
        completed: false,
      ),
    ];
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      appBar: AppBar(
        title: const Text("Ukil App"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= LEFT SIDE =================
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _caseSummaryCard(),
                      const SizedBox(height: 16),
                      _timelineCard(),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // ================= RIGHT SIDE (HEARINGS) =================
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      if (documentDrafts != null)
                        _documentDraftTile(documentDrafts!)
                      else
                        Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.description,
                              color: Colors.grey,
                            ),
                            title: Text("Document Draft"),
                            subtitle: Text("Not created yet"),
                          ),
                        ),

                      const SizedBox(height: 16),
                      _hearingCard(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= CASE SUMMARY =================
  Widget _caseSummaryCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Case Summary",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text("Case title :- ${widget.caseName}"),
            const SizedBox(height: 8),
            Text("Lawyer : ${widget.caseLawyer}"),
            const SizedBox(height: 8),
            Text("Issued Time : ${widget.issuedTime}"),
          ],
        ),
      ),
    );
  }

  // ================= TIMELINE =================
  Widget _timelineCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: timelineSteps.map(_timelineTile).toList()),
      ),
    );
  }

  Widget _timelineTile(TimelineStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(step.icon, color: step.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(step.subtitle),
                if (step.date != null)
                  Text(step.date!, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEARING CARD =================
  Widget _hearingCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hearings",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (hearings.isEmpty) const Text("No hearing scheduled"),

            ...hearings.map(_hearingTile),
          ],
        ),
      ),
    );
  }

  Widget _hearingTile(Hearing hearing) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        leading: const Icon(Icons.gavel),
        title: Text("Hearing #${hearing.hearingNumber}"),
        subtitle: Text("Date: ${_formatDate(hearing.issuedDate)}"),
        trailing: hearing.attachmentsId.isNotEmpty
            ? Text(
                "${hearing.attachmentsId.length} files",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
        children: [
          // ---------- ATTACHMENTS ----------
          if (hearing.attachmentsId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: hearing.attachmentsId
                    .map(
                      (attachmentId) => ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(attachmentId),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HearingAttachmentView(
                                attachmentId: attachmentId,
                                jwtToken: widget.token!,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
            ),

          // ---------- APPEAL HEARINGS (FutureBuilder) ----------
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FutureBuilder<List<AppealHearing>>(
              future: AppealHearingService.getByHearing(
                widget.token!,
                hearing.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "Failed to load appeal hearings",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                final appeals = snapshot.data ?? [];

                if (appeals.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "No appeal hearing for this hearing",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        "Appeal Hearings",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...appeals.map(_appealTile).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentDraftTile(DocumentDraft draft) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.orange),
        title: const Text("Document Draft"),
        subtitle: Text("Issued: ${_formatDate(draft.issuedDate)}"),
        trailing: draft.attachmentsId.isEmpty
            ? null
            : Text(
                "${draft.attachmentsId.length} files",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
        onTap: () {
          if (draft.attachmentsId.isNotEmpty) {
            _showDraftAttachmentSheet(draft);
          }
        },
      ),
    );
  }

  void _showDraftAttachmentSheet(DocumentDraft draft) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Document Draft Attachments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ...draft.attachmentsId.map(
                (attachmentId) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(attachmentId),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DocumentDraftAttachmentView(
                            attachmentId: attachmentId,
                            jwtToken: widget.token!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _appealTile(AppealHearing appeal) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Card(
        color: Colors.grey.shade100,
        child: ListTile(
          leading: const Icon(Icons.history, color: Colors.deepOrange),
          title: Text(appeal.reason),
          subtitle: appeal.appealHearingTime != null
              ? Text("Appeal Date: ${_formatDate(appeal.appealHearingTime!)}")
              : const Text("Appeal date not scheduled"),
        ),
      ),
    );
  }
}
