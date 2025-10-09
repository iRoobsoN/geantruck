// Em lib/models/maintenance_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
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
    required String createdBy, // <-- ADICIONE ESTE PARÂMETRO
  }) : super(date: date, createdBy: createdBy); // <-- PASSE PARA A CLASSE PAI

  // MÉTODO PARA CRIAR A PARTIR DO FIRESTORE
  factory MaintenanceModel.fromFirestore(DocumentSnapshot doc, String truckId) {
    final data = doc.data() as Map<String, dynamic>;
    return MaintenanceModel(
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