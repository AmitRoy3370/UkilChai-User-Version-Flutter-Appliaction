import 'dart:convert';
import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  bool _isActive = false;
  bool _hasInitialized = false;
  Timer? _inactiveTimer;
  Timer? _heartbeatTimer;
  StreamSubscription? _connectivitySubscription;
  bool _isNetworkAvailable = true;

  // ✅ শেষ heartbeat এর সময় ট্র্যাক করা
  DateTime? _lastHeartbeatTime;

  // ✅ ব্যাকগ্রাউন্ডে যাওয়ার সময় ট্র্যাক
  DateTime? _backgroundStartTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadUser();
    _initNetworkMonitor();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactiveTimer?.cancel();
    _heartbeatTimer?.cancel();
    _connectivitySubscription?.cancel();

    if (_hasInitialized && userId != null && token != null) {
      _sendInactiveKeepalive();
    }
    super.dispose();
  }

  Future<void> _initNetworkMonitor() async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      bool isConnected = result != ConnectivityResult.none;
      if (_isNetworkAvailable != isConnected) {
        _isNetworkAvailable = isConnected;
        if (isConnected && !_isActive) {
          setUserActive(true);
        } else if (!isConnected && _isActive) {
          setUserActive(false);
        }
      }
    });

    final result = await Connectivity().checkConnectivity();
    _isNetworkAvailable = result != ConnectivityResult.none;
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("userId");
    token = prefs.getString("jwt_token");
    activeRecordId = prefs.getString("active_record_id");

    if (userId != null && token != null && !_hasInitialized) {
      _hasInitialized = true;
      await setUserActive(true);
      _startHeartbeat(); // ✅ হৃদস্পন্দন শুরু
      setupWebCloseListener();
    }
  }

  // ✅ স্মার্ট হার্টবিট - শুধু প্রয়োজন হলে কল করবে
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    // প্রতি ২ মিনিটে চেক করবে (৩০ সেকেন্ড না)
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      if (!_isActive || !_hasInitialized || !_isNetworkAvailable) return;

      // ✅ শুধু ২ মিনিটের বেশি সময় পার হলে কল করবে
      if (_lastHeartbeatTime == null ||
          DateTime.now().difference(_lastHeartbeatTime!) > const Duration(minutes: 2)) {
        await _updateHeartbeat();
      }
    });
  }

  // ✅ হৃদস্পন্দন আপডেট (শুধুমাত্র প্রয়োজন হলে)
  Future<void> _updateHeartbeat() async {
    if (activeRecordId != null && userId != null && token != null) {
      try {
        final url = Uri.parse("${BASE_URL.Urls().baseURL}user-active/heartbeat/$activeRecordId");
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (response.statusCode == 200) {
          _lastHeartbeatTime = DateTime.now();
          print("💓 Heartbeat sent (${_lastHeartbeatTime})");
        }
      } catch (e) {
        print("💓 Heartbeat failed: $e");
      }
    }
  }

  void _sendInactiveKeepalive() {
    if (!_hasInitialized || userId == null || token == null) return;

    // ✅ ওয়েবের জন্য শুধুমাত্র keepalive (sync কল এড়ানো)
    if (html.window.document.visibilityState == 'hidden') {
      _sendKeepaliveFetch();
    } else {
      _sendInactiveSync();
    }
  }

  void _sendKeepaliveFetch() {
    String url = "${BASE_URL.Urls().baseURL}user-active/add";
    String method = 'POST';
    final body = jsonEncode({"userId": userId, "active": false});

    if (activeRecordId != null) {
      url = "${BASE_URL.Urls().baseURL}user-active/update/$activeRecordId/$userId";
      method = 'PUT';
    }

    try {
      var options = html.HttpRequest.request(url,
        method: method,
        sendData: body,
        requestHeaders: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print("✅ Keepalive sent");
    } catch (e) {
      print("❌ Keepalive failed: $e");
    }
  }

  Future<void> _sendInactiveSync() async {
    if (!_hasInitialized || userId == null || token == null) return;

    try {
      String url;
      final body = jsonEncode({"userId": userId, "active": false});

      if (activeRecordId != null) {
        url = "${BASE_URL.Urls().baseURL}user-active/update/$activeRecordId/$userId";
      } else {
        url = "${BASE_URL.Urls().baseURL}user-active/add";
      }

      await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      ).timeout(const Duration(seconds: 3)); // ✅ 3 সেকেন্ড টাইমআউট
    } catch (e) {
      print("❌ Sync failed: $e");
    }
  }

  Future<void> _performSetUserActive(bool active, String uid, String? t) async {
    try {
      final response = await http.get(
        Uri.parse("${BASE_URL.Urls().baseURL}user-active/user/$uid"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $t',
        },
      ).timeout(const Duration(seconds: 5));

      String? recordId;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        recordId = body["id"].toString();
        await UserActiveService.updateUserActive(recordId, uid, active, t);
      } else {
        await UserActiveService.addUserActive(uid, active, t);

        final newResp = await http.get(
          Uri.parse("${BASE_URL.Urls().baseURL}user-active/user/$uid"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $t',
          },
        ).timeout(const Duration(seconds: 5));

        if (newResp.statusCode == 200) {
          recordId = jsonDecode(newResp.body)["id"].toString();
        }
      }

      if (recordId != null) {
        activeRecordId = recordId;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('active_record_id', recordId);
      }
    } catch (e) {
      print("🔄 _performSetUserActive error: $e");
    }
  }

  Future<void> setUserActive(bool active) async {
    if (_isActive == active) return;
    if (!_isNetworkAvailable && active) return;

    _isActive = active;
    _inactiveTimer?.cancel();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? t = token ?? prefs.getString('jwt_token');
      String? uid = userId ?? prefs.getString('userId');
      if (uid == null || t == null) return;

      if (!active) {
        // ✅ 3 সেকেন্ড ডিলে (ব্যাকগ্রাউন্ডে দ্রুত সুইচিং হ্যান্ডেল করতে)
        _inactiveTimer = Timer(const Duration(seconds: 3), () async {
          await _performSetUserActive(false, uid, t);
          _heartbeatTimer?.cancel();
        });
      } else {
        await _performSetUserActive(true, uid, t);
        // ✅ ব্যাকগ্রাউন্ড থেকে ফিরলে heartbeat রিসেট
        _lastHeartbeatTime = DateTime.now();
        _startHeartbeat();
      }
    } catch (e) {
      print("🎯 setUserActive error: $e");
    }
  }

  void setupWebCloseListener() {
    html.window.onBeforeUnload.listen((event) {
      _sendKeepaliveFetch();
    });

    html.document.onVisibilityChange.listen((event) {
      if (_hasInitialized) {
        if (html.document.visibilityState == 'hidden') {
          _sendKeepaliveFetch();
        } else if (html.document.visibilityState == 'visible') {
          setUserActive(true);
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_hasInitialized || userId == null || token == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        setUserActive(true);
        break;
      case AppLifecycleState.paused:
        setUserActive(false);
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        setUserActive(false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}