class RefuelingModel {
  final String id;
  final String truckId;
  final double liters;
  final double cost;
  final DateTime date;

  RefuelingModel({
    required this.id,
    required this.truckId,
    required this.liters,
    required this.cost,
    required this.date,
  });
}
