import 'record_model.dart';

class MaintenanceModel extends RecordModel {
  final String id;
  final String truckId;
  final String description;
  final double cost;

  MaintenanceModel({
    required this.id,
    required this.truckId,
    required this.description,
    required this.cost,
    required DateTime date,
  }) : super(date: date);
}
