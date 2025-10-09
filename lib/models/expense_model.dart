// Em lib/models/expense_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
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
    required String createdBy, // <-- ADICIONE ESTE PARÂMETRO
  }) : super(date: date, createdBy: createdBy); // <-- PASSE PARA A CLASSE PAI

  // MÉTODO PARA CRIAR A PARTIR DO FIRESTORE
  factory ExpenseModel.fromFirestore(DocumentSnapshot doc, String truckId) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      truckId: truckId,
      description: data['description'] ?? '',
      cost: (data['cost'] as num? ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '', // <-- LEIA O CAMPO DO FIRESTORE
    );
  }

  // MÉTODO PARA SALVAR NO FIRESTORE
  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'cost': cost,
      'date': date,
      'createdBy': createdBy, // <-- ADICIONE O CAMPO PARA SALVAR
    };
  }
}