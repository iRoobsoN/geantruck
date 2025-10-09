// Em seu arquivo models/truck_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TruckModel {
  final String id;
  final String name;
  final String plate;
  final String ownerId; // <-- ADICIONE ESTA LINHA (dono do caminhão)
  final String? responsibleUserId; // <- ADICIONE ESTA LINHA

  TruckModel({
    required this.id,
    required this.name,
    required this.plate,
    
    required this.ownerId, // <-- ADICIONE ESTA LINHA
    this.responsibleUserId, // <- ADICIONE ESTA LINHA
  });

  // ADICIONE ESTE MÉTODO "FACTORY"
  // Ele converte um documento do Firestore em um objeto TruckModel
  factory TruckModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TruckModel(
      id: doc.id,
      name: data['name'] ?? '',
      plate: data['plate'] ?? '',
      ownerId: data['ownerId'] ?? '', // <-- ADICIONE ESTA LINHA
      responsibleUserId: data['responsibleUserId'], // Lê o ID do responsável
    );
  }

  // ADICIONE ESTE MÉTODO
  // Ele converte o objeto TruckModel em um Mapa para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'plate': plate,
      'ownerId': ownerId, // <-- ADICIONE ESTA LINHA
      'responsibleUserId': responsibleUserId,
    };
  }
}