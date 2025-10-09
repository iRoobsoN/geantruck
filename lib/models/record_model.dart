// Em lib/models/record_model.dart

abstract class RecordModel {
  final DateTime date;
  final String createdBy; // <-- ADICIONE ESTA LINHA

  RecordModel({
    required this.date,
    required this.createdBy, // <-- ADICIONE ESTA LINHA
  });
}