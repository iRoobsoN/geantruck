class ExpenseModel {
  final String id;
  final String truckId;
  final String description;
  final double cost;
  final DateTime date;

  ExpenseModel({
    required this.id,
    required this.truckId,
    required this.description,
    required this.cost,
    required this.date,
  });
}
