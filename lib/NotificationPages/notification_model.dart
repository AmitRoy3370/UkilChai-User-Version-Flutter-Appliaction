// notification_model.dart
class NotificationModel {
  final String id;
  final String userId;
  final String message;
  final bool isRead;
  final DateTime timeStamp;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.message,
    required this.isRead,
    required this.timeStamp,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      message: json['message'],
      isRead: json['read'] ?? false,
      timeStamp: DateTime.parse(json['timeStamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'message': message,
      'read': isRead,
      'timeStamp': timeStamp.toIso8601String(),
    };
  }
}