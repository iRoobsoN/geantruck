import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/maintenance_model.dart';
import '../models/refueling_model.dart';
import '../models/expense_model.dart';

enum RecordType { maintenance, refueling, expense }

class AddRecordScreen extends StatefulWidget {
  final String truckId;
  final String ownerId; // <-- PARÂMETRO ADICIONADO

  const AddRecordScreen({
    super.key, 
    required this.truckId,
    required this.ownerId, // <-- PARÂMETRO ADICIONADO
  });

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _litersController = TextEditingController();
  final _odometerController = TextEditingController(); // <-- 1. CONTROLLER PARA O KM
  RecordType _recordType = RecordType.maintenance;
  bool _isLoading = false; // Para gerenciar o estado de carregamento do botão
  

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
    _litersController.dispose();
    _odometerController.dispose(); // <-- 2. FAZER O DISPOSE
    super.dispose();
  }

  /// Função centralizada para validar e salvar o registro.
  Future<void> _submitRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Provider.of<User?>(context, listen: false);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não autenticado.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final firestoreService = FirestoreService();
    final cost = double.parse(_costController.text.replaceAll(',', '.'));
    final date = DateTime.now();

    try {
      switch (_recordType) {
        case RecordType.maintenance:
          final maintenance = MaintenanceModel(id: '', truckId: widget.truckId, description: _descriptionController.text, cost: cost, date: date, createdBy: user.uid);
          await firestoreService.addMaintenance(widget.ownerId, widget.truckId, maintenance);
          break;
        case RecordType.refueling:
          // 4. USAR O VALOR DO NOVO CAMPO AO CRIAR O MODELO
          final refueling = RefuelingModel(
            id: '',
            truckId: widget.truckId,
            liters: double.parse(_litersController.text.replaceAll(',', '.')),
            cost: cost,
            odometer: int.parse(_odometerController.text), // <-- USA O VALOR
            date: date,
            createdBy: user.uid,
          );
          await firestoreService.addRefueling(widget.ownerId, widget.truckId, refueling);
          break;
        case RecordType.expense:
          final expense = ExpenseModel(id: '', truckId: widget.truckId, description: _descriptionController.text, cost: cost, date: date, createdBy: user.uid);
          await firestoreService.addExpense(widget.ownerId, widget.truckId, expense);
          break;
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar registro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<RecordType>(
                      segments: const <ButtonSegment<RecordType>>[
                        ButtonSegment<RecordType>(value: RecordType.maintenance, label: Text('Manutenção'), icon: Icon(Icons.build)),
                        ButtonSegment<RecordType>(value: RecordType.refueling, label: Text('Abastecer'), icon: Icon(Icons.local_gas_station)),
                        ButtonSegment<RecordType>(value: RecordType.expense, label: Text('Despesa'), icon: Icon(Icons.receipt)),
                      ],
                      selected: <RecordType>{_recordType},
                      onSelectionChanged: (Set<RecordType> newSelection) => setState(() => _recordType = newSelection.first),
                      style: SegmentedButton.styleFrom(
                        backgroundColor: Colors.grey[200], foregroundColor: Colors.grey[600], selectedForegroundColor: Colors.white, selectedBackgroundColor: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Mostra DESCRIÇÃO para Manutenção e Despesa
                    if (_recordType != RecordType.refueling)
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(labelText: 'Descrição', icon: const Icon(Icons.description), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0))),
                        validator: (value) => (value == null || value.isEmpty) ? 'Por favor, insira uma descrição' : null,
                      ),

                    // Mostra LITROS e KM para Abastecimento
                    if (_recordType == RecordType.refueling) ...[
                      TextFormField(
                        controller: _litersController,
                        decoration: InputDecoration(labelText: 'Litros', icon: const Icon(Icons.opacity), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0))),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Por favor, insira os litros';
                          if (double.tryParse(value) == null) return 'Número inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // 3. ADICIONAR O CAMPO DE TEXTO PARA O KM
                      TextFormField(
                        controller: _odometerController,
                        decoration: InputDecoration(labelText: 'Quilometragem (Hodômetro)', icon: const Icon(Icons.speed), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0))),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Por favor, insira a quilometragem';
                          if (int.tryParse(value) == null) return 'Número inválido';
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _costController,
                      decoration: InputDecoration(labelText: 'Custo Total', icon: const Icon(Icons.monetization_on), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0))),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Por favor, insira o custo';
                        if (double.tryParse(value) == null) return 'Número inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isLoading ? Container() : const Icon(Icons.add),
                        label: _isLoading 
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                            : const Text('Adicionar'),
                        onPressed: _isLoading ? null : _submitRecord,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
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
