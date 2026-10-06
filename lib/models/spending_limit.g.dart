part of 'spending_limit.dart';

class SpendingLimitAdapter extends TypeAdapter<SpendingLimit> {
  @override
  final int typeId = 2;

  @override
  SpendingLimit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SpendingLimit(
      id: fields[0] as String,
      type: fields[1] as int,
      amount: fields[2] as double,
      category: fields[3] as String?,
      isFamily: fields[4] as bool,
      isEnabled: fields[5] as bool,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SpendingLimit obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.type)
      ..writeByte(2)..write(obj.amount)
      ..writeByte(3)..write(obj.category)
      ..writeByte(4)..write(obj.isFamily)
      ..writeByte(5)..write(obj.isEnabled)
      ..writeByte(6)..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpendingLimitAdapter && typeId == other.typeId;
}
