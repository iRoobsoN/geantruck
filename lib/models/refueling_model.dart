import 'record_model.dart';

class RefuelingModel extends RecordModel {
  final String id;
  final String truckId;
  final double liters;
  final double cost;

  RefuelingModel({
    required this.id,
    required this.truckId,
    required this.liters,
    required this.cost,
    required DateTime date,
  }) : super(date: date);
}
