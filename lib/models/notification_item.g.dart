part of 'notification_item.dart';

class NotificationItemAdapter extends TypeAdapter<NotificationItem> {
  @override
  final int typeId = 4;

  @override
  NotificationItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationItem(
      id: fields[0] as String,
      title: fields[1] as String,
      body: fields[2] as String,
      type: fields[3] as int,
      isRead: fields[4] as bool,
      timestamp: fields[5] as DateTime,
      relatedEmail: fields[6] as String?,
      inviteStatus: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.title)
      ..writeByte(2)..write(obj.body)
      ..writeByte(3)..write(obj.type)
      ..writeByte(4)..write(obj.isRead)
      ..writeByte(5)..write(obj.timestamp)
      ..writeByte(6)..write(obj.relatedEmail)
      ..writeByte(7)..write(obj.inviteStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationItemAdapter && typeId == other.typeId;
}
