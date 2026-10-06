// GENERATED CODE - Hand-written TypeAdapter for Expense model.
// This avoids the need for build_runner / hive_generator.

part of 'expense.dart';

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 0;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      category: fields[3] as String,
      categoryIcon: fields[4] as int,
      categoryColor: fields[5] as int,
      date: fields[6] as DateTime,
      isIncome: fields[7] as bool,
      note: fields[8] as String?,
      userName: fields[9] as String?,
      isFamily: (fields[10] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(11) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.categoryIcon)
      ..writeByte(5)
      ..write(obj.categoryColor)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.isIncome)
      ..writeByte(8)
      ..write(obj.note)
      ..writeByte(9)
      ..write(obj.userName)
      ..writeByte(10)
      ..write(obj.isFamily);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
