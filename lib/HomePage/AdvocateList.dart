import 'dart:convert';
import 'package:advocatechai/AdvocatePages/AdvocateDetailsModel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:advocatechai/Utils/BaseURL.dart' as baseURL;
import '../PageTransition.dart';
import '../LogInPage/LogIn.dart';
import 'package:advocatechai/Auth/AuthService.dart';
import '../AdvocatePages/AdvocateDetails.dart';
import 'package:google_fonts/google_fonts.dart';

class AdvocateList extends StatefulWidget {
  String? speciality;
  AdvocateList({super.key, this.speciality});

  @override
  State<AdvocateList> createState() => _AdvocateListState();
}

class _AdvocateListState extends State<AdvocateList> {
  List<AdvocateDetailsModel> _advocates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdvocates();
  }

  Future<void> _loadAdvocates() async {
    try {
      final advocates = await getAdvocateList();
      setState(() {
        _advocates = advocates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<Uint8List?> fetchProfileImage(String? imageId) async {
    if (imageId == null || imageId.isEmpty) return null;

    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("${baseURL.Urls().baseURL}user/download/$imageId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
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

  Future<List<AdvocateDetailsModel>> getAdvocateList() async {
    final token = await AuthService.getToken();

    final uri = widget.speciality == null 
        ? Uri.parse("${baseURL.Urls().baseURL}advocate/all") 
        : Uri.parse("${baseURL.Urls().baseURL}advocate/search/speciality/${widget.speciality}");

    print("fetching all advocates from $uri");

    final response = await http.get(
      uri,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load advocates");
    }

    print("advocate status code :- ${response.statusCode}");

    final List responseData = jsonDecode(response.body);

    print("advocate response :- $responseData");

    List<AdvocateDetailsModel> list = [];

    for (var item in responseData) {
      final advocateDecoded = item as Map<String, dynamic>;

      print("advocate decoded :- $advocateDecoded");

      final String userId = advocateDecoded["userId"];

      String? email;
      String? phone;

      email = advocateDecoded["email"];
      phone = advocateDecoded["phone"];

      String? locationName;
      double? lat;
      double? lng;

      locationName = advocateDecoded["locationName"];
      lat = advocateDecoded["lattitude"];
      lng = advocateDecoded["longitude"];

      final model = AdvocateDetailsModel.defaultConstructor()
        ..id = advocateDecoded["id"]?.toString()
        ..userId = userId
        ..name = advocateDecoded["name"]?.toString()
        ..fullName = advocateDecoded["name"]?.toString()
        ..profileImageId = advocateDecoded["profileImageId"]?.toString()
        ..experience = (advocateDecoded["experience"] ?? 0)
        ..licenseKey = advocateDecoded["licenseKey"]?.toString()
        ..advocateSpeciality = advocateDecoded["advocateSpeciality"] != null
            ? List<String>.from(
                advocateDecoded["advocateSpeciality"].map((e) => e.toString()))
            : []
        ..degrees = advocateDecoded["degrees"] != null
            ? List<String>.from(
                advocateDecoded["degrees"].map((e) => e.toString()))
            : []
        ..workingExperiences = advocateDecoded["workingExperiences"] != null
            ? List<String>.from(
                advocateDecoded["workingExperiences"].map((e) => e.toString()))
            : []
        ..email = email
        ..phone = phone
        ..locationName = locationName
        ..lattitude = lat != null ? double.tryParse(lat.toString()) : null
        ..longitude = lng != null ? double.tryParse(lng.toString()) : null
        ..contactInfoId = advocateDecoded['contactInfoId']?.toString()
        ..locationId = advocateDecoded['locationId']?.toString()
        ..cvHexKey = advocateDecoded['cvHexKey']?.toString()
        ..district = advocateDecoded['district']
        ..rating = advocateDecoded['rating'] != null 
            ? double.tryParse(advocateDecoded['rating'].toString()) ?? 0.0 
            : 0.0;

      print("advocate model :- $model");

      list.add(model);
    }

    print("all advocates :- $list");

    return list;
  }

  // Helper method to get gradient based on index
  List<Color> _getCardGradient(int index) {
    final gradients = [
      [Color(0xFF667eea), Color(0xFF764ba2)],
      [Color(0xFFf093fb), Color(0xFFf5576c)],
      [Color(0xFF4facfe), Color(0xFF00f2fe)],
      [Color(0xFF43e97b), Color(0xFF38f9d7)],
      [Color(0xFFfa709a), Color(0xFFfee140)],
      [Color(0xFF30cfd0), Color(0xFF330867)],
    ];
    return gradients[index % gradients.length].cast<Color>();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final isTablet = screenWidth > 600 && screenWidth <= 800;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: Text(
          widget.speciality != null 
              ? "Advocates - ${widget.speciality}" 
              : "Featured Advocates",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.purple.shade50,
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Loading advocates...",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _loadAdvocates();
                          },
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              : _advocates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "No advocates found",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats or header
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.blue.shade700,
                                  Colors.purple.shade700,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.shade200.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Available Advocates",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "${_advocates.length} Lawyers",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.gavel,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // ========== 🔥 Advocates Grid ==========
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _advocates.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isDesktop ? 4 : (isTablet ? 3 : 2),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.7,
                            ),
                            itemBuilder: (context, index) {
                              final AdvocateDetailsModel advocate = _advocates[index];
                              final gradient = _getCardGradient(index);

                              return GestureDetector(
                                onTap: () {
                                  _navigateToDetails(context, advocate);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // ========== প্রোফাইল ইমেজ (টপে) ==========
                                      Container(
                                        width: double.infinity,
                                        height: 110,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: gradient,
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 3,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: FutureBuilder<Uint8List?>(
                                              future: fetchProfileImage(
                                                advocate.profileImageId,
                                              ),
                                              builder: (context, snapshot) {
                                                if (!snapshot.hasData) {
                                                  return const CircleAvatar(
                                                    radius: 35,
                                                    backgroundColor: Colors.white,
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 35,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                }
                                                return CircleAvatar(
                                                  radius: 35,
                                                  backgroundImage: MemoryImage(
                                                    snapshot.data!,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // ========== কন্টেন্ট অংশ ==========
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              // নাম
                                              Text(
                                                advocate.name ?? "Unknown",
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              
                                              const SizedBox(height: 2),
                                              
                                              // স্পেশালিটি
                                              if (advocate.advocateSpeciality != null && 
                                                  advocate.advocateSpeciality!.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    advocate.advocateSpeciality!.first,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 9,
                                                      color: Colors.blue.shade700,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              
                                              const SizedBox(height: 4),
                                              
                                              // রেটিং
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 12,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    advocate.rating.toStringAsFixed(1),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.grey.shade700,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    "(${_getRandomReviewCount()} reviews)",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 9,
                                                      color: Colors.grey.shade500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              
                                              const SizedBox(height: 6),
                                              
                                              // "View Profile" বাটন
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: gradient,
                                                  ),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  "View Profile",
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
    );
  }

  // র্যান্ডম রিভিউ কাউন্ট (ডেমোর জন্য)
  int _getRandomReviewCount() {
    final counts = [12, 18, 24, 32, 41, 28, 19, 36, 45, 27, 33, 22];
    return counts[DateTime.now().millisecondsSinceEpoch % counts.length];
  }
}