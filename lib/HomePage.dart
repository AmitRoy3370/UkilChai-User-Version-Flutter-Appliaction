// HomePage.dart - Complete with Unified Filter System + Random Animations + Logo

import 'package:advocatechai/HomePage/AdvocateList.dart';
import 'package:advocatechai/AdvocatePages/advocate_home_page_pageview.dart';
import 'package:advocatechai/HomePage/QuickConnect.dart';
import '../PostRelatedPages/post_feed_page_home_page.dart';
import 'package:advocatechai/PostRelatedPages/post_feed_page.dart';
import 'package:advocatechai/AdvocatePages/AdvocateFilterPage.dart';
import 'package:advocatechai/Utils/AdvocateSpeciality.dart';
import 'ChatRelatedPages/user_active_service.dart';
import 'LifeCycles/LifecycleManager.dart';
import 'package:advocatechai/Auth/AuthService.dart';
import 'Utils/BaseURL.dart' as BASE_URL;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:advocatechai/HomePage/AdvocateListView.dart';
import 'package:advocatechai/HomePage/AdvocateListPage.dart';
import 'package:advocatechai/HomePage/SpecialityDropdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../HomePage/AdvocateFilter.dart';
import '../HomePage/AdvocateFilterBar.dart';
import '../RegistrationPage/gender.dart';
import 'PageTransition.dart'; // Import the page transitions file

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _heartbeatTimer;
  
  // ========== পোস্ট টাইপ স্টেট ==========
  String? _selectedPostType;
  
  // ========== অ্যাডভোকেট ফিল্টার স্টেট ==========
  AdvocateFilter _filter = AdvocateFilter(); // Initialize with empty filter
  
  // ========== লোকেশন লিস্ট ==========
  final List<String> allLocations = [
    'Bagerhat', 'Bandarban', 'Barguna', 'Barisal', 'Bhola', 'Bogra',
    'Brahmanbaria', 'Chandpur', 'Chapai Nawabganj', 'Chittagong', 'Chuadanga',
    'Comilla', "Cox's Bazar", 'Dhaka', 'Dinajpur', 'Faridpur', 'Feni',
    'Gaibandha', 'Gazipur', 'Gopalganj', 'Habiganj', 'Jamalpur', 'Jessore',
    'Jhalokati', 'Jhenaidah', 'Joypurhat', 'Khagrachari', 'Khulna',
    'Kishoreganj', 'Kurigram', 'Kushtia', 'Lakshmipur', 'Lalmonirhat',
    'Madaripur', 'Magura', 'Manikganj', 'Meherpur', 'Moulvibazar',
    'Munshiganj', 'Mymensingh', 'Naogaon', 'Narail', 'Narayanganj',
    'Narsingdi', 'Natore', 'Netrokona', 'Nilphamari', 'Noakhali', 'Pabna',
    'Panchagarh', 'Patuakhali', 'Pirojpur', 'Rajbari', 'Rajshahi',
    'Rangamati', 'Rangpur', 'Satkhira', 'Shariatpur', 'Sherpur',
    'Sirajganj', 'Sunamganj', 'Sylhet', 'Tangail', 'Thakurgaon'
  ];

  // ========== WELCOME BANNER STATE ==========
  bool _isWelcomeBannerVisible = true;

  @override
  void initState() {
    super.initState();
    heartbit();
    _loadSavedFilter();
  }

  Future<void> heartbit() async {
    final userId = await AuthService.getUserId();
    if (userId != null) {
      _startHeartbeat(userId!);
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
          if (response.statusCode != 200) {
            print("❌ Heartbeat failed: ${response.statusCode}");
          }
        } catch (e) {
          print("❌ Heartbeat error: $e");
        }
      },
    );
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  // ========== ফিল্টার মেথড ==========
  void _onFilterChanged(AdvocateFilter newFilter) {
    setState(() {
      _filter = newFilter;
    });
    _saveFilter(newFilter);
  }

  void _saveFilter(AdvocateFilter filter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (filter.speciality != null && filter.speciality!.isNotEmpty) {
        await prefs.setString('filter_speciality', filter.speciality!);
      } else {
        await prefs.remove('filter_speciality');
      }
      if (filter.location != null && filter.location!.isNotEmpty) {
        await prefs.setString('filter_location', filter.location!);
      } else {
        await prefs.remove('filter_location');
      }
      if (filter.gender != null) {
        await prefs.setString('filter_gender', filter.gender!.name);
      } else {
        await prefs.remove('filter_gender');
      }
    } catch (e) {
      print("⚠️ Error saving filter: $e");
    }
  }

  void _loadSavedFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final speciality = prefs.getString('filter_speciality');
      final location = prefs.getString('filter_location');
      final genderStr = prefs.getString('filter_gender');
      
      Gender? gender;
      if (genderStr != null) {
        try {
          gender = Gender.values.firstWhere((g) => g.name == genderStr);
        } catch (e) {
          gender = null;
        }
      }
      
      setState(() {
        _filter = AdvocateFilter(
          speciality: speciality,
          location: location,
          gender: gender,
        );
      });
    } catch (e) {
      print("⚠️ Error loading saved filter: $e");
      // If error loading, use default empty filter
      setState(() {
        _filter = AdvocateFilter();
      });
    }
  }

  // ========== NAVIGATION WITH RANDOM ANIMATIONS ==========
  void _navigateWithRandomAnimation(Widget page) async {
    final animation = await AnimatedRoute.getRandomSafeAnimation();
    if (context.mounted) {
      NavigationHelper.push(
        context,
        page,
        transitionType: animation,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  void _navigateToPostFeed(String? postType) {
    _navigateWithRandomAnimation(
      PostFeedPageHomePage(
        initialPostType: postType,
      ),
    );
  }

  void _navigateToFeaturedAdvocates() {
    _navigateWithRandomAnimation(
      const AdvocateHomePage(),
    );
  }

  void _navigateToAllPosts() {
    _navigateWithRandomAnimation(
      const PostFeedPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final isTablet = screenWidth > 600 && screenWidth <= 800;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green.shade50, Colors.white, Colors.green.shade50],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : (isTablet ? 24 : 16),
              vertical: 20,
            ),
            child: Column(
              children: [
                _buildWelcomeBanner(context, isDesktop, isTablet),
                const SizedBox(height: 24),
                QuickConnect(
                  key: UniqueKey(),
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                ),
                const SizedBox(height: 32),
                
                // ========== Recent Legal Updates ==========
                _buildPostTypeSelector(),
                const SizedBox(height: 16),
                
                // ========== Featured Advocates with Filter Bar ==========
                _buildFeaturedAdvocatesHeader(),
                const SizedBox(height: 16),
                
                // ========== Advocate List ==========
                AdvocateListView(
                  key: ValueKey('${_filter.speciality}_${_filter.location}_${_filter.gender}'),
                  filter: _filter,
                  crossAxisCount: 2,
                  showAll: true,
                ),
                const SizedBox(height: 20),
                _buildAdvocatePromotionCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== WELCOME BANNER ==========
  Widget _buildWelcomeBanner(BuildContext context, bool isDesktop, bool isTablet) {
    if (!_isWelcomeBannerVisible) {
      // Show reopen button when banner is closed
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isWelcomeBannerVisible = true;
                });
              },
              icon: const Icon(
                Icons.expand_more,
                color: Colors.green,
                size: 20,
              ),
              label: Text(
                "Show Welcome Message",
                style: GoogleFonts.inter(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.green.shade50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.green.shade200,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 24,
        vertical: isDesktop ? 32 : 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green, Colors.greenAccent, Colors.green],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Logo Container - REPLACED GAVEL ICON WITH LOGO
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png', // Path to your logo
                      height: 40,
                      width: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Welcome to উকিল",
                      style: GoogleFonts.poppins(
                        fontSize: isDesktop ? 28 : (isTablet ? 24 : 20),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Your trusted legal partner. Connect with expert advocates, get legal advice, and manage your cases efficiently.",
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 16 : 14,
                  color: Colors.white.withOpacity(0.95),
                  height: 1.5,
                ),
              ),
            ],
          ),
          // Close button positioned at top-right
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isWelcomeBannerVisible = false;
                });
              },
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  // ========== 🔥 Featured Advocates Header ==========
  Widget _buildFeaturedAdvocatesHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Logo Container - REPLACED STAR ICON WITH LOGO
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png', // Path to your logo
                      height: 24,
                      width: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Featured Advocates",
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              
              // See All button with random animation
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton(
                  onPressed: _navigateToFeaturedAdvocates,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    foregroundColor: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "See All",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 11 : 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 🔥 Unified Filter Bar
          AdvocateFilterBar(
            filter: _filter,
            onFilterChanged: _onFilterChanged,
            locations: allLocations,
          ),
        ],
      ),
    );
  }

  // ========== 🔥 Post Type Selector ==========
  Widget _buildPostTypeSelector() {
    final allTypes = AdvocateSpeciality.values;
    final totalTypes = allTypes.length;
    
    final int midPoint = (totalTypes / 2).ceil();
    final List<AdvocateSpeciality> firstHalf = allTypes.sublist(0, midPoint);
    final List<AdvocateSpeciality> secondHalf = allTypes.sublist(midPoint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Logo Container - REPLACED DEFAULT ICON WITH LOGO
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/images/logo.png', // Path to your logo
                    height: 20,
                    width: 20,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Recent Legal Updates",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _navigateToAllPosts,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.post_add,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "See All",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            _buildSpecialityRow(firstHalf, 'first'),
            const SizedBox(height: 10),
            _buildSpecialityRow(secondHalf, 'second'),
          ],
        ),
      ],
    );
  }

  // ========== 🔥 Speciality Row ==========
  Widget _buildSpecialityRow(List<AdvocateSpeciality> items, String rowId) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final type = items[index];
          final isSelected = _selectedPostType == type.apiValue;
          
          return Container(
            width: 100,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildTypeChip(type, isSelected),
          );
        },
      ),
    );
  }

  // ========== Type Chip ==========
  Widget _buildTypeChip(AdvocateSpeciality type, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (isSelected) {
          setState(() {
            _selectedPostType = null;
          });
        } else {
          _navigateToPostFeed(type.apiValue);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.green.shade600 
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Colors.green.shade600 
                : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type.icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              type.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ========== Advocate Promotion Card ==========
  Widget _buildAdvocatePromotionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple.shade600, Colors.purple.shade500, Colors.blue.shade500],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo Container - REPLACED PREMIUM ICON WITH LOGO
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/logo.png', // Path to your logo
              height: 42,
              width: 42,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Want to be an Advocate?",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Join our advocate platform and connect with clients across Bangladesh.",
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse('https://advocate.ukil.com.bd');
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text("Visit Advocate App"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}