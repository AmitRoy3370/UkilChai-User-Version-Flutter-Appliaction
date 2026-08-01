// ChatWebSocketService.dart - Fixed Edit/Delete JSON Keys

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/html.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ChatWebSocketService {
  static final ChatWebSocketService _instance = ChatWebSocketService._internal();
  factory ChatWebSocketService() => _instance;
  ChatWebSocketService._internal();

  WebSocketChannel? _channel;
  String? _currentUserId;
  String? _currentOtherUserId;
  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  
  // Callbacks
  Function(Map<String, dynamic>)? onMessage;
  Function(Map<String, dynamic>)? onMessageEdit;
  Function(String)? onMessageDelete;
  Function(String, bool)? onTyping;
  Function(String, bool)? onOnlineStatus;
  Function(bool)? onConnectionChanged;

  // ==================== WebSocket সংযোগ ====================

  Future<void> connect(String userId, {String? otherUserId}) async {
    if (_isConnecting) {
      print('⚠️ Already connecting...');
      return;
    }

    if (_isConnected && _currentUserId == userId) {
      print('✅ Already connected for user: $userId');
      return;
    }

    _isConnecting = true;
    _currentUserId = userId;
    _currentOtherUserId = otherUserId;

    try {
      print('🔌 Connecting to WebSocket for user: $userId');

      await _closeConnection();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null) {
        print('❌ No authentication token found');
        _isConnecting = false;
        return;
      }

      final String wsUrl = 'wss://ukilchai.abrdns.com/ws';
      
      print('🔌 WebSocket URL: $wsUrl');
      print('🔑 Token: ${token.substring(0, 20)}...');

      if (kIsWeb) {
        _channel = HtmlWebSocketChannel.connect(wsUrl);
        print('🌐 Using HTML WebSocket for web');
      } else {
        _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
        print('📱 Using IO WebSocket for mobile');
      }

      _channel!.stream.listen(
        _handleIncomingMessage,
        onError: (error) {
          print('❌ WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('🔌 WebSocket connection closed');
          _handleDisconnection();
        },
        cancelOnError: false,
      );

      await Future.delayed(const Duration(milliseconds: 500));
      
      _sendAuthMessage(token, userId);
      
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      onConnectionChanged?.call(true);
      _startHeartbeat();
      
      print('✅ WebSocket connected successfully for user: $userId');

    } catch (e) {
      print('❌ WebSocket connection error: $e');
      _isConnecting = false;
      _handleDisconnection();
    }
  }

  // ==================== Authentication ====================

  void _sendAuthMessage(String token, String userId) {
    if (_channel == null) return;

    final authMessage = jsonEncode({
      'type': 'auth',
      'token': token,
      'userId': userId,
    });

    _channel!.sink.add(authMessage);
    print('📤 Auth message sent');
  }

  // ==================== ইনকামিং মেসেজ হ্যান্ডেল ====================

  void _handleIncomingMessage(dynamic message) {
    try {
      String messageStr = message.toString().trim();
      
      if (messageStr == 'h' || messageStr == '\n' || messageStr.isEmpty || messageStr == 'ping' || messageStr == 'pong') {
        print('💓 Heartbeat received');
        return;
      }

      if (!messageStr.startsWith('{')) {
        print('📨 Server Plain-Text ACK received: $messageStr');
        return; 
      }

      print('📨 Received JSON: ${messageStr.substring(0, messageStr.length > 200 ? 200 : messageStr.length)}...');

      final data = jsonDecode(messageStr);
      _processMessage(data);

    } catch (e) {
      print('❌ Error handling message: $e');
    }
  }

  void _processMessage(Map<String, dynamic> data) {
    print('📦 Processing: $data');
    
    final type = data['type'] ?? '';
    
    switch (type) {
      case 'message':
      case 'chat':
        if (data.containsKey('data')) {
          onMessage?.call(data['data']);
        } else {
          onMessage?.call(data);
        }
        break;
        
      case 'edit':
        if (data.containsKey('data')) {
          onMessageEdit?.call(data['data']);
        } else {
          onMessageEdit?.call(data);
        }
        break;
        
      case 'delete':
        if (data.containsKey('data')) {
          onMessageDelete?.call(data['data']['id'] ?? '');
        } else {
          onMessageDelete?.call(data['id'] ?? '');
        }
        break;
        
      case 'typing':
        if (data.containsKey('data')) {
          final typingData = data['data'];
          onTyping?.call(
            typingData['sender'] ?? '',
            typingData['typing'] ?? false,
          );
        } else {
          onTyping?.call(
            data['sender'] ?? '',
            data['typing'] ?? false,
          );
        }
        break;
        
      case 'online':
      case 'status':
        if (data.containsKey('data')) {
          onOnlineStatus?.call(
            data['data']['userId'] ?? '',
            data['data']['online'] ?? false,
          );
        } else {
          onOnlineStatus?.call(
            data['userId'] ?? '',
            data['online'] ?? false,
          );
        }
        break;
        
      case 'auth_success':
        print('✅ Authentication successful');
        break;
        
      case 'auth_failed':
        print('❌ Authentication failed: ${data['message']}');
        break;
        
      default:
        if (data.containsKey('sender') || data.containsKey('content') || data.containsKey('message')) {
          onMessage?.call(data);
        } else {
          print('📨 Unknown message type: $type');
        }
    }
  }

  // ==================== মেসেজ পাঠানো ====================

  void sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) {
    if (!_isConnected || _channel == null) {
      print('⚠️ Cannot send: Not connected');
      _connectWithRetry();
      return;
    }

    final message = {
      'type': 'message',
      'sender': senderId,
      'receiver': receiverId,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _sendRawMessage(jsonEncode(message));
    print('📤 Message sent to $receiverId');
  }

  void sendTypingIndicator({
    required String senderId,
    required String receiverId,
    required bool isTyping,
  }) {
    if (!_isConnected) return;

    final message = {
      'type': 'typing',
      'sender': senderId,
      'receiver': receiverId,
      'typing': isTyping,
    };

    _sendRawMessage(jsonEncode(message));
  }

  // 🛠️ FIXED: Changed 'id' to 'messageId' to match Java backend expectations
  void sendEditEvent({
    required String senderId,
    required String receiverId,
    required String messageId,
    required String newContent,
  }) {
    if (!_isConnected) {
      print('⚠️ Cannot send edit: Not connected');
      _connectWithRetry();
      return;
    }

    final message = {
      'type': 'edit',
      'messageId': messageId, // <--- FIXED: Changed from 'id' to 'messageId'
      'sender': senderId,
      'receiver': receiverId,
      'content': newContent,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _sendRawMessage(jsonEncode(message));
    print('✏️ Edit event sent to backend for messageId: $messageId');
  }

  // 🛠️ FIXED: Changed 'id' to 'messageId' to match Java backend expectations
  void sendDeleteEvent({
    required String senderId,
    required String receiverId,
    required String messageId,
  }) {
    if (!_isConnected) {
      print('⚠️ Cannot send delete: Not connected');
      _connectWithRetry();
      return;
    }

    final message = {
      'type': 'delete',
      'messageId': messageId, // <--- FIXED: Changed from 'id' to 'messageId'
      'sender': senderId,
      'receiver': receiverId,
    };

    _sendRawMessage(jsonEncode(message));
    print('🗑️ Delete event sent to backend for messageId: $messageId');
  }

  void _sendRawMessage(String message) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(message);
      } catch (e) {
        print('❌ Error sending raw message: $e');
        _handleDisconnection();
      }
    }
  }

  // ==================== হৃদস্পন্দন ====================

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add('h');
          print('💓 Heartbeat sent');
        } catch (e) {
          print('❌ Heartbeat failed: $e');
          _handleDisconnection();
        }
      } else {
        timer.cancel();
      }
    });
  }

  // ==================== রিকানেক্ট ====================

  void _connectWithRetry() {
    if (_currentUserId != null && !_isConnected) {
      _scheduleReconnect();
    }
  }

  void _handleDisconnection() {
    _isConnected = false;
    _isConnecting = false;
    _heartbeatTimer?.cancel();
    onConnectionChanged?.call(false);

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    } else {
      print('❌ Max reconnection attempts reached');
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    final delay = (2 << _reconnectAttempts).clamp(2, 30);

    print('⏳ Reconnecting in $delay seconds... (attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts)');

    _reconnectTimer = Timer(Duration(seconds: delay), () {
      _reconnectAttempts++;
      if (_currentUserId != null) {
        connect(_currentUserId!, otherUserId: _currentOtherUserId);
      }
    });
  }

  // ==================== ডিসকানেক্ট ====================

  Future<void> _closeConnection() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    if (_channel != null) {
      try {
        await _channel!.sink.close();
      } catch (e) {
        print('⚠️ Error closing connection: $e');
      }
      _channel = null;
    }
  }

  Future<void> disconnect() async {
    print('🔌 Disconnecting WebSocket...');
    await _closeConnection();
    _isConnected = false;
    _isConnecting = false;
    _currentUserId = null;
    _currentOtherUserId = null;
    _reconnectAttempts = 0;
    onConnectionChanged?.call(false);
    print('🔌 WebSocket disconnected');
  }

  // ==================== গেটার ====================

  bool get isConnected => _isConnected && _channel != null;
  bool get isConnecting => _isConnecting;
  String? get currentUserId => _currentUserId;
}