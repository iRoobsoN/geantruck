// Em lib/models/refueling_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
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
    required String createdBy, // <-- ADICIONE ESTE PARÂMETRO
  }) : super(date: date, createdBy: createdBy); // <-- PASSE PARA A CLASSE PAI

  // MÉTODO PARA CRIAR A PARTIR DO FIRESTORE
  factory RefuelingModel.fromFirestore(DocumentSnapshot doc, String truckId) {
    final data = doc.data() as Map<String, dynamic>;
    return RefuelingModel(
      id: doc.id,
      truckId: truckId,
      liters: (data['liters'] as num? ?? 0).toDouble(),
      cost: (data['cost'] as num? ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '', // <-- LEIA O CAMPO DO FIRESTORE
    );
  }

  // MÉTODO PARA SALVAR NO FIRESTORE
  Map<String, dynamic> toFirestore() {
    return {
      'liters': liters,
      'cost': cost,
      'date': date,
      'createdBy': createdBy, // <-- ADICIONE O CAMPO PARA SALVAR
    };
  }
}