import 'dart:convert';
import 'package:advocatechai/AdvocatePages/AdvocateFilterPage.dart';
import 'package:advocatechai/PostRelatedPages/post_feed_page.dart';
import 'package:advocatechai/ProfilePage/ProfileAvatar.dart';
import 'package:advocatechai/ProfilePage/ProfileImageWidget.dart';
//import 'package:advocatechai/AdvocatePages/AdvocateHomePage.dart';
import 'package:advocatechai/AdvocatePages/advocate_home_page_pageview.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:advocatechai/Auth/AuthService.dart';
import 'TermsAndPrivacyScreen.dart';
import 'AboutUkilScreen.dart';
import 'ChatRelatedPages/AllUserChatListScreen.dart';
import 'ChatRelatedPages/user_active_service.dart';
import 'HomePage.dart';
import 'LifeCycles/LifecycleManager.dart';
import 'LifeCycles/PresenceSocketService.dart';
import 'LogInPage/LogIn.dart';
import 'NotificationPages/notification_page.dart';
import 'NotificationPages/notification_service.dart';
import 'PostRelatedPages/post_feed_page_home_page.dart';
import 'ProfilePage/ProfileMenuPage.dart';
import 'Utils/BaseURL.dart' as BASE_URL;
import 'dart:async';
import 'PageTransition.dart';

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
  Timer? _heartbeatTimer;
  String? _userId;
  String? _userName;
  bool _isOnline = false;


// Public method to refresh user data - can be called from anywhere
Future<void> refreshUserData() async {
  print("Refreshing user data...");
  await _loadUserData();
  print("Loaded userId: $_userId");
  print("Loaded userName: $_userName");

  // Check if user is logged out
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');
  
  setState(() {
    if (userId == null || userId.isEmpty) {
      // User is logged out, show Login page
      _userId = null;
      _userName = null;
      _isOnline = false;
      
      // Cancel heartbeat timer
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
      
      bottomPages = [
        HomePage(key: UniqueKey()),
        PostFeedPage(key: UniqueKey()),
        AdvocateHomePage(key: UniqueKey()),
        AllUserChatListScreen(
          key: UniqueKey(),
          currentUserId: null,
          currentUserName: null,
        ),
        LogIn(key: UniqueKey()),
      ];
      _selectedIndex = 0; // Go to Home
    } else {
      // User is logged in
      bottomPages = [
        HomePage(key: UniqueKey()),
        PostFeedPage(key: UniqueKey()),
        AdvocateHomePage(key: UniqueKey()),
        AllUserChatListScreen(
          key: UniqueKey(),
          currentUserId: _userId,
          currentUserName: _userName,
        ),
        LogIn(key: UniqueKey()),
      ];
    }
  });
}

  @override
  void initState() {
    super.initState();

    if (widget.userId != null) {
      setState(() {
        _userId = widget.userId;
      });
    }

    if (widget.userName != null) {
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
        AdvocateHomePage(isShow:false),
        AllUserChatListScreen(
          currentUserId: _userId,
          currentUserName: _userName,
        ),
        LogIn(),
      ];
      isLoading = false;
    });

    // ✅ Start presence after user is loaded
    if (_userId != null && _userId!.isNotEmpty) {
      _startPresence();
    }

  }

  // ✅ Start presence service
  void _startPresence() {
    if (_userId != null && _userId!.isNotEmpty) {
      final socketService = PresenceSocketService();
      socketService.connect(_userId!);
      _startHeartbeat(_userId!);
      setState(() {
        _isOnline = true;
      });
      print('🟢 User is now ONLINE');
    }
  }

  void _startHeartbeat(String userId) {
    _heartbeatTimer = Timer.periodic(
    const Duration(seconds: 20),
    (timer) async {
       try {
      // ✅ Direct heartbeat by userId
      final url = Uri.parse("${BASE_URL.Urls().baseURL}user-active/heartbeat/$userId");
      
      final token = await AuthService.getToken();

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        //_lastHeartbeatTime = DateTime.now();
        //print("💓 Heartbeat sent at ${_lastHeartbeatTime?.toLocal()}");
      } else {
        print("❌ Heartbeat failed: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Heartbeat error: $e");
    }
    },
  );
}

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('jwt_token');

    print('Loading user data - userId: $userId');

    if (userId != null && token != null && userId.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse("${BASE_URL.Urls().baseURL}user/search?userId=$userId"),
          headers: {
            'content-type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _userId = userId;
            _userName = data['name'] ?? "User";
          });
          print('User loaded: $_userName');
        }
      } catch (e) {
        print('Error loading user: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Don't find any user Info....")),
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
        AdvocateHomePage(),
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
                MaterialPageRoute(builder: (_) => const NotificationPage()),
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
  if(_userId != null) Padding(
    padding: const EdgeInsets.only(right: 20),
    child: GestureDetector(
      onTap: () async {
        // ✅ FIX: Use await to get the result
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileMenuPage(userId: _userId)),
        );
        
        if (result == true) {
          // Clear user data
          await _loadUserData();
          
          // Update the state
          setState(() {
            _userId = null;
            _userName = null;
            _isOnline = false;
            
            // Cancel heartbeat timer
            _heartbeatTimer?.cancel();
            _heartbeatTimer = null;
            
            // Update bottomPages to show LogIn instead of Profile
            bottomPages = [
              HomePage(key: UniqueKey()),
              PostFeedPage(key: UniqueKey()),
              AdvocateHomePage(key: UniqueKey()),
              AllUserChatListScreen(
                key: UniqueKey(),
                currentUserId: null,
                currentUserName: null,
              ),
              LogIn(key: UniqueKey()),
            ];
            _selectedIndex = 0; // Go to Home tab
          });
          
          // Show logout message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("You have been logged out."),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
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
                      title: "Home",
                      index: 0,
                    ),
                    _buildModernDrawerItem(
                      icon: Icons.article,
                      title: "Post",
                      index: 1,
                    ),
                    _buildModernDrawerItem(
                      icon: Icons.person,
                      title: "Advocate",
                      index: 2,
                    ),
                    _buildModernDrawerItem(
                      icon: Icons.chat,
                      title: "Chat",
                      index: 3,
                    ),
                    const Divider(color: Colors.white38, height: 20, thickness: 1),
                    
                    // NEW: About Ukil Option
                    _buildModernDrawerItem(
                      icon: Icons.info_outline,
                      title: "About Ukil",
                      index: 5,
                    ),
                    
                    // NEW: Terms & Privacy Option
                    _buildModernDrawerItem(
                      icon: Icons.description,
                      title: "Terms & Privacy",
                      index: 6,
                    ),
                    
                    const Divider(color: Colors.white38, height: 20, thickness: 1),
                    
                    _buildModernDrawerItem(
                      icon: _userId != null ? Icons.person : Icons.login,
                      title: _userId != null ? "Profile" : "LogIn",
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
            _userName ?? "Invited Guest",
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
              _userId != null ? "Online" : "Offline",
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
    // For About and Terms pages (indices 5 and 6), never show as selected
    final isSelected = (index == 5 || index == 6) ? false : (_selectedIndex == index);

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
            "© ${DateTime.now().year} উকিল চাই",
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
    // Handle About Ukil (index 5) - Open as new page
    if (newIndex == 5) {
      Navigator.pop(context); // Close drawer
      await NavigationHelper.push(
        context,
        const AboutUkilScreen(),
        transitionType: await AnimatedRoute.getRandomSafeAnimation(),
        duration: const Duration(milliseconds: 500),
      );
      return;
    }

    // Handle Terms & Privacy (index 6) - Open as new page
    if (newIndex == 6) {
      Navigator.pop(context); // Close drawer
      await NavigationHelper.push(
        context,
        const TermsAndPrivacyScreen(),
        transitionType: await AnimatedRoute.getRandomSafeAnimation(),
        duration: const Duration(milliseconds: 500),
      );
      return;
    }

    // Handle Login/Profile (index 4)
    if (newIndex == 4) {
      Navigator.pop(context); // Close drawer

      if (_userId != null && _userId!.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileMenuPage(userId:_userId)),
        );
        await refreshUserData();
      } else {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LogIn(),
          ),
        );

        if (result == true && mounted) {
          // wait a little for SharedPreferences to settle
          await Future.delayed(const Duration(milliseconds: 300));
          await refreshUserData();
          setState(() {});
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

    // For main tab navigation (indices 0, 1, 2, 3)
    if (newIndex >= 0 && newIndex < bottomPages.length) {
      setState(() {
        _selectedIndex = newIndex;
      });
    }
    
    Navigator.pop(context);
  }
}