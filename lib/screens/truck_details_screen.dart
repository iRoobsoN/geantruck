import 'package:flutter/material.dart';
import '../models/truck_model.dart';
import 'add_record_screen.dart';
import 'stats_screen.dart';

class TruckDetailsScreen extends StatelessWidget {
  final TruckModel truck;

  TruckDetailsScreen({required this.truck});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(truck.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Placa: ${truck.plate}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddRecordScreen(truckId: truck.id),
                  ),
                );
              },
              child: Text('Adicionar Registro'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatsScreen(truckId: truck.id),
                  ),
                );
              },
              child: Text('Ver Estatísticas'),
            ),
          ],
        ),
      ),
    );
  }
}
