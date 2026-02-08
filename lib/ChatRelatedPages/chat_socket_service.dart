import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatWebSocketService {
  static final ChatWebSocketService _instance = ChatWebSocketService._internal();
  factory ChatWebSocketService() => _instance;
  ChatWebSocketService._internal();

  WebSocketChannel? _channel;
  String? _currentUserId;
  bool _isConnected = false;
  int _subscriptionId = 0;

  // Callbacks
  Function(Map<String, dynamic>)? onMessage;
  Function(String, bool)? onTyping;
  Function(String, bool)? onOnlineStatus;

  // Connect to WebSocket with SockJS
  Future<void> connect(String userId) async {
    if (_isConnected && _currentUserId == userId) {
      print('⚠️ Already connected for user: $userId');
      return;
    }

    _currentUserId = userId;

    try {
      print('🔌 Connecting to WebSocket for user: $userId');

      // SockJS endpoint - note: uses /ws-chat from backend config
      final wsUrl = Uri.parse('wss://ukilchaiuserversion.onrender.com/ws-chat/websocket');

      _channel = WebSocketChannel.connect(wsUrl);

      // Wait for connection
      await _channel!.ready;

      // Send STOMP CONNECT frame
      _sendStompFrame('CONNECT', {
        'accept-version': '1.2',
        'heart-beat': '10000,10000',
      });

      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          print('❌ WebSocket error: $error');
          _isConnected = false;
        },
        onDone: () {
          print('⚠️ WebSocket connection closed');
          _isConnected = false;
        },
      );

    } catch (e) {
      print('❌ Failed to connect: $e');
      _isConnected = false;
    }
  }

  void _handleMessage(dynamic data) {
    String message = data.toString();

    if (message.startsWith('CONNECTED')) {
      print('✅ WebSocket connected successfully');
      _isConnected = true;
      _subscribeToUserQueue();
    } else if (message.startsWith('MESSAGE')) {
      _parseStompMessage(message);
    } else if (message.startsWith('ERROR')) {
      print('❌ STOMP error: $message');
    }
  }

  void _subscribeToUserQueue() {
    if (_currentUserId == null) return;

    _subscriptionId++;

    // Subscribe to user's private message queue
    _sendStompFrame('SUBSCRIBE', {
      'id': 'sub-$_subscriptionId',
      'destination': '/user/queue/messages',
    });

    print('📬 Subscribed to /user/queue/messages for user: $_currentUserId');
  }

  void _parseStompMessage(String stompFrame) {
    try {
      // Extract JSON body from STOMP frame
      final lines = stompFrame.split('\n');
      final bodyIndex = lines.indexWhere((line) => line.isEmpty) + 1;

      if (bodyIndex > 0 && bodyIndex < lines.length) {
        final jsonBody = lines.sublist(bodyIndex).join('\n').trim();
        final body = jsonBody.replaceAll('\u0000', ''); // Remove null terminator

        if (body.isNotEmpty) {
          final data = json.decode(body);

          // Check destination to determine message type
          if (stompFrame.contains('/queue/messages')) {
            onMessage?.call(data);
          } else if (stompFrame.contains('/queue/edit')) {
            onMessage?.call(data); // Handle edited messages
          }
        }
      }
    } catch (e) {
      print('❌ Error parsing STOMP message: $e');
    }
  }

  void sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) {
    if (!_isConnected) {
      print('⚠️ Cannot send message: Not connected');
      return;
    }

    final messageBody = json.encode({
      'sender': senderId,
      'receiver': receiverId,
      'content': content,
    });

    _sendStompFrame(
      'SEND',
      {'destination': '/app/chat.send'},
      messageBody,
    );

    print('📤 Message sent to $receiverId');
  }

  void sendTypingIndicator({
    required String senderId,
    required String receiverId,
    required bool isTyping,
  }) {
    if (!_isConnected) return;

    final body = json.encode({
      'sender': senderId,
      'receiver': receiverId,
      'typing': isTyping,
    });

    _sendStompFrame(
      'SEND',
      {'destination': '/app/chat.typing'},
      body,
    );
  }

  void _sendStompFrame(String command, Map<String, String> headers, [String? body]) {
    if (_channel == null) return;

    final frame = StringBuffer();
    frame.writeln(command);

    headers.forEach((key, value) {
      frame.writeln('$key:$value');
    });

    frame.writeln();

    if (body != null) {
      frame.write(body);
    }

    frame.write('\u0000'); // Null terminator

    _channel!.sink.add(frame.toString());
  }

  void disconnect() {
    if (_channel != null) {
      _sendStompFrame('DISCONNECT', {});
      _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    _currentUserId = null;
    print('🔌 WebSocket disconnected');
  }

  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;
}
