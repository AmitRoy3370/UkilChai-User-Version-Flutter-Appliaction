// lib/Case/screens/case_judgment_attachment_view.dart
// (আপনার path অনুযায়ী adjust করুন)

import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File;

// WEB ONLY
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import '../Auth/AuthService.dart';
import '../Utils/BaseURL.dart' as BASE_URL;

class CaseJudgmentAttachmentView extends StatefulWidget {
  final String attachmentId;
  final String jwtToken;

  const CaseJudgmentAttachmentView({
    super.key,
    required this.attachmentId,
    required this.jwtToken,
  });

  @override
  State<CaseJudgmentAttachmentView> createState() =>
      _CaseJudgmentAttachmentViewState();
}

class _CaseJudgmentAttachmentViewState
    extends State<CaseJudgmentAttachmentView> {
  Uint8List? fileBytes;
  String? contentType;
  String? tempFilePath;
  String? webUrl;

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
    if (kIsWeb && webUrl != null) {
      html.Url.revokeObjectUrl(webUrl!);
    }
    super.dispose();
  }

  // ============================================================
  // FILE EXTENSION FROM MIME
  // ============================================================
  String getFileExtension(String? mime) {
    if (mime == null) return '';

    // Documents
    if (mime.contains('pdf')) return '.pdf';
    if (mime == 'application/msword') return '.doc';
    if (mime ==
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
      return '.docx';
    }
    if (mime == 'application/vnd.ms-excel') return '.xls';
    if (mime ==
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
      return '.xlsx';
    }
    if (mime == 'application/vnd.ms-powerpoint') return '.ppt';
    if (mime ==
        'application/vnd.openxmlformats-officedocument.presentationml.presentation') {
      return '.pptx';
    }
    if (mime == 'text/plain') return '.txt';
    if (mime == 'text/csv') return '.csv';
    if (mime.contains('json')) return '.json';
    if (mime.contains('xml')) return '.xml';

    // Images
    if (mime.startsWith('image/jpeg')) return '.jpg';
    if (mime.startsWith('image/png')) return '.png';
    if (mime.startsWith('image/gif')) return '.gif';
    if (mime.startsWith('image/webp')) return '.webp';
    if (mime.startsWith('image/bmp')) return '.bmp';
    if (mime.startsWith('image/heic')) return '.heic';
    if (mime.startsWith('image/heif')) return '.heif';
    if (mime.startsWith('image/svg')) return '.svg';
    if (mime.startsWith('image/tiff')) return '.tiff';

    // Video
    if (mime.startsWith('video/mp4')) return '.mp4';
    if (mime.startsWith('video/quicktime')) return '.mov';
    if (mime.startsWith('video/x-msvideo')) return '.avi';
    if (mime.startsWith('video/webm')) return '.webm';
    if (mime.startsWith('video/x-matroska')) return '.mkv';
    if (mime.startsWith('video/3gpp')) return '.3gp';

    // Audio
    if (mime.startsWith('audio/mpeg')) return '.mp3';
    if (mime.startsWith('audio/wav') || mime.startsWith('audio/x-wav')) {
      return '.wav';
    }
    if (mime.startsWith('audio/ogg')) return '.ogg';
    if (mime.startsWith('audio/aac')) return '.aac';
    if (mime.startsWith('audio/m4a') || mime.startsWith('audio/x-m4a')) {
      return '.m4a';
    }
    if (mime.startsWith('audio/flac')) return '.flac';
    if (mime.startsWith('audio/webm')) return '.weba';

    return '';
  }

  // ============================================================
  // MAGIC BYTE DETECTION
  // ============================================================
  String? detectContentType(Uint8List bytes) {
    if (bytes.length < 12) return null;

    debugPrint('🔍 Detecting content-type from magic bytes...');
    debugPrint(
        '   First 16 bytes: ${bytes.take(16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

    // ═══════════════════════════════════════════════════════
    // IMAGES
    // ═══════════════════════════════════════════════════════

    // ✅ PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      debugPrint('   ✅ Detected: PNG');
      return 'image/png';
    }

    // ✅ JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      debugPrint('   ✅ Detected: JPEG');
      return 'image/jpeg';
    }

    // ✅ GIF: 47 49 46 38 (GIF8)
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      debugPrint('   ✅ Detected: GIF');
      return 'image/gif';
    }

    // ✅ WEBP: RIFF....WEBP
    if (String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      debugPrint('   ✅ Detected: WEBP');
      return 'image/webp';
    }

    // ✅ BMP: 42 4D (BM)
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      debugPrint('   ✅ Detected: BMP');
      return 'image/bmp';
    }

    // ✅ HEIC/HEIF (iPhone): ....ftypheic etc.
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
      final brand = String.fromCharCodes(bytes.sublist(8, 12));
      debugPrint('   Brand: $brand');
      if (brand == 'heic' ||
          brand == 'heix' ||
          brand == 'mif1' ||
          brand == 'msf1' ||
          brand == 'heim' ||
          brand == 'heis') {
        debugPrint('   ✅ Detected: HEIC/HEIF');
        return 'image/heic';
      }
      if (brand == 'avif') {
        debugPrint('   ✅ Detected: AVIF');
        return 'image/avif';
      }
      // Fallback: any ISO-BMFF brand = likely HEIC on mobile
      debugPrint('   ✅ Detected: HEIC (ISO-BMFF)');
      return 'image/heic';
    }

    // ✅ TIFF
    if (bytes[0] == 0x49 && bytes[1] == 0x49 && bytes[2] == 0x2A) {
      debugPrint('   ✅ Detected: TIFF');
      return 'image/tiff';
    }
    if (bytes[0] == 0x4D && bytes[1] == 0x4D && bytes[2] == 0x00) {
      debugPrint('   ✅ Detected: TIFF');
      return 'image/tiff';
    }

    // ═══════════════════════════════════════════════════════
    // DOCUMENTS
    // ═══════════════════════════════════════════════════════

    // ✅ PDF: %PDF
    if (bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      debugPrint('   ✅ Detected: PDF');
      return 'application/pdf';
    }

    // ✅ DOCX/XLSX/PPTX (ZIP-based): PK
    if (bytes[0] == 0x50 && bytes[1] == 0x4B) {
      debugPrint('   ✅ Detected: ZIP (likely docx/xlsx/pptx)');
      return 'application/zip';
    }

    // ✅ OLE (old MS Office): D0 CF 11 E0
    if (bytes[0] == 0xD0 &&
        bytes[1] == 0xCF &&
        bytes[2] == 0x11 &&
        bytes[3] == 0xE0) {
      debugPrint('   ✅ Detected: OLE (doc/xls/ppt)');
      return 'application/msword';
    }

    // ═══════════════════════════════════════════════════════
    // VIDEO
    // ═══════════════════════════════════════════════════════

    // ✅ MP4 / MOV / 3GP (ISO-BMFF): ....ftyp
    if (String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
      final brand = bytes.length >= 12
          ? String.fromCharCodes(bytes.sublist(8, 12))
          : '';
      debugPrint('   Video brand: $brand');
      if (brand == 'qt  ') {
        debugPrint('   ✅ Detected: MOV');
        return 'video/quicktime';
      }
      if (brand == '3gp4' || brand == '3gp5' || brand == '3g2a') {
        debugPrint('   ✅ Detected: 3GP');
        return 'video/3gpp';
      }
      debugPrint('   ✅ Detected: MP4');
      return 'video/mp4';
    }

    // ✅ AVI: RIFF....AVI 
    if (String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'AVI ') {
      debugPrint('   ✅ Detected: AVI');
      return 'video/x-msvideo';
    }

    // ✅ WEBM/MKV: 1A 45 DF A3
    if (bytes[0] == 0x1A &&
        bytes[1] == 0x45 &&
        bytes[2] == 0xDF &&
        bytes[3] == 0xA3) {
      final searchLen = bytes.length > 100 ? 100 : bytes.length;
      final head = String.fromCharCodes(bytes.sublist(0, searchLen));
      if (head.contains('webm')) {
        debugPrint('   ✅ Detected: WEBM');
        return 'video/webm';
      }
      debugPrint('   ✅ Detected: MKV');
      return 'video/x-matroska';
    }

    // ═══════════════════════════════════════════════════════
    // AUDIO
    // ═══════════════════════════════════════════════════════

    // ✅ WAV: RIFF....WAVE
    if (String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WAVE') {
      debugPrint('   ✅ Detected: WAV');
      return 'audio/wav';
    }

    // ✅ MP3 with ID3
    if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
      debugPrint('   ✅ Detected: MP3 (ID3)');
      return 'audio/mpeg';
    }

    // ✅ MP3 without ID3: FF Ex
    if (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) {
      debugPrint('   ✅ Detected: MP3');
      return 'audio/mpeg';
    }

    // ✅ OGG: OggS
    if (String.fromCharCodes(bytes.sublist(0, 4)) == 'OggS') {
      debugPrint('   ✅ Detected: OGG');
      return 'audio/ogg';
    }

    // ✅ FLAC: fLaC
    if (bytes[0] == 0x66 &&
        bytes[1] == 0x4C &&
        bytes[2] == 0x61 &&
        bytes[3] == 0x43) {
      debugPrint('   ✅ Detected: FLAC');
      return 'audio/flac';
    }

    // ✅ M4A
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp' &&
        String.fromCharCodes(bytes.sublist(8, 11)) == 'M4A') {
      debugPrint('   ✅ Detected: M4A');
      return 'audio/mp4';
    }

    // ✅ AAC
    if (bytes[0] == 0xFF && (bytes[1] == 0xF1 || bytes[1] == 0xF9)) {
      debugPrint('   ✅ Detected: AAC');
      return 'audio/aac';
    }

    debugPrint('   ❌ Could not detect');
    return null;
  }

  // ============================================================
  // LOAD ATTACHMENT
  // ============================================================
  Future<void> loadAttachment() async {
    final url = Uri.parse(
      '${BASE_URL.Urls().baseURL}case-judgment/attachment/view/${widget.attachmentId}',
    );

    debugPrint('═══════════════════════════════════════════');
    debugPrint('📥 CASE JUDGMENT ATTACHMENT LOAD');
    debugPrint('   ID: ${widget.attachmentId}');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.jwtToken}'},
      );

      debugPrint('   Status: ${response.statusCode}');
      debugPrint('   Header Content-Type: ${response.headers['content-type']}');
      debugPrint('   Body bytes: ${response.bodyBytes.length}');

      if (response.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load attachment')),
          );
        }
        return;
      }

      fileBytes = response.bodyBytes;
      contentType = response.headers['content-type'];
      debugPrint('   contentType from header: $contentType');

      // Fallback detection
      if (contentType == null ||
          contentType == 'application/octet-stream' ||
          contentType == 'application/x-www-form-urlencoded' ||
          contentType == 'binary/octet-stream') {
        debugPrint('   ⚠️ Generic/wrong content-type, detecting from bytes...');
        final detected = detectContentType(fileBytes!);
        if (detected != null) {
          contentType = detected;
          debugPrint('   ✅ Updated contentType: $contentType');
        } else {
          debugPrint('   ❌ Detection failed');
        }
      } else {
        debugPrint('   ✅ Header content-type OK: $contentType');
      }

      debugPrint('   FINAL contentType: $contentType');
      debugPrint('   isImage: ${contentType?.startsWith('image/')}');
      debugPrint('   isVideo: ${contentType?.startsWith('video/')}');
      debugPrint('   isAudio: ${contentType?.startsWith('audio/')}');
      debugPrint('═══════════════════════════════════════════');

      // ═══════════════════════════════════════════════════════
      // WEB: Create blob URL
      // ═══════════════════════════════════════════════════════
      if (kIsWeb) {
        final blob = html.Blob(
          [fileBytes!],
          contentType ?? 'application/octet-stream',
        );
        webUrl = html.Url.createObjectUrlFromBlob(blob);
      }

      // ═══════════════════════════════════════════════════════
      // MOBILE: Save temp file for supported types
      // ═══════════════════════════════════════════════════════
      final needsTempFile = !kIsWeb &&
          contentType != null &&
          (contentType!.contains('pdf') ||
              contentType!.startsWith('video/') ||
              contentType!.startsWith('audio/') ||
              contentType!.contains('word') ||
              contentType!.contains('excel') ||
              contentType!.contains('powerpoint') ||
              contentType!.contains('office') ||
              contentType!.contains('zip') ||
              contentType!.contains('ms'));

      if (needsTempFile) {
        try {
          final dir = await getTemporaryDirectory();
          final fileName =
              '${widget.attachmentId}${getFileExtension(contentType)}';
          tempFilePath = '${dir.path}/$fileName';
          await File(tempFilePath!).writeAsBytes(fileBytes!);
          debugPrint('   📁 Temp file saved: $tempFilePath');
        } catch (e) {
          debugPrint('   ❌ Temp file save failed: $e');
        }
      }

      // ═══════════════════════════════════════════════════════
      // WEB PDF iframe — ✅ Unique viewType for Case Judgment
      // ═══════════════════════════════════════════════════════
      if (kIsWeb && contentType != null && contentType!.contains('pdf')) {
        ui_web.platformViewRegistry.registerViewFactory(
          'case-judgment-pdf-${widget.attachmentId}',
          (int viewId) => html.IFrameElement()
            ..src = webUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%',
        );
      }

      // ═══════════════════════════════════════════════════════
      // VIDEO
      // ═══════════════════════════════════════════════════════
      if (contentType != null && contentType!.startsWith('video/')) {
        try {
          videoController = kIsWeb
              ? VideoPlayerController.networkUrl(Uri.parse(webUrl!))
              : VideoPlayerController.file(File(tempFilePath!));
          await videoController!.initialize();
          debugPrint('   ✅ Video controller initialized');
        } catch (e) {
          debugPrint('   ❌ Video controller failed: $e');
        }
      }

      // ═══════════════════════════════════════════════════════
      // AUDIO
      // ═══════════════════════════════════════════════════════
      if (contentType != null && contentType!.startsWith('audio/')) {
        try {
          audioPlayer = AudioPlayer();
          if (kIsWeb) {
            await audioPlayer!.play(UrlSource(webUrl!));
          } else {
            await audioPlayer!.play(DeviceFileSource(tempFilePath!));
          }
          debugPrint('   ✅ Audio player started');
        } catch (e) {
          debugPrint('   ❌ Audio player failed: $e');
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Load error: $e');
    }
  }

  // ============================================================
  // DOWNLOAD HELPER
  // ============================================================
  String _getExtensionFromContentType(String? contentType) {
    if (contentType == null) return ".bin";
    if (contentType.contains("pdf")) return ".pdf";
    if (contentType.contains("jpeg")) return ".jpeg";
    if (contentType.contains("jpg")) return ".jpg";
    if (contentType.contains("png")) return ".png";
    if (contentType.contains("gif")) return ".gif";
    if (contentType.contains("webp")) return ".webp";
    if (contentType.contains("heic")) return ".heic";
    if (contentType.contains("mp4")) return ".mp4";
    if (contentType.contains("quicktime")) return ".mov";
    if (contentType.contains("mp3")) return ".mp3";
    if (contentType.contains("wav")) return ".wav";
    if (contentType.contains("word")) return ".docx";
    if (contentType.contains("excel")) return ".xlsx";
    if (contentType.contains("powerpoint")) return ".pptx";
    if (contentType.contains("text")) return ".txt";
    return ".bin";
  }

  Future<void> _openOrDownload() async {
    try {
      // ✅ Case Judgment download URL
      final url =
          "${BASE_URL.Urls().baseURL}case-judgment/attachment/${widget.attachmentId}";

      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Download failed")),
        );
        return;
      }

      String fileName = "attachment";
      final disposition = response.headers['content-disposition'];
      if (disposition != null) {
        final match = RegExp(r'filename="([^"]+)"').firstMatch(disposition);
        if (match != null) {
          fileName = match.group(1)!;
        }
      }

      final ct = response.headers['content-type'] ?? "application/octet-stream";

      if (!fileName.contains(".")) {
        fileName += _getExtensionFromContentType(ct);
      }

      // WEB
      if (kIsWeb) {
        final blob = html.Blob([response.bodyBytes], ct);
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: blobUrl)
          ..setAttribute("download", fileName)
          ..click();

        html.Url.revokeObjectUrl(blobUrl);
        return;
      }

      // MOBILE
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/$fileName";

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      await OpenFilex.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Attachment error: $e")),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    if (fileBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // IMAGE
    if (contentType != null && contentType!.startsWith('image/')) {
      if (kIsWeb &&
          (contentType!.contains('heic') ||
              contentType!.contains('heif'))) {
        return _heicFallback();
      }

      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        child: Center(
          child: Image.memory(
            fileBytes!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Image render error: $error');
              return _imageErrorFallback();
            },
          ),
        ),
      );
    }

    // PDF
    if (contentType != null && contentType!.contains('pdf')) {
      if (kIsWeb) {
        return HtmlElementView(
            viewType: 'case-judgment-pdf-${widget.attachmentId}');
      } else {
        return PDFView(
          filePath: tempFilePath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
        );
      }
    }

    // TEXT / JSON / CSV / XML
    if (contentType != null &&
        (contentType!.startsWith('text/') ||
            contentType!.contains('json') ||
            contentType!.contains('xml'))) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          String.fromCharCodes(fileBytes!),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
      );
    }

    // VIDEO
    if (contentType != null && contentType!.startsWith('video/')) {
      if (videoController == null || !videoController!.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: videoController!.value.aspectRatio,
              child: VideoPlayer(videoController!),
            ),
            VideoProgressIndicator(videoController!, allowScrubbing: true),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 40,
                  icon: Icon(
                    videoController!.value.isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                  ),
                  onPressed: () {
                    setState(() {
                      videoController!.value.isPlaying
                          ? videoController!.pause()
                          : videoController!.play();
                    });
                  },
                ),
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.replay),
                  onPressed: () {
                    videoController!.seekTo(Duration.zero);
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    // AUDIO
    if (contentType != null && contentType!.startsWith('audio/')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A237E).withOpacity(0.1),
              ),
              child: const Icon(Icons.audiotrack,
                  size: 60, color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 16),
            Text(
              'Audio: ${contentType!.split('/').last.toUpperCase()}',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('Playing audio...',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // FALLBACK
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _iconForContentType(contentType),
              size: 80,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 12),
            Text(
              _labelForContentType(contentType),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Preview not supported.\nTap below to open or download.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Open / Download'),
              onPressed: _openOrDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FALLBACK WIDGETS
  // ============================================================

  Widget _heicFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_iphone,
                size: 80, color: Color(0xFF1A237E)),
            const SizedBox(height: 16),
            const Text(
              'iPhone Photo (HEIC)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'HEIC format cannot be previewed in browser.\nPlease download to view.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download HEIC'),
              onPressed: _openOrDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageErrorFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image,
                size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Unable to preview this image',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Format: ${contentType ?? "unknown"}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download File'),
              onPressed: _openOrDownload,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForContentType(String? ct) {
    if (ct == null) return Icons.insert_drive_file;
    if (ct.contains('word')) return Icons.description;
    if (ct.contains('excel') || ct.contains('spreadsheet')) {
      return Icons.table_chart;
    }
    if (ct.contains('powerpoint') || ct.contains('presentation')) {
      return Icons.slideshow;
    }
    if (ct.contains('zip') || ct.contains('rar')) return Icons.archive;
    if (ct.contains('json')) return Icons.data_object;
    if (ct.contains('xml')) return Icons.code;
    return Icons.insert_drive_file;
  }

  String _labelForContentType(String? ct) {
    if (ct == null) return 'Unknown File';
    if (ct.contains('word')) return 'Word Document';
    if (ct.contains('excel') || ct.contains('spreadsheet')) {
      return 'Excel Spreadsheet';
    }
    if (ct.contains('powerpoint') || ct.contains('presentation')) {
      return 'PowerPoint Presentation';
    }
    if (ct.contains('zip')) return 'ZIP Archive';
    return 'Document';
  }
}