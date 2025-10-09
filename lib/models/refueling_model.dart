import 'package:cloud_firestore/cloud_firestore.dart';
import 'record_model.dart';

class RefuelingModel extends RecordModel {
  final String id;
  final String truckId;
  final double liters;
  final double cost;
  final int odometer; // <-- 1. CAMPO ADICIONADO (KM)

  RefuelingModel({
    required this.id,
    required this.truckId,
    required this.liters,
    required this.cost,
    required this.odometer, // <-- 2. ADICIONADO AO CONSTRUTOR
    required DateTime date,
    required String createdBy,
  }) : super(date: date, createdBy: createdBy);

  factory RefuelingModel.fromFirestore(DocumentSnapshot doc, String truckId) {
    final data = doc.data() as Map<String, dynamic>;
    return RefuelingModel(
      id: doc.id,
      truckId: truckId,
      liters: (data['liters'] as num? ?? 0).toDouble(),
      cost: (data['cost'] as num? ?? 0).toDouble(),
      odometer: data['odometer'] as int? ?? 0, // <-- 3. LIDO DO FIRESTORE
      date: (data['date'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'liters': liters,
      'cost': cost,
      'odometer': odometer, // <-- 4. ADICIONADO PARA SALVAR NO FIRESTORE
      'date': date,
      'createdBy': createdBy,
    };
  }
}