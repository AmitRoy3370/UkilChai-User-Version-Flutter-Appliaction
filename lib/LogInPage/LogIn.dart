// LogIn.dart - Fixed version
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Auth/AuthService.dart';
import '../ChatRelatedPages/user_active_service.dart';
import '../RegistrationPage/RegistrationPage.dart';
import 'package:advocatechai/Utils/BaseURL.dart' as baseURL;
import '../DirectorsPages/director_service.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import '../main.dart';
import '../DirectorsPages/director_response.dart';
import '../ShareholderPages/shareholder_service.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<StatefulWidget> createState() {
    return LogInState();
  }
}

class LogInState extends State<LogIn>
    with SingleTickerProviderStateMixin {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isVisible = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // ✅ Drives the continuous rotation of the gradient ring
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // one full rotation every 5s
    )..repeat();
    doesItVisible();
  }

  @override
  void dispose() {
    _spinController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<bool> doesItVisible() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("jwt_token") ?? "";

    if (token.isEmpty) {
      return false;
    }

    String allAthleteURL = "${baseURL.Urls().baseURL}advocate/all";
    Uri uri = Uri.parse(allAthleteURL);

    var response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 403) {
      return false;
    }

    setState(() {
      isVisible = true;
    });

    return true;
  }

  void setUserActive(bool active) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
      String? userId = prefs.getString('userId');
      if (userId != null) {
        final response = await http.get(
          Uri.parse("${BASE_URL.Urls().baseURL}user-active/user/$userId"),
          headers: {
            'content-type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          await UserActiveService.updateUserActive(
            body["id"],
            userId,
            active,
            token,
          );
        } else {
          await UserActiveService.addUserActive(userId, active, token);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _submitForm() async {
    String email = emailController.text;
    String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String loginURL = "${baseURL.Urls().baseURL}auth/login";
    Uri uri = Uri.parse(loginURL);

    var logInResponse = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userName": email, "password": password}),
    );

    setState(() {
      _isLoading = false;
    });

    if (logInResponse.statusCode == 200 || logInResponse.statusCode == 201) {
      final decoded = jsonDecode(logInResponse.body);
      final userId = decoded["userId"];
      final String token = decoded["token"];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("jwt_token", token);
      await prefs.setString("userId", userId);
      String? directorId, holderId;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logged in successfully...")),
      );

      setState(() {
        isVisible = true;
      });

      AuthService.saveToken(token);
      AuthService.saveUserId(userId);
      setUserActive(true);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(
              title: 'উকিল',
              directorId: directorId,
              userId: userId,
              shareHolderId: holderId,
            ),
          ),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(logInResponse.body)),
      );
    }
  }

  // ============================================================
  // ✅ Spinning Badge Logo Builder
  // ============================================================
  Widget _buildSpinningLogo() {
    const double badgeSize = 120;
    const double ringWidth = 4;
    const double innerPadding = 6;

    return SizedBox(
      width: badgeSize,
      height: badgeSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1) Soft green glow (static)
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade700.withOpacity(0.18),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.green.shade200.withOpacity(0.5),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),

          // 2) Rotating gradient ring (the "spinning" part)
          RotationTransition(
            turns: _spinController,
            child: CustomPaint(
              size: const Size(badgeSize, badgeSize),
              painter: _LoginRingPainter(
                ringWidth: ringWidth,
                colors: [
                  Colors.green.shade300,
                  Colors.green.shade700,
                  Colors.lightGreen.shade400,
                  Colors.green.shade700,
                  Colors.green.shade300,
                ],
              ),
            ),
          ),

          // 3) Stationary white inner disk + logo
          Container(
            width: badgeSize - (ringWidth * 2) - (innerPadding * 2),
            height: badgeSize - (ringWidth * 2) - (innerPadding * 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: Colors.green.shade50,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.gavel_rounded,
                  color: Colors.green.shade700,
                  size: 42,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // ✅ Attractive spinning logo badge
              _buildSpinningLogo(),

              const SizedBox(height: 20),
              Text(
                "Welcome Back!",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Login to your account",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: emailController,
                style: GoogleFonts.inter(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Enter your username',
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.person_outline,
                      color: Colors.green.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: !_isPasswordVisible,
                style: GoogleFonts.inter(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.lock_outline,
                      color: Colors.green.shade600),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Login",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.inter(color: Colors.grey.shade600),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegistrationPage()),
                      );

                      if (result == true) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: Text(
                      "Register",
                      style: GoogleFonts.inter(
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Custom painter — draws a smooth gradient ring.
// Rotation is applied externally via RotationTransition.
// ============================================================
class _LoginRingPainter extends CustomPainter {
  final double ringWidth;
  final List<Color> colors;

  _LoginRingPainter({
    required this.ringWidth,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - ringWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Main rotating ring
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: colors,
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        startAngle: 0,
        endAngle: math.pi * 2,
      ).createShader(rect);

    canvas.drawCircle(center, radius, paint);

    // Extra white shine "comet tail" for a premium feel
    final shinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth * 0.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.9),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.04, 0.09],
        startAngle: 0,
        endAngle: math.pi * 2,
      ).createShader(rect);

    canvas.drawCircle(center, radius, shinePaint);
  }

  @override
  bool shouldRepaint(covariant _LoginRingPainter old) {
    return old.ringWidth != ringWidth || old.colors != colors;
  }
}