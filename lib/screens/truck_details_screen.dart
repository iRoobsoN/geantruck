import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import '../models/truck_model.dart';
import '../models/maintenance_model.dart';
import '../models/refueling_model.dart';
import '../models/expense_model.dart';

import '../services/firestore_service.dart';
import 'add_record_screen.dart';
import 'stats_screen.dart';

class TruckDetailsScreen extends StatefulWidget {
  final TruckModel truck;

  const TruckDetailsScreen({super.key, required this.truck});

  @override
  State<TruckDetailsScreen> createState() => _TruckDetailsScreenState();
}

class _TruckDetailsScreenState extends State<TruckDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  // GlobalKey to access StatsScreen's state
  final GlobalKey<StatsScreenState> _statsScreenKey = GlobalKey<StatsScreenState>();


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      } else {
         setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.truck.name),
        backgroundColor: Colors.blue.shade800,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.history), text: 'Registros'),
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.picture_as_pdf), text: 'Relatórios'),
          ],
        ),
        actions: [
          if (_currentIndex == 2) // Only show button on Reports tab
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () {
                // Call the PDF generation method from StatsScreen
                _statsScreenKey.currentState?.exportPdf();
              },
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RecordsList(truckId: widget.truck.id),
          _DashboardView(truckId: widget.truck.id),
          StatsScreen(key: _statsScreenKey, truckId: widget.truck.id),
        ],
      ),
      floatingActionButton: _currentIndex == 0 // Only show FAB on Records tab
          ? FloatingActionButton(
              child: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Adicionar Registro',
              backgroundColor: Colors.blue.shade800,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddRecordScreen(truckId: widget.truck.id),
                  ),
                );
              },
            )
          : null,
    );
  }
}

// Placeholder for the Records List
class _RecordsList extends StatelessWidget {
  final String truckId;
  const _RecordsList({required this.truckId});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final user = Provider.of<User?>(context);

    if (user == null) {
      return Center(child: Text('Usuário não autenticado.'));
    }

    return StreamBuilder<List<dynamic>>(
      stream: firestoreService.getCombinedRecords(user.uid, truckId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar registros: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text('Nenhum registro encontrado', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              ],
            ),
          );
        }

        final records = snapshot.data!;
        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _buildRecordTile(context, record);
          },
        );
      },
    );
  }

  Widget _buildRecordTile(BuildContext context, dynamic record) {
    IconData icon;
    String title;
    String subtitle;
    String amount;

    if (record is MaintenanceModel) {
      icon = Icons.build;
      title = 'Manutenção';
      subtitle = record.description;
      amount = '- R\$ ${record.cost.toStringAsFixed(2)}';
    } else if (record is RefuelingModel) {
      icon = Icons.local_gas_station;
      title = 'Abastecimento';
      subtitle = '${record.liters.toStringAsFixed(2)} litros';
      amount = '- R\$ ${record.cost.toStringAsFixed(2)}';
    } else if (record is ExpenseModel) {
      icon = Icons.receipt_long;
      title = 'Outra Despesa';
      subtitle = record.description;
      amount = '- R\$ ${record.cost.toStringAsFixed(2)}';
    } else {
      return SizedBox.shrink(); // Should not happen
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
                fontSize: 15,
              ),
            ),
            SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yy').format(record.date),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder for the Dashboard View
class _DashboardView extends StatelessWidget {
  final String truckId;
  const _DashboardView({required this.truckId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Provavelmente vamos ter uma tela bem útil aqui.'),
    );
  }
}

