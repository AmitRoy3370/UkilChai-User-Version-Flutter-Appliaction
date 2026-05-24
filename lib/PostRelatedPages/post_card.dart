import 'dart:convert';
import 'dart:math';
import 'package:advocatechai/PostRelatedPages/post_response.dart';
import 'package:advocatechai/Utils/AdvocateSpeciality.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import './AdvocatePost.dart';
import 'PostAttachmentViewer.dart';
import 'reaction_bar.dart';
import '../PageTransition.dart';  // ✅ Add this import

class PostCard extends StatefulWidget {
  final PostResponse post;
  final bool? canReact;
  final Function? onReactionChanged;

  const PostCard({
    super.key,
    required this.post,
    this.canReact,
    this.onReactionChanged,
  });

  @override
  State<StatefulWidget> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  // Smooth animations only
  final List<PageTransitionType> _smoothAnimations = AnimatedRoute.getCompanySafeAnimations();

  PageTransitionType _getRandomAnimation() {
    final random = Random().nextInt(_smoothAnimations.length);
    return _smoothAnimations[random];
  }

  // Check if attachment exists
  bool get hasAttachment {
    return widget.post.attachmentId != null &&
        widget.post.attachmentId!.isNotEmpty &&
        widget.post.attachmentId != "null" &&
        widget.post.attachmentId != "attachmentId";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.purple.shade400, Colors.blue.shade400],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.post.advocateName.isNotEmpty
                              ? widget.post.advocateName[0].toUpperCase()
                              : "A",
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.advocateName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.purple.shade400, Colors.blue.shade400],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.post.postType.label,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Post Content
                Text(
                  widget.post.postContent,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Attachment Button - Only shows if attachment exists
                if (hasAttachment)
                  InkWell(
                    onTap: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('jwt_token') ?? '';

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostAttachmentView(
                            attachmentId: widget.post.attachmentId!,
                            jwtToken: token,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attach_file, size: 16, color: Colors.purple),
                          const SizedBox(width: 6),
                          Text(
                            "View Attachment",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.open_in_new, size: 14, color: Colors.purple),
                        ],
                      ),
                    ),
                  ),

                const Divider(color: Colors.grey, height: 24),

                // Reaction Bar
                ReactionBar(
                  postResponse: widget.post,
                  onReactionChanged: (reaction, action) {
                    setState(() {
                      widget.onReactionChanged?.call(reaction, action);
                    });
                  },
                  canReact: widget.canReact ?? true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}