import 'package:advocatechai/PostRelatedPages/post_card_home_page.dart';
import 'package:advocatechai/PostRelatedPages/post_response.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './PostService.dart';
import '../Utils/AdvocateSpeciality.dart';

class PostFeedPageHomePage extends StatefulWidget {
  const PostFeedPageHomePage({super.key});

  @override
  State<PostFeedPageHomePage> createState() => _PostFeedPageHomePageState();
}

class _PostFeedPageHomePageState extends State<PostFeedPageHomePage> {
  bool loading = true;
  bool isLoggedIn = true;
  List<PostResponse> posts = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    if (token.isEmpty) {
      setState(() {
        loading = false;
        isLoggedIn = false;
      });
      return;
    }

    try {
      final data = await PostService.fetchAllPosts(token);
      setState(() {
        posts = data;
        posts = posts.reversed.toList();
        loading = false;
        isLoggedIn = true;
      });
    } catch (e) {
      setState(() {
        loading = false;
        isLoggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!loading && !isLoggedIn) {
      return SizedBox(
        height: 360,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 60,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                "Log in first",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "to watch the posts",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 20),
            
            ],
          ),
        ),
      );
    }

    if (loading) {
      return const SizedBox(
        height: 360,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 360,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return PostCardHomePage(post: posts[index]);
          },
        ),
      ),
    );
  }
}