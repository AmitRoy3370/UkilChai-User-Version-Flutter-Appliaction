import 'dart:convert';
import 'package:advocatechai/AdvocatePages/AdvocateFilterPage.dart';
import 'package:advocatechai/PostRelatedPages/post_feed_page.dart';
import 'package:advocatechai/ProfilePage/ProfileAvatar.dart';
import 'package:advocatechai/ProfilePage/ProfileImageWidget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';  // ✅ Provider যোগ করুন

import 'ChatRelatedPages/AllUserChatListScreen.dart';
import 'ChatRelatedPages/user_active_service.dart';
import 'HomePage.dart';
import 'LifeCycles/LifecycleManager.dart';
import 'LogInPage/LogIn.dart';
import 'NotificationPages/notification_page.dart';
import 'NotificationPages/notification_service.dart';  // ✅ নতুন সার্ভিস
import 'PostRelatedPages/post_feed_page_home_page.dart';
import 'ProfilePage/ProfileMenuPage.dart';
import 'Utils/BaseURL.dart' as BASE_URL;

void main() {
  runApp(
    // ✅ NotificationService যোগ করুন
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: LifecycleManager(child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'উকিল',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'উকিল চাই'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

int index = 0;

Future<String?> getMyId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? myId = prefs.getString('userId');
  return myId;
}

Future<String?> getMyName() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? myId = prefs.getString('userId');
  String? token = prefs.getString('jwt_token');

  final response = await http.get(
    Uri.parse("${BASE_URL.Urls().baseURL}user/$myId"),
    headers: {
      'content-type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['name'];
  } else {
    return "";
  }
}

class _MyHomePageState extends State<MyHomePage> {
  late List<Widget> bottomPages = [];
  bool isLoading = true;

  // ✅ NotificationService থেকে unreadCount নেওয়া হবে
  String? myId, myName;
  bool _showWelcome = false;

  void _onWelcomeContinue() {
    setState(() {
      _showWelcome = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeNotification();  // ✅ নোটিফিকেশন ইনিশিয়ালাইজ
    loadAllUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ✅ নোটিফিকেশন ইনিশিয়ালাইজ করার নতুন মেথড
  Future<void> _initializeNotification() async {
    final prefs = await SharedPreferences.getInstance();
    myId = prefs.getString('userId');

    if (myId != null && myId!.isNotEmpty) {
      // NotificationService পাওয়া
      final notificationService = Provider.of<NotificationService>(context, listen: false);

      // Context সেট করুন
      notificationService.setContext(context);

      // ওয়েবসকেট সংযোগ করুন
      await notificationService.connectWebSocket();

      // আনরিড নোটিফিকেশন লোড করুন
      await notificationService.loadUnreadNotifications();
    }
  }

  // ✅ পুরনো initNotificationSocket সরিয়ে ফেলুন
  // ✅ পুরনো showNotificationSnack সরিয়ে ফেলুন (Service এ আছে)

  Future<void> loadAllUser() async {
    bottomPages = [
      Homepage(),
      PostFeedPage(),
      AdvocateFilterPage(),
      AllUserChatListScreen(currentUserId: myId, currentUserName: myName),
      LogIn(),
    ];

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      appBar: AppBar(
        title: const Text("উকিল"),
        centerTitle: true,
        backgroundColor: Colors.green,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          // ✅ নোটিফিকেশন বেল (Consumer ব্যবহার করে)
          Consumer<NotificationService>(
            builder: (context, notificationService, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      // নোটিফিকেশন পেজে নেভিগেট করুন
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationPage()),
                      );
                    },
                  ),
                  // 🔴 ব্যাজ কাউন্টার
                  if (notificationService.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          notificationService.unreadCount > 9
                              ? '9+'
                              : notificationService.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // 👤 প্রোফাইল ইমেজ
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileMenuPage()),
                );
              },
              child: const ProfileImageWidget(),
            ),
          ),
        ],
      ),
      body: (index == 3 && myId != null)
          ? AllUserChatListScreen(currentUserId: myId, currentUserName: myName)
          : (bottomPages.isNotEmpty ? bottomPages[index] : const Center(child: CircularProgressIndicator())),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "হোম",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: "পোস্ট",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "এডভোকেট",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "চ্যাট",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.login),
            label: "লগইন",
          ),
        ],
        currentIndex: index,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (value) async {
          String? tempId;
          String? tempName;

          if (value == 3) {
            tempId = await getMyId();
            tempName = await getMyName();
          }

          setState(() {
            index = value;
            myId = tempId ?? myId;
            myName = tempName ?? myName;
          });
        },
      ),
    );
  }
}