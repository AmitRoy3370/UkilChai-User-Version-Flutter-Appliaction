// ========== attachment_widget.dart ==========
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/BaseURL.dart' as BASE_URL;

class AttachmentWidget extends StatefulWidget {
  final String attachmentId;
  final double height;
  final Function(String) onViewAttachment;

  const AttachmentWidget({
    super.key,
    required this.attachmentId,
    this.height = 150,
    required this.onViewAttachment,
  });

  @override
  State<AttachmentWidget> createState() => _AttachmentWidgetState();
}

class _AttachmentWidgetState extends State<AttachmentWidget> {
  // ========== গ্লোবাল ক্যাশ ==========
  static final Map<String, _AttachmentCache> _cache = {};

  bool _isLoading = false;
  bool _isLoaded = false;
  Uint8List? _fileBytes;
  String? _contentType;
  bool _isImageOrVideo = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // ক্যাশ চেক করুন
    final cached = _cache[widget.attachmentId];
    if (cached != null) {
      setState(() {
        _fileBytes = cached.fileBytes;
        _contentType = cached.contentType;
        _isImageOrVideo = cached.isImageOrVideo;
        _isLoaded = true;
        _isLoading = false;
      });
      return;
    }

    // ক্যাশে না থাকলে লোড করুন
    await _loadAttachment();
  }

  Future<void> _loadAttachment() async {
    if (_isLoading || _isLoaded) return;

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      if (token.isEmpty) {
        setState(() {
          _isLoading = false;
          _isLoaded = true;
        });
        return;
      }

      final url = Uri.parse(
        '${BASE_URL.Urls().baseURL}advocate/posts/attachment/view/${widget.attachmentId}',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fileBytes = response.bodyBytes;
        _contentType = response.headers['content-type'];

        // কন্টেন্ট টাইপ ডিটেক্ট
        if (_contentType == null ||
            _contentType == 'application/octet-stream' ||
            _contentType == 'application/x-www-form-urlencoded') {
          final detected = _detectContentType(_fileBytes!);
          if (detected != null) {
            _contentType = detected;
          }
        }

        _isImageOrVideo = _contentType != null &&
            (_contentType!.startsWith('image/') ||
                _contentType!.startsWith('video/'));

        // ক্যাশে সেভ করুন
        _cache[widget.attachmentId] = _AttachmentCache(
          fileBytes: _fileBytes!,
          contentType: _contentType!,
          isImageOrVideo: _isImageOrVideo,
        );

        setState(() {
          _isLoaded = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoaded = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Failed to load attachment: $e');
      setState(() {
        _isLoaded = true;
        _isLoading = false;
      });
    }
  }

  // ========== কন্টেন্ট টাইপ ডিটেক্ট ==========
  String? _detectContentType(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      return 'application/pdf';
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'image/jpeg';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
      return 'video/mp4';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0x49 &&
        bytes[1] == 0x44 &&
        bytes[2] == 0x33) {
      return 'audio/mpeg';
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) {
      return 'audio/mpeg';
    }
    if (bytes.length >= 4 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF') {
      return 'audio/wav';
    }
    if (bytes.length >= 4 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'OggS') {
      return 'audio/ogg';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'image/gif';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // ========== লোডিং ==========
    if (_isLoading) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ========== লোড হয়ে গেছে এবং ইমেজ/ভিডিও ==========
    if (_isLoaded && _isImageOrVideo && _fileBytes != null) {
      // ইমেজ
      if (_contentType != null && _contentType!.startsWith('image/')) {
        return _buildImageWidget();
      }
      // ভিডিও
      if (_contentType != null && _contentType!.startsWith('video/')) {
        return _buildVideoWidget();
      }
    }

    // ========== লোড হয়ে গেছে কিন্তু ইমেজ/ভিডিও নয় ==========
    if (_isLoaded && !_isImageOrVideo) {
      return _buildOtherAttachmentButton();
    }

    // ========== ডিফল্ট - View Attachment বাটন ==========
    return _buildViewAttachmentButton();
  }

  // ========== View Attachment বাটন ==========
  Widget _buildViewAttachmentButton() {
    return SizedBox(
      height: widget.height,
      child: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            widget.onViewAttachment(widget.attachmentId);
          },
          icon: const Icon(Icons.attach_file, size: 18),
          label: const Text('View Attachment'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.grey.shade700,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ),
    );
  }

  // ========== 🔥 ইমেজ উইজেট (পুরো ইমেজ দেখাবে) ==========
  Widget _buildImageWidget() {
    return GestureDetector(
      onTap: () {
        widget.onViewAttachment(widget.attachmentId);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: widget.height,
          width: double.infinity,
          color: Colors.grey.shade100,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            child: Image.memory(
              _fileBytes!,
              width: double.infinity,
              height: widget.height,
              fit: BoxFit.contain, // 🔥 cover থেকে contain করা হয়েছে
            ),
          ),
        ),
      ),
    );
  }

  // ========== 🔥 ভিডিও উইজেট (পুরো ভিডিও দেখাবে) ==========
  Widget _buildVideoWidget() {
    return GestureDetector(
      onTap: () {
        widget.onViewAttachment(widget.attachmentId);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: widget.height,
          width: double.infinity,
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ভিডিও থাম্বনেইল - পুরো দেখাবে
              Image.memory(
                _fileBytes!,
                width: double.infinity,
                height: widget.height,
                fit: BoxFit.contain, // 🔥 cover থেকে contain করা হয়েছে
              ),
              // ওভারলে
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              // প্লে বাটন
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.play_circle_filled,
                    color: Colors.black,
                    size: 40,
                  ),
                ),
              ),
              // ভিউ বাটন
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Play',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== অন্যান্য অ্যাটাচমেন্ট বাটন ==========
  Widget _buildOtherAttachmentButton() {
    IconData icon;
    String label;
    Color color;

    if (_contentType != null) {
      if (_contentType!.contains('pdf')) {
        icon = Icons.picture_as_pdf;
        label = 'View PDF';
        color = Colors.red.shade400;
      } else if (_contentType!.startsWith('audio/')) {
        icon = Icons.audiotrack;
        label = 'Play Audio';
        color = Colors.green.shade400;
      } else if (_contentType!.contains('word') ||
          _contentType!.contains('document')) {
        icon = Icons.description;
        label = 'View Document';
        color = Colors.blue.shade400;
      } else if (_contentType!.contains('text') ||
          _contentType!.contains('json')) {
        icon = Icons.text_snippet;
        label = 'View Text';
        color = Colors.purple.shade400;
      } else {
        icon = Icons.attach_file;
        label = 'View Attachment';
        color = Colors.grey.shade600;
      }
    } else {
      icon = Icons.attach_file;
      label = 'View Attachment';
      color = Colors.grey.shade600;
    }

    return SizedBox(
      height: widget.height,
      child: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            widget.onViewAttachment(widget.attachmentId);
          },
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            backgroundColor: color.withOpacity(0.1),
            foregroundColor: color,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ),
    );
  }
}

// ========== ক্যাশ ক্লাস ==========
class _AttachmentCache {
  final Uint8List fileBytes;
  final String contentType;
  final bool isImageOrVideo;

  _AttachmentCache({
    required this.fileBytes,
    required this.contentType,
    required this.isImageOrVideo,
  });
}