import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // Mobile PDF
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File;

import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; // Web & Mobile PDF
import '../Utils/BaseURL.dart' as BASE_URL;

class CaseRequestAttachmentViewer extends StatefulWidget {
  final String attachmentId;
  final String jwtToken;

  const CaseRequestAttachmentViewer({
    super.key,
    required this.attachmentId,
    required this.jwtToken,
  });

  @override
  State<CaseRequestAttachmentViewer> createState() => _CaseRequestAttachmentViewState();
}

class _CaseRequestAttachmentViewState extends State<CaseRequestAttachmentViewer> {
  Uint8List? fileBytes;
  String? contentType;
  String? tempFilePath;

  VideoPlayerController? videoController;
  AudioPlayer? audioPlayer;

  @override
  void initState() {
    super.initState();
    loadAttachment();
  }

  @override
  void dispose() {
    videoController?.dispose();
    audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> loadAttachment() async {
    final url = Uri.parse(
        '${BASE_URL.Urls().baseURL}case-request/attachment/view/${widget.attachmentId}');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.jwtToken}',
      },
    );

    if (response.statusCode == 200) {
      fileBytes = response.bodyBytes;
      contentType = response.headers['content-type'];

      // Save temp file ONLY for Mobile (pdf / video / audio)
      if (!kIsWeb &&
          contentType != null &&
          (contentType!.contains('pdf') ||
              contentType!.startsWith('video/') ||
              contentType!.startsWith('audio/'))) {
        final dir = await getTemporaryDirectory();
        tempFilePath =
        '${dir.path}/${widget.attachmentId.replaceAll(RegExp(r"[^\w\-_\.]"), "_")}';
        await File(tempFilePath!).writeAsBytes(fileBytes!);
      }

      // Init video
      if (contentType != null && contentType!.startsWith('video/')) {
        if (kIsWeb) {
          videoController = VideoPlayerController.network(
            'data:$contentType;base64,${base64Encode(fileBytes!)}',
          );
        } else {
          videoController = VideoPlayerController.file(File(tempFilePath!));
        }
        await videoController!.initialize();
      }

      // Init audio
      if (contentType != null && contentType!.startsWith('audio/')) {
        audioPlayer = AudioPlayer();
        if (kIsWeb) {
          await audioPlayer!.setSourceBytes(fileBytes!);
        } else {
          await audioPlayer!.play(DeviceFileSource(tempFilePath!));
        }
      }

      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load attachment')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (fileBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 🖼 IMAGE
    if (contentType != null && contentType!.startsWith('image/')) {
      return InteractiveViewer(
        child: Image.memory(fileBytes!),
      );
    }

    // 📄 PDF
    if (contentType == 'application/pdf') {
      if (kIsWeb) {
        return SfPdfViewer.memory(fileBytes!);
      } else {
        return PDFView(filePath: tempFilePath!);
      }
    }

    // 📝 TEXT / JSON / CSV
    if (contentType != null &&
        (contentType!.startsWith('text/') || contentType == 'application/json')) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          String.fromCharCodes(fileBytes!),
          style: const TextStyle(fontSize: 14),
        ),
      );
    }

    // 🎥 VIDEO
    if (contentType != null && contentType!.startsWith('video/')) {
      if (!videoController!.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }
      return Column(
        children: [
          AspectRatio(
            aspectRatio: videoController!.value.aspectRatio,
            child: VideoPlayer(videoController!),
          ),
          VideoProgressIndicator(videoController!, allowScrubbing: true),
          IconButton(
            icon: Icon(
              videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: () {
              setState(() {
                videoController!.value.isPlaying
                    ? videoController!.pause()
                    : videoController!.play();
              });
            },
          ),
        ],
      );
    }

    // 🔊 AUDIO
    if (contentType != null && contentType!.startsWith('audio/')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.audiotrack, size: 80),
            SizedBox(height: 12),
            Text('Playing audio...'),
          ],
        ),
      );
    }

    // WORD DOCUMENT
    if (contentType == 'application/msword' ||
        contentType ==
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, size: 80),
            const SizedBox(height: 12),
            const Text(
              'Word document preview is not supported inside the app.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open with Word / Office'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please download to open this document'),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // ❌ OTHER FILE TYPES
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.insert_drive_file, size: 80),
          SizedBox(height: 12),
          Text(
            'Preview not supported for this file type.\nPlease download to open.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
