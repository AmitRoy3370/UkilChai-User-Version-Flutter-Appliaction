import 'dart:convert';
import 'package:advocatechai/AdvocatePages/AdvocateFilterPage.dart';
import 'package:advocatechai/PostRelatedPages/post_feed_page.dart';
import 'package:advocatechai/ProfilePage/ProfileAvatar.dart';
import 'package:advocatechai/ProfilePage/ProfileImageWidget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'ChatRelatedPages/AllUserChatListScreen.dart';
import 'ChatRelatedPages/user_active_service.dart';
import 'HomePage.dart';
import 'LifeCycles/LifecycleManager.dart';
import 'LogInPage/LogIn.dart';
import 'NotificationPages/notification_page.dart';
import 'NotificationPages/notification_service.dart';
import 'PostRelatedPages/post_feed_page_home_page.dart';
import 'ProfilePage/ProfileMenuPage.dart';
import 'Utils/BaseURL.dart' as BASE_URL;

// Global key to access MyHomePage state from anywhere
final GlobalKey<_MyHomePageState> homePageKey = GlobalKey<_MyHomePageState>();

void main() {
  runApp(
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
      home: MyHomePage(
  key: homePageKey,
  title: 'উকিল চাই',
),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {


  final String? userId, userName;

  const MyHomePage({super.key, required this.title, this.userId, this.userName});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late List<Widget> bottomPages = [];
  bool isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  String? _userId;
  String? _userName;

  // Public method to refresh user data - can be called from anywhere
Future<void> refreshUserData() async {

  print("Refreshing user data...");

  await _loadUserData();

  print("Loaded userId: $_userId");
  print("Loaded userName: $_userName");

  setState(() {

    bottomPages = [

      HomePage(key: UniqueKey()),

      PostFeedPage(key: UniqueKey()),

      AdvocateFilterPage(key: UniqueKey()),

      AllUserChatListScreen(
        key: UniqueKey(),
        currentUserId: _userId,
        currentUserName: _userName,
      ),

      LogIn(key: UniqueKey()),
    ];

  });

}
  @override
  void initState() {
    super.initState();

    if(widget.userId != null) {

        setState(() {

            _userId = widget.userId;

        });

        

    }

    if(widget.userName != null) {

        setState(() {

            _userName = widget.userName;

        });

    }

    _initializeData();
  }

  Future<void> _initializeData() async {
  await _loadUserData();
  await _initializeNotification();

  setState(() {
    bottomPages = [
  HomePage(),
  PostFeedPage(),
  AdvocateFilterPage(),
  AllUserChatListScreen(
    currentUserId: _userId,
    currentUserName: _userName,
  ),
  LogIn(),
];

    isLoading = false;
  });
}

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('jwt_token');

    print('Loading user data - userId: $userId');


    /*ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("userId :- ${userId} and token :- ${token}")),
        );*/

    if (userId != null && token != null && userId.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse("${BASE_URL.Urls().baseURL}user/search?userId=$userId"),
          headers: {
            'content-type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

         /*ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("response :- ${response.body}")),
        );*/

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _userId = userId;
            _userName = data['name'] ?? "User";
          });
          print('User loaded: $_userName');

          /*ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("userName :- $_userName and $_userId")),
        );*/


        }
      } catch (e) {
        print('Error loading user: $e');
      }
    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Don't find any user Info....")),
      );

      setState(() {
        _userId = null;
        _userName = null;
      });
    }
  }

  Future<void> _initializeNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final myId = prefs.getString('userId');

    if (myId != null && myId.isNotEmpty) {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      notificationService.setContext(context);
      await notificationService.connectWebSocket();
      await notificationService.loadUnreadNotifications();
    }
  }

  Future<void> loadAllUser() async {
    setState(() {

      bottomPages = [];

      bottomPages = [
        HomePage(),
        PostFeedPage(),
        AdvocateFilterPage(),
        AllUserChatListScreen(
          currentUserId: _userId,
          currentUserName: _userName,
        ),
        const LogIn(),
      ];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          Consumer<NotificationService>(
            builder: (context, notificationService, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NotificationPage()),
                      );
                    },
                  ),
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
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileMenuPage()),
                );
              },
              child: ProfileImageWidget(
  key: ValueKey(_userId),
),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        width: 280,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade800,
                Colors.green.shade600,
                Colors.green.shade400,
              ],
            ),
          ),
          child: Column(
            children: [
              _buildModernDrawerHeader(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildModernDrawerItem(
                      icon: Icons.home,
                      title: "হোম",
                      index: 0,
                    ),
                    _buildModernDrawerItem(
                      icon: Icons.article,
                      title: "পোস্ট",
                      index: 1,
                    ),
                    _buildModernDrawerItem(
                      icon: Icons.person,
                      title: "এডভোকেট",
                      index: 2,
                    ),
                    _buildModernDrawerItem(
                      icon: Icons.chat,
                      title: "চ্যাট",
                      index: 3,
                    ),
                    const Divider(color: Colors.white38, height: 20, thickness: 1),
                    _buildModernDrawerItem(
                      icon: _userId != null ? Icons.person : Icons.login,
                      title: _userId != null ? "প্রোফাইল" : "লগইন",
                      index: 4,
                    ),
                  ],
                ),
              ),
              _buildModernFooter(),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_selectedIndex == 3 && _userId != null)
          ? AllUserChatListScreen(currentUserId: _userId, currentUserName: _userName)
          : bottomPages[_selectedIndex],
    );
  }

  Widget _buildModernDrawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Column(
        children: [
          Hero(
            tag: 'profileHero',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: _userId != null
                      ? ProfileAvatar(key: ValueKey(_userId))
                      : const Icon(Icons.person, size: 50, color: Colors.green),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userName ?? "আমন্ত্রিত অতিথি",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _userId != null ? "অনলাইন" : "অফলাইন",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white70,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16)
            : null,
        onTap: () {
          _onItemTapped(index);
        },
      ),
    );
  }

  Widget _buildModernFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, color: Colors.white.withOpacity(0.5), size: 8),
              const SizedBox(width: 4),
              Icon(Icons.circle, color: Colors.white.withOpacity(0.5), size: 8),
              const SizedBox(width: 4),
              Icon(Icons.circle, color: Colors.white.withOpacity(0.5), size: 8),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "© 2026 উকিল চাই",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int newIndex) async {
    if (newIndex == 4) {
      Navigator.pop(context); // Close drawer

      if (_userId != null && _userId!.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileMenuPage()),
        );
        await refreshUserData();
      } else {
        final result = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => LogIn(),
  ),
);

if (result == true && mounted) {

  // wait a little for SharedPreferences to settle
  await Future.delayed(const Duration(milliseconds: 300));

  await refreshUserData();

  setState(() {

  });

  ScaffoldMessenger.of(context).showSnackBar(

    const SnackBar(
      content: Text("Welcome! You have successfully logged in."),
      backgroundColor: Colors.green,
    ),

  );
}
      }
      return;
    }

    setState(() {
      _selectedIndex = newIndex;
    });
    Navigator.pop(context);
  }
}