import 'package:hive/hive.dart';

part 'notification_item.g.dart';

/// In-app notification item for budget alerts, family events, and AI insights.
@HiveType(typeId: 4)
class NotificationItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String body;

  /// 0=budget, 1=family, 2=insight, 3=invite
  @HiveField(3)
  final int type;

  @HiveField(4)
  bool isRead;

  @HiveField(5)
  final DateTime timestamp;

  /// Optional: email of person related to this notification (family invites)
  @HiveField(6)
  final String? relatedEmail;

  /// Optional: status for invite notifications (pending/accepted/rejected)
  @HiveField(7)
  String? inviteStatus;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.timestamp,
    this.relatedEmail,
    this.inviteStatus,
  });

  String get typeName {
    switch (type) {
      case 0: return 'Budget';
      case 1: return 'Family';
      case 2: return 'Insight';
      case 3: return 'Invite';
      default: return 'Other';
    }
  }
}
