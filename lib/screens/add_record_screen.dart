import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/maintenance_model.dart';
import '../models/refueling_model.dart';
import '../models/expense_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddRecordScreen extends StatefulWidget {
  final String truckId;

  AddRecordScreen({required this.truckId});

  @override
  _AddRecordScreenState createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _litersController = TextEditingController();
  String _recordType = 'maintenance';

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final user = Provider.of<User?>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Adicionar Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _recordType,
              onChanged: (String? newValue) {
                setState(() {
                  _recordType = newValue!;
                });
              },
              items: <String>['maintenance', 'refueling', 'expense']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            if (_recordType != 'refueling')
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Descrição'),
              ),
            if (_recordType == 'refueling')
              TextField(
                controller: _litersController,
                decoration: InputDecoration(labelText: 'Litros'),
                keyboardType: TextInputType.number,
              ),
            TextField(
              controller: _costController,
              decoration: InputDecoration(labelText: 'Custo'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (user != null) {
                  final cost = double.parse(_costController.text);
                  final date = DateTime.now();

                  if (_recordType == 'maintenance') {
                    await firestoreService.addMaintenance(
                      user.uid,
                      widget.truckId,
                      MaintenanceModel(
                        id: '',
                        truckId: widget.truckId,
                        description: _descriptionController.text,
                        cost: cost,
                        date: date,
                      ),
                    );
                  } else if (_recordType == 'refueling') {
                    await firestoreService.addRefueling(
                      user.uid,
                      widget.truckId,
                      RefuelingModel(
                        id: '',
                        truckId: widget.truckId,
                        liters: double.parse(_litersController.text),
                        cost: cost,
                        date: date,
                      ),
                    );
                  } else if (_recordType == 'expense') {
                    await firestoreService.addExpense(
                      user.uid,
                      widget.truckId,
                      ExpenseModel(
                        id: '',
                        truckId: widget.truckId,
                        description: _descriptionController.text,
                        cost: cost,
                        date: date,
                      ),
                    );
                  }
                  Navigator.pop(context);
                }
              },
              child: Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}
