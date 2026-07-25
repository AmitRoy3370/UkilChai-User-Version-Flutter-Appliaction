import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:advocatechai/Utils/BaseURL.dart' as baseURL;
import 'Gender.dart';
import 'UserGender.dart';
import 'UserGenderService.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController googlePasswordController = TextEditingController();
  final TextEditingController confirmGooglePasswordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationTextController = TextEditingController();

  bool _showPassword = false;
  bool _showGooglePassword = false;
  bool _showConfirmGooglePassword = false;
  Gender? _selectedGender;
  bool _isGoogleSignInLoading = false;
  bool _showSuccessMessage = false;

  lat_lng.LatLng? _devicePosition;
  lat_lng.LatLng? _selectedPosition;
  String? _selectedPlaceName;
  List<Marker> _markers = [];
  bool showForm = false;
  File? pickedImage;
  Uint8List? webImageBytes;
  double lattitude = 0.0;
  double longititude = 0.0;

  final MapController mapController = MapController();
  final UserGenderService _userGenderService = UserGenderService();
  late GoogleSignIn _googleSignIn;

  Stream<Position>? _positionStream;

  static const String _webClientId = '556137802637-se4ttcor4s9hnqsmacaeo4f96uvl8955.apps.googleusercontent.com';

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
    _startLocationUpdates();
  }

  // Initialize Google Sign-In with client ID
  void _initializeGoogleSignIn() {
    if (kIsWeb) {
      _googleSignIn = GoogleSignIn(
        clientId: _webClientId,
        scopes: ['email', 'profile', 'openid'],
      );
    } else {
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile', 'openid'],
      );
    }
  }

  void _startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location service")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied forever")),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    );
    _updateDevicePosition(position);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );

    _positionStream!.listen((Position position) {
      _updateDevicePosition(position);
    });
  }

  Future<void> _updateDevicePosition(Position position) async {
    lat_lng.LatLng newPos = lat_lng.LatLng(
      position.latitude,
      position.longitude,
    );
    String placeName = await getAddressFromLatLng(
      position.latitude,
      position.longitude,
    );

    setState(() {
      _devicePosition = newPos;
      if (_selectedPosition == null) {
        _selectedPosition = newPos;
        _selectedPlaceName = placeName;
        lattitude = position.latitude;
        longititude = position.longitude;
        locationTextController.text = placeName;
      }
      _updateMarkers();
    });

    if (_selectedPosition == newPos) {
      mapController.move(newPos, 15.0);
    }
  }

  void _updateMarkers() {
    _markers = [];
    if (_devicePosition != null) {
      _markers.add(
        Marker(
          width: 80,
          height: 80,
          point: _devicePosition!,
          child: const Icon(Icons.my_location, color: Colors.red, size: 40),
        ),
      );
    }
    if (_selectedPosition != null && _selectedPosition != _devicePosition) {
      _markers.add(
        Marker(
          width: 80,
          height: 80,
          point: _selectedPosition!,
          child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
        ),
      );
    }
  }

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'AdvocateChaiApp/1.0'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'] ?? 'Unknown location';
      }
    } catch (e) {
      if (kDebugMode) print('Geocoding error: $e');
    }
    return 'Lat: $lat, Lng: $lng';
  }

  Future<void> searchPlace() async {
    String query = searchController.text.trim();
    if (query.isEmpty) return;

    lat_lng.LatLng? pos;

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'AdvocateChaiApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          double lat = double.parse(data[0]['lat']);
          double lng = double.parse(data[0]['lon']);
          lattitude = lat;
          longititude = lng;
          pos = lat_lng.LatLng(lat, lng);
          String name = data[0]['display_name'];
          setState(() {
            _selectedPosition = pos;
            _selectedPlaceName = name;
            locationTextController.text = _selectedPlaceName!;
            _updateMarkers();
          });
          mapController.move(pos, 15.0);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Search error: $e');
    }

    if (pos == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No results found")));
    }
  }

  Future<void> pickImage() async {
    XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      if (kIsWeb) {
        webImageBytes = await file.readAsBytes();
        pickedImage = File(file.path);
      } else {
        pickedImage = File(file.path);
      }
      setState(() {});
    }
  }

  // ============ NAVIGATION HELPER METHOD ============
  void _navigateToHomePage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MyHomePage(title: 'উকিল চাই')),
      (route) => false,
    );
    
    // Refresh home page data after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      homePageKey.currentState?.refreshUserData();
    });
  }

  // ============ GOOGLE SIGN-IN WITH PASSWORD ============
  Future<void> _signInWithGoogle() async {
    // Validate password first
    if (googlePasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a password")),
      );
      return;
    }

    if (googlePasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    if (googlePasswordController.text != confirmGooglePasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() {
      _isGoogleSignInLoading = true;
      _showSuccessMessage = false;
    });

    try {
      // Step 1: Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isGoogleSignInLoading = false;
        });
        return;
      }

      // Step 2: Get user data from Google
      final String? email = googleUser.email;
      final String? displayName = googleUser.displayName;
      final String? photoUrl = googleUser.photoUrl;

      if (email == null) {
        throw Exception('Could not get email from Google');
      }

      print('✅ Email: $email');
      print('✅ Display Name: $displayName');

      // Step 3: Get authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      print('🔑 ID Token: ${idToken != null ? 'Received' : 'Not received'}');
      print('🔑 Access Token: ${accessToken != null ? 'Received' : 'Not received'}');

      // Step 4: Use access token to get user info from Google API
      if (accessToken != null) {
        try {
          // Get user info using access token
          final userInfoResponse = await http.get(
            Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          );

          if (userInfoResponse.statusCode == 200) {
            final userInfo = jsonDecode(userInfoResponse.body);
            print('✅ User info retrieved: ${userInfo['email']}');
            
            // Register user with the information
            await _registerUser(
              email: userInfo['email'] ?? email,
              displayName: userInfo['name'] ?? displayName,
              photoUrl: userInfo['picture'] ?? photoUrl,
              accessToken: accessToken,
            );
            
            // Show success message after successful registration
            setState(() {
              _showSuccessMessage = true;
            });
            
            // ✅ Navigate to HomePage after successful registration
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                _navigateToHomePage();
              }
            });
            return;
          } else {
            print('⚠️ Failed to get user info: ${userInfoResponse.statusCode}');
          }
        } catch (e) {
          print('⚠️ Error getting user info: $e');
        }
      }

      // If we have an ID token, use it as fallback
      if (idToken != null) {
        await _registerUser(
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
          accessToken: accessToken,
          idToken: idToken,
        );
        setState(() {
          _showSuccessMessage = true;
        });
        
        // ✅ Navigate to HomePage
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _navigateToHomePage();
          }
        });
      } else {
        // If we only have access token, use that
        if (accessToken != null) {
          await _registerUser(
            email: email,
            displayName: displayName,
            photoUrl: photoUrl,
            accessToken: accessToken,
          );
          setState(() {
            _showSuccessMessage = true;
          });
          
          // ✅ Navigate to HomePage
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              _navigateToHomePage();
            }
          });
        } else {
          throw Exception('No authentication token available');
        }
      }
      
    } catch (e) {
      print('Google Sign-In error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleSignInLoading = false;
        });
      }
    }
  }

  // ============ REGISTER USER WITH TOKENS ============
  Future<void> _registerUser({
    required String email,
    required String? displayName,
    required String? photoUrl,
    String? accessToken,
    String? idToken,
  }) async {
    // Download profile picture if available
    Uint8List? profileImageBytes;
    if (photoUrl != null) {
      try {
        final response = await http.get(Uri.parse(photoUrl));
        if (response.statusCode == 200) {
          profileImageBytes = response.bodyBytes;
        }
      } catch (e) {
        print('Failed to download profile image: $e');
      }
    }

    // Register user with the provided password
    final registrationUri = Uri.parse("${baseURL.Urls().baseURL}auth/register");

    // Generate username from email
    final String userName = email.split('@').first;
    final String fullName = displayName ?? userName;

    // Create multipart request for registration
    var request = http.MultipartRequest("POST", registrationUri);

    // Add user data with the provided password
    request.fields["name"] = userName;
    request.fields["FullName"] = fullName;
    request.fields["password"] = googlePasswordController.text;
    request.fields["profileImageId"] = "profileImageId";

    // Add profile picture if available
    if (profileImageBytes != null && profileImageBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          profileImageBytes,
          filename: '$userName.png',
          contentType: http.MediaType('image', 'png'),
        ),
      );
    }

    // Send registration request
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(responseBody);
      final String token = decoded["token"];
      final String userId = decoded["userId"];

      // Save tokens and user info
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("jwt_token", token);
      await prefs.setString("userId", userId);
      await prefs.setString("userEmail", email);
      await prefs.setString("userName", userName);
      await prefs.setString("fullName", fullName);

      // ============ ADD CONTACT INFO ============
      String contactInfoUri = "${baseURL.Urls().baseURL}user/contact-info/add?userId=$userId";
      final url = Uri.parse(contactInfoUri);

      if (email.isNotEmpty) {
        final responseForContactInfo = await http.post(
          url,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "userId": userId,
            "email": email,
            "phone": null,
          }),
        );

        if (responseForContactInfo.statusCode == 200 || responseForContactInfo.statusCode == 201) {
          print('✅ Contact info added successfully');
        } else {
          print('❌ Contact info not added');
        }
      }

      // ============ ADD LOCATION ============
      if (locationTextController.text.isNotEmpty) {
        final String locationUrl = "${baseURL.Urls().baseURL}userLocation/add";
        final location = Uri.parse(locationUrl);

        final responseForLocation = await http.post(
          location,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "userId": userId,
            "locationName": locationTextController.text.trim(),
            "lattitude": lattitude,
            "longitude": longititude,
          }),
        );

        if (responseForLocation.statusCode == 200 || responseForLocation.statusCode == 201) {
          print('✅ Location added successfully');
        }
      }

      // Show success SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Google Sign-In Successful! Welcome to Ukil Chai!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

    } else {
      throw Exception('Registration failed: $responseBody');
    }
  }

  // ============ REGULAR REGISTRATION ============
  Future<void> _submitForm() async {
    try {
      final uri = Uri.parse("${baseURL.Urls().baseURL}auth/register");

      if (fullNameController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please enter fullName")));
        return;
      } else if (nameController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please enter userName")));
        return;
      } else if (passwordController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please enter password")));
        return;
      } else if (_selectedGender == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please select your gender")));
        return;
      } else if (locationTextController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please select location")));
        return;
      }

      var request = http.MultipartRequest("POST", uri);

      request.fields["name"] = nameController.text.trim();
      request.fields["FullName"] = fullNameController.text.trim();
      request.fields["password"] = passwordController.text.trim();
      request.fields["profileImageId"] = "profileImageId";

      if (kIsWeb && webImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            webImageBytes!,
            filename: '${nameController.text.trim()}.png',
            contentType: http.MediaType('image', 'png'),
          ),
        );
      } else if (!kIsWeb && pickedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath("file", pickedImage!.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(responseBody);
        final String token = decoded["token"];
        final String userId = decoded["userId"];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("jwt_token", token);
        await prefs.setString("userId", userId);

        final sharedPreferences = await SharedPreferences.getInstance();
        final _token = sharedPreferences.getString("jwt_token");

        if (_token == null || token.isEmpty) {
          print("No token found. User not logged in.");
          return;
        }

        // ============ ADD GENDER ============
        try {
          final userGender = await _userGenderService.createUserGender(
            userId: userId,
            gender: _selectedGender!,
          );
          print('✅ Gender added successfully: ${userGender.gender}');
        } catch (e) {
          print('❌ Failed to add gender: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save gender: $e')),
          );
        }

        // ============ ADD CONTACT INFO ============
        String contactInfoUri = "${baseURL.Urls().baseURL}user/contact-info/add?userId=$userId";
        final url = Uri.parse(contactInfoUri);

        if (emailController.text.isNotEmpty || phoneController.text.isNotEmpty) {
          final responseForContactInfo = await http.post(
            url,
            headers: {
              "Authorization": "Bearer $_token",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "userId": userId,
              "email": emailController.text.isNotEmpty ? emailController.text.trim() : null,
              "phone": phoneController.text.isNotEmpty ? phoneController.text.trim() : null,
            }),
          );

          if (responseForContactInfo.statusCode == 200 || responseForContactInfo.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Your contact info added successfully...")),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Your contact info not added...")),
            );
          }
        }

        // ============ ADD LOCATION ============
        final String locationUrl = "${baseURL.Urls().baseURL}userLocation/add";
        final loaction = Uri.parse(locationUrl);

        final sharedPreferences1 = await SharedPreferences.getInstance();
        final token1 = sharedPreferences1.getString("jwt_token");

        final responseForContactInfo1 = await http.post(
          loaction,
          headers: {
            "Authorization": "Bearer $token1",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "userId": userId,
            "locationName": locationTextController.text.trim(),
            "lattitude": lattitude,
            "longitude": longititude,
          }),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Successful")),
        );

        setState(() {
          showForm = false;
          _selectedGender = null;
        });

        nameController.clear();
        passwordController.clear();
        emailController.clear();
        phoneController.clear();
        locationTextController.clear();
        pickedImage = null;
        webImageBytes = null;

        // ✅ Navigate to HomePage
        _navigateToHomePage();

      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Registration failed: $responseBody")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ============ SHOW PASSWORD DIALOG ============
  void _showGooglePasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Google Sign-In',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Please set a password for your account.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                // Password Field
                TextField(
                  controller: googlePasswordController,
                  obscureText: !_showGooglePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'At least 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showGooglePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          _showGooglePassword = !_showGooglePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Confirm Password Field
                TextField(
                  controller: confirmGooglePasswordController,
                  obscureText: !_showConfirmGooglePassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmGooglePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          _showConfirmGooglePassword = !_showConfirmGooglePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _signInWithGoogle();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continue with Google'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============ UI COMPONENTS ============

  Widget _buildOpenFormButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Regular Registration Button
        GestureDetector(
          onTap: () {
            setState(() {
              showForm = true;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            transform: Matrix4.identity()..scale(showForm ? 0.0 : 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 1 + (value * 0.1),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.app_registration,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'New Registration',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Google Sign-In Button
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..scale(showForm ? 0.0 : 1.0),
          child: _buildGoogleSignInButton(),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return GestureDetector(
      onTap: _isGoogleSignInLoading ? null : _showGooglePasswordDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isGoogleSignInLoading)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue,
                ),
              )
            else
              Image.network(
                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                height: 24,
                width: 24,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(width: 12),
            Text(
              _isGoogleSignInLoading ? 'Signing in...' : 'Continue with Google',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedForm() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      bottom: showForm ? 0 : -MediaQuery.of(context).size.height,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).size.height * 0.85,
      child: IgnorePointer(
        ignoring: !showForm,
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: showForm ? 1 : 0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, (1 - value) * 100),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.delta.dy > 10) {
                      setState(() {
                        showForm = false;
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.blueAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registration Form',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Fill with your data',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => showForm = false),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      left: 20,
                      right: 20,
                      top: 20,
                    ),
                    child: Column(
                      children: [
                        _buildFormField(
                          controller: fullNameController,
                          label: "Full Name",
                          icon: Icons.person_outline,
                          hint: "Write your full name",
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: nameController,
                          label: "User Name",
                          icon: Icons.person_outline,
                          hint: "Write your user name (unique)",
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: emailController,
                          label: "Email",
                          icon: Icons.email_outlined,
                          hint: "Your mail address",
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: phoneController,
                          label: "Mobile Number",
                          icon: Icons.phone_outlined,
                          hint: "01XXXXXXXXX",
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordField(),
                        const SizedBox(height: 16),
                        _buildGenderSelector(),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: locationTextController,
                          label: "Location",
                          icon: Icons.location_on_outlined,
                          hint: "Select from the map",
                          readOnly: true,
                        ),
                        const SizedBox(height: 20),
                        _buildImagePicker(),
                        const SizedBox(height: 30),
                        _buildSubmitButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ GENDER SELECTOR WIDGET ============
  Widget _buildGenderSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.transgender, color: Colors.blue, size: 22),
              const SizedBox(width: 12),
              const Text(
                "Gender",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: Gender.values.map((gender) {
              final isSelected = _selectedGender == gender;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedGender = gender;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getGenderIcon(gender),
                            color: isSelected ? Colors.white : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            gender.displayName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getGenderIcon(Gender gender) {
    switch (gender) {
      case Gender.MALE:
        return Icons.male;
      case Gender.FEMALE:
        return Icons.female;
      case Gender.OTHER:
        return Icons.transgender;
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.blue),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: passwordController,
        obscureText: !_showPassword,
        decoration: InputDecoration(
          labelText: "Password",
          labelStyle: const TextStyle(color: Colors.blue),
          hintText: "At least 6 characters",
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.blue,
            ),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Profile image",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: pickImage,
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: pickedImage == null && webImageBytes == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        "Add image",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  )
                : kIsWeb
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          webImageBytes!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          pickedImage!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          FocusScope.of(context).unfocus();
          
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Registering...",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Please wait",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          );

          // ✅ Submit the form - this will handle navigation
          await _submitForm();

          // ✅ The loading dialog will automatically close when navigation happens
          // No need to manually pop it
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
        ),
        child: const Text(
          "Registration Complete",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Registration with Map"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Map
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: lat_lng.LatLng(23.8103, 90.4125),
                    initialZoom: 13.0,
                    minZoom: 3.0,
                    maxZoom: 18.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.advocatechai.app',
                    ),
                    MarkerLayer(markers: _markers),
                  ],
                ),
              );
            },
          ),

          // Gradient Overlay
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),

          // Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.blue),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: "Search location...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        onSubmitted: (value) => searchPlace(),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: searchPlace,
                        iconSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // My Location Button
          Positioned(
            bottom: 20,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                if (_devicePosition != null) {
                  setState(() {
                    _selectedPosition = _devicePosition;
                    locationTextController.text = _selectedPlaceName ?? '';
                    _updateMarkers();
                  });
                  mapController.move(_devicePosition!, 15.0);
                }
              },
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          // Open Form Button
          if (!showForm)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: _buildOpenFormButton(),
              ),
            ),

          // Animated Form
          _buildAnimatedForm(),
        ],
      ),
    );
  }
}