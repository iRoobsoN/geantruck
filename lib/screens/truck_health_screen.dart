// Em lib/screens/truck_health_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/refueling_model.dart';
import '../services/firestore_service.dart';

// Classe auxiliar para armazenar os resultados do cálculo
class FuelEfficiencyRecord {
  final DateTime date;
  final double kmPerLiter;
  final int kmTraveled;
  final double litersUsed;

  FuelEfficiencyRecord({
    required this.date,
    required this.kmPerLiter,
    required this.kmTraveled,
    required this.litersUsed,
  });
}

class TruckHealthScreen extends StatelessWidget {
  final String ownerId;
  final String truckId;

  const TruckHealthScreen({
    super.key,
    required this.ownerId,
    required this.truckId,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: StreamBuilder<List<RefuelingModel>>(
        stream: firestoreService.getRefuelingsForTruck(ownerId, truckId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.length < 2) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'São necessários pelo menos dois registros de abastecimento com quilometragem para calcular a eficiência.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          // A lista vem ordenada do mais recente para o mais antigo.
          final refuelings = snapshot.data!;
          final List<FuelEfficiencyRecord> efficiencyRecords = [];

          // Calcula a eficiência entre cada par de abastecimentos.
          for (int i = 0; i < refuelings.length - 1; i++) {
            final currentRefuel = refuelings[i];
            final previousRefuel = refuelings[i + 1];

            // Garante que o cálculo seja válido
            if (currentRefuel.odometer > previousRefuel.odometer && currentRefuel.liters > 0) {
              final kmTraveled = currentRefuel.odometer - previousRefuel.odometer;
              // Usamos os litros do abastecimento ATUAL para calcular a eficiência do trecho ANTERIOR.
              final litersUsed = currentRefuel.liters; 
              final kmPerLiter = kmTraveled / litersUsed;

              efficiencyRecords.add(FuelEfficiencyRecord(
                date: currentRefuel.date,
                kmPerLiter: kmPerLiter,
                kmTraveled: kmTraveled,
                litersUsed: litersUsed,
              ));
            }
          }

          if (efficiencyRecords.isEmpty) {
             return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Não foi possível calcular a eficiência. Verifique se os dados de quilometragem e litros estão corretos e em ordem crescente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          // Calcula a média geral
          final double averageKmL = efficiencyRecords.map((e) => e.kmPerLiter).reduce((a, b) => a + b) / efficiencyRecords.length;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: efficiencyRecords.length + 1, // +1 para o card da média
            itemBuilder: (context, index) {
              if (index == 0) {
                // O primeiro item é o card da média geral.
                return _buildAverageCard(averageKmL);
              }
              
              final record = efficiencyRecords[index - 1];
              return _buildEfficiencyCard(record);
            },
          );
        },
      ),
    );
  }

  Widget _buildAverageCard(double averageKmL) {
    return Card(
      elevation: 4,
      color: Colors.blue.shade800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Média de Consumo',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              '${averageKmL.toStringAsFixed(2)} km/L',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyCard(FuelEfficiencyRecord record) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.kmPerLiter.toStringAsFixed(2)} km/L',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMd('pt_BR').format(record.date),
                  style: TextStyle(color: Colors.grey[600]),
                )
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${record.kmTraveled} km percorridos',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'com ${record.litersUsed.toStringAsFixed(2)} L',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}