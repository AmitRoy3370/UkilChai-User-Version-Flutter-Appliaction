
// HomePage.dart - Updated with Dropdown

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
import 'package:advocatechai/HomePage/SpecialityDropdown.dart'; // নতুন ইমপোর্ট
import 'package:shared_preferences/shared_preferences.dart';


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
  String? _selectedSpeciality;

  @override
  void initState() {
    super.initState();
    heartbit();
    _loadSavedSpeciality();
  }

  Future<void> heartbit() async {
    final userId = await AuthService.getUserId();
    if (userId != null) {
      _startHeartbeat(userId!);
    }
  }

  // 🔥 স্পেশালিটি সেভ করুন
  void _saveSpeciality(String? speciality) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (speciality != null && speciality.isNotEmpty) {
        await prefs.setString('selected_speciality', speciality);
        print("💾 Saved speciality: $speciality");
      } else {
        await prefs.remove('selected_speciality');
        print("🗑️ Removed speciality");
      }
    } catch (e) {
      print("⚠️ Error saving speciality: $e");
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

  // ========== টাইপ সিলেক্ট করলে PostFeedPageHomePage-এ নেভিগেট ==========
  void _navigateToPostFeed(String? postType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostFeedPageHomePage(
          initialPostType: postType,
        ),
      ),
    );
  }

  // ========== স্পেশালিটি সিলেক্ট করার ফাংশন ==========
  void _onSpecialitySelected(String? speciality) {
    setState(() {
      _selectedSpeciality = speciality;
    });
    _saveSpeciality(speciality);
  }

  // 🔥 সেভ করা স্পেশালিটি লোড করুন
  void _loadSavedSpeciality() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSpeciality = prefs.getString('selected_speciality');
      if (savedSpeciality != null && savedSpeciality.isNotEmpty) {
        setState(() {
          _selectedSpeciality = savedSpeciality;
        });
        print("📂 Loaded saved speciality: $savedSpeciality");
      }
    } catch (e) {
      print("⚠️ Error loading saved speciality: $e");
    }
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
                
                // ========== 🔥 Recent Legal Updates Header ==========
                const SizedBox(height: 16),
                
                // ========== 🔥 পোস্ট টাইপ সিলেক্টর (স্ক্রোলযোগ্য ২ সারি) ==========
                _buildPostTypeSelector(),
                const SizedBox(height: 16),
                
                // ========== 🔥 Featured Advocates Header with Dropdown ==========
                _buildFeaturedAdvocatesHeader(),
                const SizedBox(height: 16),
                
                // ========== 🔥 Advocate List ==========
                AdvocateListView(
                  key: ValueKey(_selectedSpeciality ?? 'all'), // 🔥 Key যোগ করুন
                  speciality: _selectedSpeciality,
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

// ========== 🔥 Featured Advocates Header with Dropdown ==========
Widget _buildFeaturedAdvocatesHeader() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.star, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            "Featured Advocates",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
      SingleChildScrollView(scrollDirection: Axis.horizontal,child : Row(
        children: [
          SpecialityDropdown(
            onSpecialitySelected: _onSpecialitySelected,
            selectedSpeciality: _selectedSpeciality,
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdvocateListPage(
                    speciality: _selectedSpeciality,
                  ),
                ),
              );
            },
            child: Text(
              "See All",
              style: GoogleFonts.inter(
                color: Colors.green.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
       ),
      ),
    ],
  );
}
  // ========== 🔥 পোস্ট টাইপ সিলেক্টর (স্ক্রোলযোগ্য ২ সারি) ==========
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
            Text(
              "Recent Legal Updates",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PostFeedPage(),
                  ),
                );
              },
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

  // ========== 🔥 স্পেশালিটির সারি (স্ক্রোলযোগ্য) ==========
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

  // ========== টাইপ চিপ ==========
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

  Widget _buildWelcomeBanner(BuildContext context, bool isDesktop, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 24,
        vertical: isDesktop ? 32 : 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade700, Colors.green.shade500, Colors.green.shade400],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.gavel, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Welcome to উকিল চাই",
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
    );
  }

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
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium,
              size: 42,
              color: Colors.white,
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