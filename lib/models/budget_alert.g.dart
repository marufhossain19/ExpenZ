part of 'budget_alert.dart';

class BudgetAlertAdapter extends TypeAdapter<BudgetAlert> {
  @override
  final int typeId = 3;

  @override
  BudgetAlert read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BudgetAlert(
      id: fields[0] as String,
      limitId: fields[1] as String,
      message: fields[2] as String,
      level: fields[3] as int,
      amountSpent: fields[4] as double,
      amountLimit: fields[5] as double,
      category: fields[6] as String?,
      isFamily: fields[7] as bool,
      timestamp: fields[8] as DateTime,
      isDismissed: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetAlert obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.limitId)
      ..writeByte(2)..write(obj.message)
      ..writeByte(3)..write(obj.level)
      ..writeByte(4)..write(obj.amountSpent)
      ..writeByte(5)..write(obj.amountLimit)
      ..writeByte(6)..write(obj.category)
      ..writeByte(7)..write(obj.isFamily)
      ..writeByte(8)..write(obj.timestamp)
      ..writeByte(9)..write(obj.isDismissed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetAlertAdapter && typeId == other.typeId;
}
