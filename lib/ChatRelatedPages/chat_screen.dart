import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:advocatechai/Utils/BaseURL.dart' as BASE_URL;
import 'package:advocatechai/ChatRelatedPages/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SIMPLE WebSocket implementation without STOMP
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class ChatScreen extends StatefulWidget {
  final String? currentUser;
  final String? otherUser;
  final String? othersName;
  final String? myName;

  const ChatScreen({
    Key? key,
    required this.currentUser,
    required this.otherUser,
    required this.othersName,
    required this.myName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isConnected = false;
  bool _isConnecting = false;

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;

  // For Render.com, we need to handle WebSocket differently
  String getWebSocketUrl() {
    String baseUrl = BASE_URL.Urls().baseURL;

    // Render.com specific WebSocket URL construction
    // Convert https:// to wss://
    if (baseUrl.startsWith('https://')) {
      baseUrl = baseUrl.replaceFirst('https://', 'wss://');
    } else if (baseUrl.startsWith('http://')) {
      baseUrl = baseUrl.replaceFirst('http://', 'ws://');
    }

    // Remove /api from the end
    baseUrl = baseUrl.replaceAll('/api/', '/');

    // Ensure no trailing slash
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    // For Render.com, we need to use the SockJS endpoint
    return '$baseUrl/ws/websocket';
  }

  @override
  void initState() {
    super.initState();
    print(
      'ChatScreen initialized for ${widget.currentUser} -> ${widget.otherUser}',
    );
    _loadChatHistory();
    _connectWebSocket();
  }

  Future<void> _loadChatHistory() async {
    try {
      print('Loading chat history...');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final apiBaseUrl = '${BASE_URL.Urls().baseURL}chat';
      final response = await http.get(
        Uri.parse(
          '$apiBaseUrl/history/${widget.currentUser}/${widget.otherUser}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('History response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _messages.addAll(
            data.map((msg) => ChatMessage.fromJson(msg)).toList(),
          );
          _messages.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
        });
        _scrollToBottom();
        print('Loaded ${_messages.length} messages');
      } else {
        print(
          'Failed to load history: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  void _connectWebSocket() {
    if (_isConnecting) {
      print('Already connecting, skipping...');
      return;
    }

    _isConnecting = true;
    _isConnected = false;

    final wsUrl = getWebSocketUrl();
    print('🔄 Connecting to WebSocket: $wsUrl');

    // Close existing connection if any
    _channel?.sink.close();

    try {
      // For SockJS connection, we need to use the full URL
      _channel = IOWebSocketChannel.connect(wsUrl, protocols: ['websocket']);

      // Set up listeners
      _channel!.stream.listen(
        (message) {
          print('📨 Received WebSocket message: $message');
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('⚠️ WebSocket connection closed');
          _handleDisconnection();
        },
      );

      // Set connected state after a short delay
      Future.delayed(Duration(seconds: 2), () {
        if (_channel != null) {
          print('✅ WebSocket connected successfully!');
          setState(() {
            _isConnected = true;
            _isConnecting = false;
          });
        }
      });
    } catch (e) {
      print('❌ Failed to connect to WebSocket: $e');
      _handleDisconnection();
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      // Try to parse as JSON (STOMP messages)
      if (message is String) {
        // Check if it's a STOMP frame
        if (message.startsWith('a[') && message.endsWith(']')) {
          // SockJS message format: a["MESSAGE"]
          final content = message.substring(2, message.length - 1);
          final decoded = jsonDecode(content);

          if (decoded is List && decoded.isNotEmpty) {
            final stompFrame = decoded[0];
            if (stompFrame is String && stompFrame.startsWith('MESSAGE')) {
              // Parse STOMP MESSAGE frame
              _parseStompMessage(stompFrame);
            }
          }
        } else if (message.contains('"sender"') &&
            message.contains('"receiver"')) {
          // Direct JSON message
          final data = jsonDecode(message);
          _addMessageFromData(data);
        }
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  void _parseStompMessage(String stompFrame) {
    try {
      // Simple STOMP frame parsing
      final lines = stompFrame.split('\n');
      String? body;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('{')) {
          body = lines.sublist(i).join('\n');
          break;
        }
      }

      if (body != null) {
        final data = jsonDecode(body);
        _addMessageFromData(data);
      }
    } catch (e) {
      print('Error parsing STOMP frame: $e');
    }
  }

  void _addMessageFromData(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add(ChatMessage.fromJson(data));
        _messages.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
      });
      _scrollToBottom();
    });
  }

  void _handleDisconnection() {
    if (mounted) {
      setState(() {
        _isConnected = false;
        _isConnecting = false;
      });
    }

    // Schedule reconnection
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    print('⏳ Scheduling reconnect in 5 seconds...');
    _reconnectTimer = Timer(Duration(seconds: 5), () {
      print('🔄 Attempting to reconnect...');
      _connectWebSocket();
    });
  }

  void _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    print('📤 Sending message: $message');

    // Try WebSocket first if connected
    if (_isConnected && _channel != null) {
      try {
        // Send as raw JSON (not STOMP)
        final msg = jsonEncode({
          'sender': widget.currentUser,
          'receiver': widget.otherUser,
          'content': message,
        });

        // For SockJS, we need to send in the correct format
        final sockjsMsg = jsonEncode([
          'SEND',
          {
            'destination': '/app/chat.send',
            'content-type': 'application/json',
            'body': msg,
          },
        ]);

        _channel!.sink.add(sockjsMsg);

        print('✅ Message sent via WebSocket');
        _textController.clear();
        _scrollToBottom();
        return;
      } catch (e) {
        print('❌ WebSocket send failed: $e');
      }
    }

    // Fallback to HTTP
    await _sendMessageViaHttp(message);
  }

  Future<void> _sendMessageViaHttp(String message) async {
    try {
      final apiBaseUrl = '${BASE_URL.Urls().baseURL}chat';
      print('📡 Sending via HTTP to: $apiBaseUrl/send');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/send'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sender': widget.currentUser,
          'receiver': widget.otherUser,
          'content': message,
        }),
      );

      print('📡 HTTP response: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _messages.add(ChatMessage.fromJson(data));
          });
          _textController.clear();
          _scrollToBottom();
        });

        print('✅ Message sent via HTTP');
      } else {
        print('❌ HTTP send failed: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ HTTP send error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.othersName}",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.circle : Icons.circle_outlined,
                  color: _isConnected ? Colors.green : Colors.red,
                  size: 12,
                ),
                SizedBox(width: 4),
                if (_isConnecting)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Send a message to start chatting!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.sender == widget.currentUser;
                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isSentByMe) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isSentByMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isSentByMe ? Colors.blue[600] : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isSentByMe)
                  Text(
                    "${widget.othersName}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                SizedBox(height: isSentByMe ? 0 : 2),
                Text(
                  msg.content,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSentByMe ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a').format(msg.timeStamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: isSentByMe ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _textController.text.isNotEmpty
                  ? Colors.blue
                  : Colors.grey[300],
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _textController.text.isNotEmpty ? _sendMessage : null,
            ),
          ),
        ],
      ),
    );
  }

  // Add this to your code before trying to connect
  void testWebSocketEndpoint() async {
    final baseUrl = BASE_URL.Urls().baseURL;

    // Test if the server is reachable
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/history/test/test'),
      );
      print('Server is reachable: ${response.statusCode}');
    } catch (e) {
      print('Server is not reachable: $e');
    }

    // Test WebSocket endpoint (SockJS info)
    try {
      final wsInfo = await http.get(
        Uri.parse('${baseUrl.replaceAll('/api/', '/')}ws/info'),
      );
      print('WebSocket info: ${wsInfo.statusCode} - ${wsInfo.body}');
    } catch (e) {
      print('WebSocket endpoint not accessible: $e');
    }
  }

  // Add these to your ChatScreenState class
  Timer? _pollTimer;
  int _lastMessageCount = 0;

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _checkForNewMessages();
    });
  }

  Future<void> _checkForNewMessages() async {
    try {
      final apiBaseUrl = '${BASE_URL.Urls().baseURL}chat';
      final response = await http.get(
        Uri.parse(
          '$apiBaseUrl/history/${widget.currentUser}/${widget.otherUser}',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.length > _lastMessageCount) {
          setState(() {
            _messages.clear();
            _messages.addAll(
              data.map((msg) => ChatMessage.fromJson(msg)).toList(),
            );
            _messages.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
            _lastMessageCount = data.length;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Polling error: $e');
    }
  }

  // Call _startPolling() in initState instead of _connectWebSocket()
}
