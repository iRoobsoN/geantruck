import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/maintenance_model.dart';
import '../models/refueling_model.dart';
import '../models/expense_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum RecordType { maintenance, refueling, expense }

class AddRecordScreen extends StatefulWidget {
  final String truckId;

  const AddRecordScreen({super.key, required this.truckId});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _litersController = TextEditingController();
  RecordType _recordType = RecordType.maintenance;

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final user = Provider.of<User?>(context);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Adicionar Registro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.grey[800],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<RecordType>(
                      segments: const <ButtonSegment<RecordType>>[
                        ButtonSegment<RecordType>(
                            value: RecordType.maintenance,
                            label: Text('Manutenção'),
                            icon: Icon(Icons.build)),
                        ButtonSegment<RecordType>(
                            value: RecordType.refueling,
                            label: Text('Abastecer'),
                            icon: Icon(Icons.local_gas_station)),
                        ButtonSegment<RecordType>(
                            value: RecordType.expense,
                            label: Text('Despesa'),
                            icon: Icon(Icons.receipt)),
                      ],
                      selected: <RecordType>{_recordType},
                      onSelectionChanged: (Set<RecordType> newSelection) {
                        setState(() {
                          _recordType = newSelection.first;
                        });
                      },
                      style: SegmentedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.grey[600],
                        selectedForegroundColor: Colors.white,
                        selectedBackgroundColor: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_recordType != RecordType.refueling)
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Descrição',
                          icon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira uma descrição';
                          }
                          return null;
                        },
                      ),
                    if (_recordType == RecordType.refueling)
                      TextFormField(
                        controller: _litersController,
                        decoration: InputDecoration(
                          labelText: 'Litros',
                          icon: const Icon(Icons.local_gas_station),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira os litros';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Por favor, insira um número válido';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _costController,
                      decoration: InputDecoration(
                        labelText: 'Custo',
                        icon: const Icon(Icons.monetization_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o custo';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Por favor, insira um número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar'),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (user != null) {
                              final cost =
                                  double.parse(_costController.text.replaceAll(',', '.'));
                              final date = DateTime.now();

                              switch (_recordType) {
                                case RecordType.maintenance:
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
                                  break;
                                case RecordType.refueling:
                                  await firestoreService.addRefueling(
                                    user.uid,
                                    widget.truckId,
                                    RefuelingModel(
                                      id: '',
                                      truckId: widget.truckId,
                                      liters: double.parse(
                                          _litersController.text.replaceAll(',', '.')),
                                      cost: cost,
                                      date: date,
                                    ),
                                  );
                                  break;
                                case RecordType.expense:
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
                                  break;
                              }
                              if (mounted) {
                                Navigator.pop(context);
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
