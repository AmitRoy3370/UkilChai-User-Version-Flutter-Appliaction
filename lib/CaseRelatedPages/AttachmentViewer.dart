import 'dart:typed_data';
import 'dart:io';
import 'package:advocatechai/Utils/BaseURL.dart' as BASE_URL;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

class CaseAttachmentView extends StatefulWidget {
  final String attachmentId;
  final String jwtToken;

  const CaseAttachmentView({
    super.key,
    required this.attachmentId,
    required this.jwtToken,
  });

  @override
  State<CaseAttachmentView> createState() => _CaseAttachmentViewState();
}

class _CaseAttachmentViewState extends State<CaseAttachmentView> {
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
        '${BASE_URL.Urls().baseURL}case/attachment/view/${widget.attachmentId}');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.jwtToken}',
      },
    );

    if (response.statusCode == 200) {
      fileBytes = response.bodyBytes;
      contentType = response.headers['content-type'];

      // Save temp file ONLY if needed (pdf / video / audio)
      if (contentType != null &&
          (contentType!.contains('pdf') ||
              contentType!.startsWith('video/') ||
              contentType!.startsWith('audio/'))) {
        final dir = await getTemporaryDirectory();
        tempFilePath = '${dir.path}/${widget.attachmentId}';
        await File(tempFilePath!).writeAsBytes(fileBytes!);
      }

      // Init video
      if (contentType != null && contentType!.startsWith('video/')) {
        videoController = VideoPlayerController.file(File(tempFilePath!));
        await videoController!.initialize();
      }

      // Init audio
      if (contentType != null && contentType!.startsWith('audio/')) {
        audioPlayer = AudioPlayer();
        await audioPlayer!.play(DeviceFileSource(tempFilePath!));
      }

      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load attachment')),
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
      return PDFView(filePath: tempFilePath!);
    }

    // 📝 TEXT / JSON / CSV
    if (contentType != null &&
        (contentType!.startsWith('text/') ||
            contentType == 'application/json')) {
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
              videoController!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
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

    if(contentType == 'application/msword' ||
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
              onPressed: () async {
                // reuse your download screen OR direct open logic
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
