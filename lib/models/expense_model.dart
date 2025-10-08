import 'record_model.dart';

class ExpenseModel extends RecordModel {
  final String id;
  final String truckId;
  final String description;
  final double cost;

  ExpenseModel({
    required this.id,
    required this.truckId,
    required this.description,
    required this.cost,
    required DateTime date,
  }) : super(date: date);
}
