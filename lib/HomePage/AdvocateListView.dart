import 'dart:convert';
import 'package:advocatechai/AdvocatePages/AdvocateDetailsModel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:advocatechai/Utils/BaseURL.dart' as baseURL;
import '../PageTransition.dart';
import 'package:advocatechai/Auth/AuthService.dart';
import '../AdvocatePages/AdvocateDetails.dart';
import 'package:google_fonts/google_fonts.dart';

class AdvocateListView extends StatefulWidget {
  final String? speciality;
  final int crossAxisCount;
  final bool showAll;
  
  const AdvocateListView({
    super.key,
    this.speciality,
    this.crossAxisCount = 2,
    this.showAll = false,
  });

  @override
  State<AdvocateListView> createState() => _AdvocateListViewState();
  
  static Future<List<AdvocateDetailsModel>> getAdvocateList({String? speciality}) async {
    try {
      final token = await AuthService.getToken();
      String? searchSpeciality;

      if (speciality != null && 
        speciality.isNotEmpty && 
        speciality != 'null' && 
        speciality != 'All Specialities') {
        searchSpeciality = speciality;
      }

      final uri = speciality == null || speciality == 'null' || speciality == 'All Specialities'
          ? Uri.parse("${baseURL.Urls().baseURL}advocate/all") 
          : Uri.parse("${baseURL.Urls().baseURL}advocate/search/speciality/${speciality}");

      print("📡 Fetching advocates from: $uri");

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("📊 Response status: ${response.statusCode}");

      if (response.statusCode != 200) {
        print("❌ Error response: ${response.body}");
        throw Exception("Failed to load advocates: ${response.statusCode}");
      }

      final List responseData = jsonDecode(response.body);
      print("📊 Found ${responseData.length} advocates");
      
      List<AdvocateDetailsModel> list = [];

      for (var item in responseData) {
        try {
          final advocateDecoded = item as Map<String, dynamic>;
          
          final model = AdvocateDetailsModel.defaultConstructor()
            ..id = advocateDecoded["id"]?.toString()
            ..userId = advocateDecoded["userId"]?.toString()
            ..name = advocateDecoded["name"]?.toString()
            ..fullName = advocateDecoded["name"]?.toString()
            ..profileImageId = advocateDecoded["profileImageId"]?.toString()
            ..experience = (advocateDecoded["experience"] ?? 0)
            ..licenseKey = advocateDecoded["licenseKey"]?.toString()
            ..advocateSpeciality = advocateDecoded["advocateSpeciality"] != null
                ? List<String>.from(advocateDecoded["advocateSpeciality"].map((e) => e.toString()))
                : []
            ..degrees = advocateDecoded["degrees"] != null
                ? List<String>.from(advocateDecoded["degrees"].map((e) => e.toString()))
                : []
            ..workingExperiences = advocateDecoded["workingExperiences"] != null
                ? List<String>.from(advocateDecoded["workingExperiences"].map((e) => e.toString()))
                : []
            ..email = advocateDecoded["email"]?.toString()
            ..phone = advocateDecoded["phone"]?.toString()
            ..locationName = advocateDecoded["locationName"]?.toString()
            ..lattitude = advocateDecoded["lattitude"] != null 
                ? double.tryParse(advocateDecoded["lattitude"].toString()) 
                : null
            ..longitude = advocateDecoded["longitude"] != null 
                ? double.tryParse(advocateDecoded["longitude"].toString()) 
                : null
            ..contactInfoId = advocateDecoded['contactInfoId']?.toString()
            ..locationId = advocateDecoded['locationId']?.toString()
            ..cvHexKey = advocateDecoded['cvHexKey']?.toString()
            ..district = advocateDecoded['district']?.toString()
            ..rating = advocateDecoded['rating'] != null 
                ? double.tryParse(advocateDecoded['rating'].toString()) ?? 0.0 
                : 0.0;

          list.add(model);
        } catch (e) {
          print("⚠️ Error parsing advocate: $e");
        }
      }

      return list;
    } catch (e) {
      print("❌ Error in getAdvocateList: $e");
      return [];
    }
  }
}

class _AdvocateListViewState extends State<AdvocateListView> {
  List<AdvocateDetailsModel> _advocates = [];
  bool _isLoading = true;
  String? _error;
  
  final ScrollController _scrollController = ScrollController();
  
  // 🔥 ইমেজ ক্যাশের জন্য Map
  final Map<String, Uint8List?> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _loadAdvocates();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AdvocateListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speciality != widget.speciality) {
      print("🔄 Speciality changed from ${oldWidget.speciality} to ${widget.speciality}");
      _imageCache.clear();
      _loadAdvocates();
    }
  }

  Future<void> _loadAdvocates() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final advocates = await AdvocateListView.getAdvocateList(
        speciality: widget.speciality,
      );
      if (mounted) {
        setState(() {
          _advocates = advocates;
          _isLoading = false;
        });
        print("✅ Loaded ${advocates.length} advocates");
        
        // 🔥 প্রতিটি অ্যাডভোকেটের profileImageId চেক করুন
        for (var adv in advocates) {
          print("👤 ${adv.name} - ProfileImageId: ${adv.profileImageId ?? 'NULL'}");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        print("❌ Error loading advocates: $e");
      }
    }
  }

  // 🔥 ক্যাশ সহ ইমেজ লোড
  Future<Uint8List?> fetchProfileImage(String? imageId) async {
    if (imageId == null || imageId.isEmpty) {
      print("⚠️ No imageId provided");
      return null;
    }
    
    // 🔥 ক্যাশে আছে কিনা চেক
    if (_imageCache.containsKey(imageId)) {
      print("✅ Image found in cache: $imageId");
      return _imageCache[imageId];
    }

    try {
      final token = await AuthService.getToken();
      /*if (token == null || token.isEmpty) {
        print("⚠️ No token found");
        return null;
      }*/

      final url = Uri.parse("${baseURL.Urls().baseURL}user/download/$imageId");
      print("📡 Fetching image from: $url");
      
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      print("📊 Image response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        _imageCache[imageId] = bytes;
        print("✅ Image loaded successfully: $imageId (${bytes.length} bytes)");
        return bytes;
      } else {
        print("❌ Failed to load image: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Error loading image: $e");
    }
    _imageCache[imageId] = null;
    return null;
  }

  Future<void> _navigateToDetails(BuildContext context, AdvocateDetailsModel advocate) async {
    NavigationHelper.push(
      context,
      AdvocateDetails(advocateDetailsModel: advocate),
      transitionType: await AnimatedRoute.getRandomSafeAnimation(),
      duration: const Duration(milliseconds: 600),
      curve: Curves.bounceOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (_isLoading) {
      return SizedBox(
        height: widget.showAll ? 400 : 280,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 2,
              ),
              SizedBox(height: 10),
              Text(
                "Loading advocates...",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadAdvocates,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (_advocates.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 40,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 10),
              const Text(
                "No advocates found",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.speciality != null && widget.speciality != 'All Specialities')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "for ${widget.speciality}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final int itemCount = widget.showAll 
        ? _advocates.length 
        : (_advocates.length > 6 ? 6 : _advocates.length);

    final double cardWidth = screenWidth * 0.40;
    final double cardHeight = 260;

    final bool showScrollbar = itemCount > 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔥 Scrollbar সহ ListView
        Container(
          height: cardHeight + 20,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: showScrollbar,
            trackVisibility: showScrollbar,
            thickness: 6,
            radius: const Radius.circular(10),
            child: ListView.builder(
              key: ValueKey(widget.speciality ?? 'all'),
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: itemCount,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                final AdvocateDetailsModel advocate = _advocates[index];

                return Container(
                  width: cardWidth,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      _navigateToDetails(context, advocate);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Profile Image
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: FutureBuilder<Uint8List?>(
                              key: ValueKey(advocate.profileImageId ?? 'no_image_$index'),
                              future: fetchProfileImage(advocate.profileImageId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  // 🔥 const সরিয়ে দেওয়া হয়েছে
                                  return CircleAvatar(
                                    radius: 35,
                                    backgroundColor: Colors.grey.shade200,
                                    child: const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  );
                                }
                                
                                if (snapshot.hasData && snapshot.data != null) {
                                  return CircleAvatar(
                                    radius: 35,
                                    backgroundImage: MemoryImage(snapshot.data!),
                                  );
                                }
                                
                                // 🔥 Error বা No Image হলে ডিফল্ট দেখান - const সরিয়ে দেওয়া হয়েছে
                                return CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.grey.shade200,
                                  child: Icon(
                                    Icons.person,
                                    size: 35,
                                    color: Colors.grey.shade400,
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 10),
                          
                          // Name
                          Text(
                            advocate.fullName ?? advocate.name ?? "Unknown",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 2),
                          
                          // District
                          if (advocate.district != null && advocate.district!.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.grey.shade600,
                                  size: 10,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  advocate.district!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          
                          const SizedBox(height: 6),
                          
                          // Rating
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.amber.shade200,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  advocate.rating.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        // 🔥 স্ক্রল ইন্ডিকেটর লাইন
        if (showScrollbar && _scrollController.hasClients)
          Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: (_scrollController.position.pixels / 
                      _scrollController.position.maxScrollExtent) * 
                      (MediaQuery.of(context).size.width - 24),
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade400,
                    Colors.green.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}