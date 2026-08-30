import 'dart:convert';
import 'package:advocatechai/AdvocatePages/AdvocateFilterPage.dart';
import 'package:advocatechai/PostRelatedPages/post_feed_page.dart';
import 'package:advocatechai/ProfilePage/ProfileAvatar.dart';
import 'package:advocatechai/ProfilePage/ProfileImageWidget.dart';
//import 'package:advocatechai/AdvocatePages/AdvocateHomePage.dart';
import '../DirectorsPages/director_profile_page.dart';
import '../ShareholderPages/shareholder_profile_page.dart';
import '../DirectorsPages/director_list_page.dart';
import '../ShareholderPages/shareholder_list_page.dart';
import 'package:advocatechai/AdvocatePages/advocate_home_page_pageview.dart';
import '../DirectorsPages/DirectorRegistrationScreen.dart';
import '../ShareholderPages/shareholder_registration_screen.dart';
import '../CompanyPages/company_registration_screen.dart';
import '../CompanyPages/my_company_page.dart'; // ✅ Add this import
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
import 'ChatRelatedPages/district_selection_page.dart';
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
  final String? userId, userName, directorId, shareHolderId;

  const MyHomePage({super.key, required this.title, this.userId, this.userName, this.shareHolderId, this.directorId});

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
  String? _directorId;
  String? _shareHolderId;
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
    final directorId = prefs.getString('directorId');
    final shareHolderId = prefs.getString('shareHolderId');  

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
          DistrictSelectionPage(
              preSelectedDistrict : "AllDistrict",
              currentUserId : _userId,
              currentUserName : _userName,
          ),
          LogIn(key: UniqueKey()),
        ];
        _selectedIndex = 0;
      } else {
        // User is logged in
        bottomPages = [
          HomePage(key: UniqueKey()),
          PostFeedPage(key: UniqueKey()),
          AdvocateHomePage(key: UniqueKey()),
          DistrictSelectionPage(
              preSelectedDistrict : "AllDistrict",
              currentUserId : _userId,
              currentUserName : _userName,
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

    if (widget.directorId != null) {
      setState(() {
        _directorId = widget.directorId;
      });
    }

    if (widget.shareHolderId != null) {
      setState(() {
        _shareHolderId = widget.shareHolderId;
        print('Loaded shareHolderId :- $_shareHolderId');
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
        DistrictSelectionPage(
            preSelectedDistrict : "AllDistrict",
            currentUserId : _userId,
            currentUserName : _userName,
        ),
        LogIn(),
        DirectorRegistrationScreen(userId:_userId),
        ShareholderRegistrationScreen(userId:_userId),
      ];
      isLoading = false;
    });

    if (_userId != null && _userId!.isNotEmpty) {
      _startPresence();
    }
  }

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
          // Heartbeat successful
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
    final directorId = prefs.getString('directorId');
    final shareHolderId = prefs.getString('shareHolderId');  

    print('Loading user data - userId: $userId');
    print('Loading user data - directorId: $directorId');
    print('Loading user data - shareHolderId: $shareHolderId');

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
            _userName = (data['fullName'] ?? data['name']) ?? "User";
            _shareHolderId = shareHolderId;
            _directorId = directorId;
          });
          print('User loaded: $_userName');
          print('Director ID: $_directorId');
          print('Shareholder ID: $_shareHolderId');
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
        DistrictSelectionPage(
               preSelectedDistrict : "AllDistrict",
               currentUserId : _userId,
               currentUserName : _userName,
        ),
        DirectorRegistrationScreen(userId:_userId),
        const LogIn(),
        DirectorProfilePage(userId:_userId, directorId:_directorId),
        DirectorListPage(),
        ShareholderListPage(),
        ShareholderProfilePage(userId:_userId, shareholderId:_shareHolderId),
        ShareholderRegistrationScreen(userId:_userId),
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
                    onPressed: () async {
                      final token = await AuthService.getToken();
                      if(token == null) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LogIn()),);
                      }
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
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileMenuPage(userId: _userId)),
                );
                
                if (result == true) {
                  await _loadUserData();
                  
                  setState(() {
                    _userId = null;
                    _userName = null;
                    _isOnline = false;
                    
                    _heartbeatTimer?.cancel();
                    _heartbeatTimer = null;
                    
                    bottomPages = [
                      HomePage(),
                      PostFeedPage(),
                      AdvocateHomePage(),
                      DistrictSelectionPage(
                             preSelectedDistrict : "AllDistrict",
                             currentUserId : _userId,
                             currentUserName : _userName,
                      ),
                      DirectorRegistrationScreen(userId:_userId),
                      const LogIn(),
                      DirectorProfilePage(userId:_userId, directorId:_directorId),
                      DirectorListPage(),
                      ShareholderListPage(),
                      ShareholderProfilePage(userId:_userId, shareholderId:_shareHolderId),
                      ShareholderRegistrationScreen(userId:_userId),
                    ];
                    isLoading = false;
                    _selectedIndex = 0;
                  });
                  
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
                    
                    // ========== DIRECTOR SECTION ==========
                    if(_directorId == null || _directorId == "")
                      _buildModernDrawerItem(
                        icon: Icons.person_add,
                        title: "Director Registration",
                        index: 5,
                      ),
                    if(_directorId != null && _directorId!.isNotEmpty) 
                      _buildModernDrawerItem(
                        icon: Icons.person,
                        title: "Director Profile",
                        index: 6,
                      ),
                    
                    const Divider(color: Colors.white38, height: 20, thickness: 1),
                    
                    // ========== SHAREHOLDER SECTION ==========
                    if(_shareHolderId == null || _shareHolderId == "")
                      _buildModernDrawerItem(
                        icon: Icons.person_add,
                        title: "Shareholder Registration",
                        index: 10,
                      ),
                    if(_shareHolderId != null && _shareHolderId!.isNotEmpty) 
                      _buildModernDrawerItem(
                        icon: Icons.person,
                        title: "Shareholder Profile",
                        index: 9,
                      ),
                    
                    const Divider(color: Colors.white38, height: 20, thickness: 1),
                    
                    // ========== LIST VIEWS ==========
                    _buildModernDrawerItem(
                      icon: Icons.people,
                      title: "All Directors",
                      index: 7,
                    ),
                    _buildModernDrawerItem(
                      icon: Icons.people_outline,
                      title: "All Shareholders",
                      index: 8,
                    ),
                    
                    const Divider(color: Colors.white38, height: 20, thickness: 1),
                    
                    // ========== COMPANY SECTION ==========
                    if(_directorId != null && _directorId!.isNotEmpty) ...[
                      _buildModernDrawerItem(
                        icon: Icons.business,
                        title: "Company Registration",
                        index: 13,
                      ),
                      _buildModernDrawerItem(
                        icon: Icons.business_center,
                        title: "My Companies",
                        index: 14, // ✅ New index for My Companies
                      ),
                    ],
                    
                    const Divider(color: Colors.white38, height: 20, thickness: 1),
                    
                    // ========== ABOUT & TERMS ==========
                    _buildModernDrawerItem(
                      icon: Icons.info_outline,
                      title: "About Ukil",
                      index: 11,
                    ),
                    _buildModernDrawerItem(
                      icon: Icons.description,
                      title: "Terms & Privacy",
                      index: 12,
                    ),
                    
                    const Divider(color: Colors.white38, height: 20, thickness: 1),
                    
                    // ========== PROFILE / LOGIN ==========
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
              ? DistrictSelectionPage(
                  preSelectedDistrict : "AllDistrict",
                  currentUserId : _userId,
                  currentUserName : _userName,
              )
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
    // For pages that open as new pages (not bottom tabs), never show as selected
    final isSpecialPage = (index == 5 || index == 6 || index == 7 || index == 8 || index == 9 || index == 10 || index == 11 || index == 12 || index == 13 || index == 14);
    final isSelected = isSpecialPage ? false : (_selectedIndex == index);

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
    // Handle About Ukil (index 11)
    if (newIndex == 11) {
      Navigator.pop(context);
      await NavigationHelper.push(
        context,
        const AboutUkilScreen(),
        transitionType: await AnimatedRoute.getRandomSafeAnimation(),
        duration: const Duration(milliseconds: 500),
      );
      return;
    }

    // Handle Terms & Privacy (index 12)
    if (newIndex == 12) {
      Navigator.pop(context);
      await NavigationHelper.push(
        context,
        const TermsAndPrivacyScreen(),
        transitionType: await AnimatedRoute.getRandomSafeAnimation(),
        duration: const Duration(milliseconds: 500),
      );
      return;
    }

    // ✅ Handle Company Registration (index 13)
    if (newIndex == 13) {
      Navigator.pop(context);
      
      final token = await AuthService.getToken();
      if (token == null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LogIn()),
        );
        if (result == true && mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          await refreshUserData();
          setState(() {});
        }
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CompanyRegistrationScreen(
            userId: userId,
          ),
        ),
      );
      return;
    }

    // ✅ Handle My Companies (index 14)
    if (newIndex == 14) {
      Navigator.pop(context);
      
      final token = await AuthService.getToken();
      if (token == null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LogIn()),
        );
        if (result == true && mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          await refreshUserData();
          setState(() {});
        }
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Check if user is a director
      final directorId = prefs.getString('directorId');
      if (directorId == null || directorId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to be a director to view companies. Please register as a director first.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MyCompanyPage(),
        ),
      );
      return;
    }

    // ✅ Handle Director Profile (index 6)
    if (newIndex == 6) {
      Navigator.pop(context);
      
      final token = await AuthService.getToken();
      if (token == null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LogIn()),
        );
        if (result == true && mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          await refreshUserData();
          setState(() {});
        }
        return;
      }

      print('directorId :- $_directorId');
      
      final prefs = await SharedPreferences.getInstance();
      final storedDirectorId = prefs.getString('directorId');
      final directorIdToUse = _directorId ?? storedDirectorId;
      
      if (directorIdToUse != null && directorIdToUse.isNotEmpty) {
        print('Navigating to Director Profile with ID: $directorIdToUse');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DirectorProfilePage(
              userId: _userId ?? '',
              directorId: directorIdToUse,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are not registered as a director. Please register first.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DirectorRegistrationScreen(
              userId: _userId,
            ),
          ),
        );
      }
      return;
    }

    // ✅ Handle All Directors (index 7)
    if (newIndex == 7) {
      Navigator.pop(context);
      
      final token = await AuthService.getToken();
      if (token == null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LogIn()),
        );
        if (result == true && mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          await refreshUserData();
          setState(() {});
        }
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DirectorListPage(),
        ),
      );
      return;
    }

    // ✅ Handle All Shareholders (index 8)
    if (newIndex == 8) {
      Navigator.pop(context);
      
      final token = await AuthService.getToken();
      if (token == null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LogIn()),
        );
        if (result == true && mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          await refreshUserData();
          setState(() {});
        }
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ShareholderListPage(),
        ),
      );
      return;
    }

    // ✅ Handle Shareholder Profile (index 9)
    if (newIndex == 9) {
      Navigator.pop(context);
      
      final token = await AuthService.getToken();
      if (token == null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LogIn()),
        );
        if (result == true && mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          await refreshUserData();
          setState(() {});
        }
        return;
      }

      print('shareHolderId :- $_shareHolderId');
      
      final prefs = await SharedPreferences.getInstance();
      final storedShareHolderId = prefs.getString('shareHolderId');
      final shareHolderIdToUse = _shareHolderId ?? storedShareHolderId;
      
      if (shareHolderIdToUse != null && shareHolderIdToUse.isNotEmpty) {
        print('Navigating to Shareholder Profile with ID: $shareHolderIdToUse');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShareholderProfilePage(
              userId: _userId ?? '',
              shareholderId: shareHolderIdToUse,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are not registered as a shareholder. Please register first.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShareholderRegistrationScreen(
              userId: _userId,
            ),
          ),
        );
      }
      return;
    }

    // ✅ Handle Director Registration (index 5)
    if (newIndex == 5) {
      Navigator.pop(context);
      
      final token = await AuthService.getToken();
      if (token == null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LogIn()));
        return;
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DirectorRegistrationScreen(
            userId: _userId,
          ),
        ),
      );
      return;
    }

    // ✅ Handle Shareholder Registration (index 10)
    if (newIndex == 10) {
      Navigator.pop(context);
      
      final token = await AuthService.getToken();
      if (token == null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LogIn()));
        return;
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShareholderRegistrationScreen(
            userId: _userId,
          ),
        ),
      );
      return;
    }

    // ✅ Handle Login/Profile (index 4)
    if (newIndex == 4) {
      final token = await AuthService.getToken();
      if (token == null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LogIn()));
        return;
      }

      Navigator.pop(context);

      if (_userId != null && _userId!.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileMenuPage(userId: _userId)),
        );
        await refreshUserData();
      } else {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LogIn()),
        );

        if (result == true && mounted) {
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

    // ✅ For main tab navigation (indices 0, 1, 2, 3)
    final token = await AuthService.getToken();
    if (token == null) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LogIn()));
      return;
    } else {
      if (newIndex >= 0 && newIndex < bottomPages.length) {
        setState(() {
          _selectedIndex = newIndex;
        });
      }
    }
    
    Navigator.pop(context);
  }
}