import 'package:hive/hive.dart';
import 'plan.dart';

// typeId 0 → PlanVersion
// typeId 1 → DailyProgress
// typeId 2 → PlanRecord
// typeId 3 → FreeHoursSnapshot

class PlanVersionAdapter extends TypeAdapter<PlanVersion> {
  @override
  final int typeId = 0;

  @override
  PlanVersion read(BinaryReader reader) {
    return PlanVersion(
      effectiveFrom: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      name: reader.readString(),
      category: PlanCategory.values[reader.readByte()],
      measureType: MeasureType.values[reader.readByte()],
      target: reader.readDouble(),
      repeatDays: reader.readList().cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, PlanVersion obj) {
    writer.writeInt(obj.effectiveFrom.millisecondsSinceEpoch);
    writer.writeString(obj.name);
    writer.writeByte(obj.category.index);
    writer.writeByte(obj.measureType.index);
    writer.writeDouble(obj.target);
    writer.writeList(obj.repeatDays);
  }
}

class DailyProgressAdapter extends TypeAdapter<DailyProgress> {
  @override
  final int typeId = 1;

  @override
  DailyProgress read(BinaryReader reader) {
    return DailyProgress(
      planId: reader.readString(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      current: reader.readDouble(),
      isCompleted: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, DailyProgress obj) {
    writer.writeString(obj.planId);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeDouble(obj.current);
    writer.writeBool(obj.isCompleted);
  }
}

class FreeHoursSnapshotAdapter extends TypeAdapter<FreeHoursSnapshot> {
  @override
  final int typeId = 3;

  @override
  FreeHoursSnapshot read(BinaryReader reader) {
    return FreeHoursSnapshot(
      effectiveFrom: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      hours: reader.readList().cast<double>(),
    );
  }

  @override
  void write(BinaryWriter writer, FreeHoursSnapshot obj) {
    writer.writeInt(obj.effectiveFrom.millisecondsSinceEpoch);
    writer.writeList(obj.hours);
  }
}

class PlanRecordAdapter extends TypeAdapter<PlanRecord> {
  @override
  final int typeId = 2;

  @override
  PlanRecord read(BinaryReader reader) {
    final id = reader.readString();
    final createdDate = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final hasEndDate = reader.readBool();
    final endDate = hasEndDate
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;
    final count = reader.readInt();
    final versions = List<PlanVersion>.generate(
      count,
      (_) => reader.read() as PlanVersion,
    );
    return PlanRecord(
      id: id,
      createdDate: createdDate,
      endDate: endDate,
      versions: versions,
    );
  }

  @override
  void write(BinaryWriter writer, PlanRecord obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.createdDate.millisecondsSinceEpoch);
    writer.writeBool(obj.endDate != null);
    if (obj.endDate != null) {
      writer.writeInt(obj.endDate!.millisecondsSinceEpoch);
    }
    writer.writeInt(obj.versions.length);
    for (final v in obj.versions) {
      writer.write(v);
    }
  }
}
