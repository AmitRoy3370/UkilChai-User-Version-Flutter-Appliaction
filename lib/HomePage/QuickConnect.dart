import 'dart:convert';
import 'package:advocatechai/ChatRelatedPages/CenterAdminChatListScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Auth/AuthService.dart';
import '../CaseRelatedPages/CaseHomePage.dart';
import '../QuestionPages/AskQuestionPage.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import 'QuickCard.dart';
import '../AdvocatePages/AdvocateFilterPage.dart';

class QuickConnect extends StatelessWidget {
  const QuickConnect({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Title
          const Text(
            "Quick Connect",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Always 2×2 grid — fixed 2 columns
          GridView.count(
            crossAxisCount: 2,                    // ← Fixed to 2 columns forever
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.35,               // nice proportion
            children: [
              // 1. Find Expert
              QuickCard(
                icon: Icons.person_search,
                title: "Find Expert",
                subtitle: "Connect with specialized advocates",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdvocateFilterPage()),
                  );
                },
              ),

              // 2. Free Consult
              QuickCard(
                icon: Icons.chat_bubble_outline,
                title: "Free Consult",
                subtitle: "15-min free consultation",
                onTap: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  String userId = prefs.getString("userId") ?? "";
                  String token = prefs.getString("jwt_token") ?? "";

                  if (userId.isEmpty || token.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please log in first"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final response = await http.get(
                    Uri.parse('${BASE_URL.Urls().baseURL}user/search?userId=$userId'),
                    headers: {
                      'Content-Type': 'application/json',
                      'Accept': 'application/json',
                      'Authorization': 'Bearer $token',
                    },
                  );

                  if (response.statusCode == 200) {
                    final data = jsonDecode(response.body);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CenterAdminChatListScreen(
                          currentUserId: userId,
                          currentUserName: data['name'] ?? "User",
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Failed to fetch user data."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),

              // 3. Ask Question
              QuickCard(
                icon: Icons.help_outline_rounded,
                title: "Ask Question",
                subtitle: "Public Q&A with advocates",
                onTap: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  String userId = prefs.getString("userId") ?? "";

                  if (userId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please log in to ask a question"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AskQuestionPage(userId: userId),
                    ),
                  );
                },
              ),

              // 4. My Cases
              QuickCard(
                icon: Icons.calendar_month,
                title: "My Cases",
                subtitle: "View your case details",
                onTap: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  String userId = prefs.getString("userId") ?? "";

                  if (userId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please log in to view cases"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CaseHomePage()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}