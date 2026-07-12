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

class AdvocateList extends StatelessWidget {
  String? speciality;
  AdvocateList({super.key, this.speciality});

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

    final uri = speciality == null 
        ? Uri.parse("${baseURL.Urls().baseURL}advocate/all") 
        : Uri.parse("${baseURL.Urls().baseURL}advocate/search/speciality/${speciality}");

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
        ..district = advocateDecoded['district'];

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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text(
          "Top Advocates",
          style: TextStyle(
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
      ),
      body: FutureBuilder<List<dynamic>>(
        future: getAdvocateList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
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
            );
          }

          if (snapshot.hasError) {
            if (snapshot.error.toString().contains("PLEASE_LOGIN_FIRST")) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 80,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Please Log In",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Log in first to view advocate data",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LogIn()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          "Log In",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Center(
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
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          }

          final advocates = snapshot.data!;

          if (kDebugMode) {
            print("advocates :- $advocates");
          }

          if (advocates.isEmpty) {
            return Center(
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
            );
          }

          return SingleChildScrollView(
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
                            "${advocates.length} Lawyers",
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
                
                // Grid of advocates
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: advocates.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final AdvocateDetailsModel advocate = advocates[index];
                    final gradient = _getCardGradient(index);

                    return GestureDetector(
                      onTap: () {
                        _navigateToDetails(context, advocate);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradient,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.last.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Card content
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Profile Image with border
                                  Container(
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
                                            radius: 45,
                                            backgroundColor: Colors.white,
                                            child: Icon(
                                              Icons.person,
                                              size: 45,
                                              color: Colors.grey,
                                            ),
                                          );
                                        }
                                        return CircleAvatar(
                                          radius: 45,
                                          backgroundImage: MemoryImage(
                                            snapshot.data!,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Name
                                  Text(
                                    advocate.name ?? "Unknown",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 4,
                                          color: Colors.black26,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  const SizedBox(height: 4),
                                  
                                  // District with icon
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: Colors.white.withOpacity(0.8),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          advocate.district ?? 'No district',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Experience badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.work_history,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${advocate.experience ?? 0} yrs exp",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Specialities
                                  if (advocate.advocateSpeciality != null && 
                                      advocate.advocateSpeciality!.isNotEmpty)
                                    Column(
                                      children: [
                                        ...advocate.advocateSpeciality!
                                            .take(2)
                                            .map((speciality) => Container(
                                                  margin: const EdgeInsets.only(bottom: 3),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    speciality,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                )),
                                        if (advocate.advocateSpeciality!.length > 2)
                                          Text(
                                            "+${advocate.advocateSpeciality!.length - 2} more",
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                      ],
                                    ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // View details button
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      "View Profile",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Animated gradient overlay on hover/tap
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                  ),
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 14,
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
          );
        },
      ),
    );
  }
}