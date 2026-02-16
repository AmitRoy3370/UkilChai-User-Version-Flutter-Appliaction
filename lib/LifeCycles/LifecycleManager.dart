import 'dart:convert';
import 'dart:html' as html;
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../ChatRelatedPages/user_active_service.dart';
import '../Utils/BaseURL.dart' as BASE_URL;

class LifecycleManager extends StatefulWidget {
  final Widget child;
  const LifecycleManager({super.key, required this.child});

  @override
  State<LifecycleManager> createState() => _LifecycleManagerState();
}

class _LifecycleManagerState extends State<LifecycleManager>
    with WidgetsBindingObserver {

  String? userId;
  String? token;
  String? activeRecordId;
  bool _isActive = false; // Track current active state
  Timer? _inactiveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("userId");
    token = prefs.getString("jwt_token");
    activeRecordId = prefs.getString("active_record_id");

    if (userId != null && token != null) {
      await setUserActive(true);
      setupWebCloseListener();
    }
  }

  // ================== NORMAL SET ACTIVE ==================
  Future<void> setUserActive(bool active) async {
    // Don't do anything if state hasn't changed
    if (_isActive == active) return;

    _isActive = active;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? t = token ?? prefs.getString('jwt_token');
      String? uid = userId ?? prefs.getString('userId');

      if (uid == null || t == null) return;

      // Cancel any pending timer
      _inactiveTimer?.cancel();

      if (!active) {
        // For setting inactive, use a small delay to ensure other operations complete
        _inactiveTimer = Timer(const Duration(milliseconds: 500), () async {
          await _performSetUserActive(false, uid, t);
        });
      } else {
        await _performSetUserActive(true, uid, t);
      }
    } catch (e) {
      print("setUserActive error: $e");
    }
  }

  Future<void> _performSetUserActive(bool active, String uid, String? t) async {
    try {
      final response = await http.get(
        Uri.parse("${BASE_URL.Urls().baseURL}user-active/user/$uid"),
        headers: {
          'content-type': 'application/json',
          'Authorization': 'Bearer $t',
        },
      );

      String? recordId;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        recordId = body["id"].toString();

        await UserActiveService.updateUserActive(recordId, uid, active, t);
      } else {
        await UserActiveService.addUserActive(uid, active, t);

        // Fetch the newly created record
        final newResp = await http.get(
          Uri.parse("${BASE_URL.Urls().baseURL}user-active/user/$uid"),
          headers: {'content-type': 'application/json', 'Authorization': 'Bearer $t'},
        );
        if (newResp.statusCode == 200) {
          recordId = jsonDecode(newResp.body)["id"].toString();
        }
      }

      // Save the record ID
      if (recordId != null) {
        activeRecordId = recordId;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('active_record_id', recordId);
      }
    } catch (e) {
      print("_performSetUserActive error: $e");
    }
  }

  // ================== WEB CLOSE HANDLING ==================
  void setupWebCloseListener() {
    print("✅ Web close listener setup");

    // Using Beacon API for more reliable closing detection
    html.window.onBeforeUnload.listen((event) {
      _sendInactiveBeacon();
    });

    // Also handle page hide
    html.window.onPageHide.listen((event) {
      _sendInactiveBeacon();
    });

    // Handle visibility change
    html.document.onVisibilityChange.listen((event) {
      if (html.document.visibilityState == 'hidden') {
        _sendInactiveBeacon();
      }
    });
  }

  void _sendInactiveBeacon() {
    print("🚨 Browser closing → sending inactive beacon...");

    if (userId == null || token == null) return;

    try {
      String url;
      String method = 'POST';
      final body = jsonEncode({"userId": userId, "active": false});

      if (activeRecordId != null) {
        url = "${BASE_URL.Urls().baseURL}user-active/update/$activeRecordId/$userId";
        method = 'PUT';
      } else {
        url = "${BASE_URL.Urls().baseURL}user-active/add";
      }

      // Create a blob with the data
      final blob = html.Blob([body], 'application/json');

      // Use sendBeacon for reliable sending even when page closes
      bool success = html.window.navigator.sendBeacon(url, blob);

      if (success) {
        print("✅ Beacon sent successfully");
      } else {
        print("❌ Beacon failed, trying sync request");
        _sendInactiveSync();
      }
    } catch (e) {
      print("Beacon error: $e, trying sync request");
      _sendInactiveSync();
    }
  }

  void _sendInactiveSync() {
    try {
      if (userId == null || token == null) return;

      String url;
      String method = 'POST';
      final body = jsonEncode({"userId": userId, "active": false});

      if (activeRecordId != null) {
        url = "${BASE_URL.Urls().baseURL}user-active/update/$activeRecordId/$userId";
        method = 'PUT';
      } else {
        url = "${BASE_URL.Urls().baseURL}user-active/add";
      }

      final request = html.HttpRequest();
      request.open(method, url, async: false);
      request.setRequestHeader('Content-Type', 'application/json');
      request.setRequestHeader('Authorization', 'Bearer $token');
      request.send(body);

      print("✅ Sync inactive request sent");
    } catch (e) {
      print("Sync request failed: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactiveTimer?.cancel();

    if (userId != null && token != null) {
      print("🗑️ App disposing → setting inactive");

      // For mobile, try to send the request
      _performSetUserActive(false, userId!, token);

      // For web, also try beacon
      if (html.window.navigator.userAgent.toLowerCase().contains('web')) {
        _sendInactiveBeacon();
      }
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (userId == null || token == null) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      print("📴 App paused/detached/inactive → inactive");
      setUserActive(false);
    } else if (state == AppLifecycleState.resumed) {
      print("✅ App resumed → active");
      setUserActive(true);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}