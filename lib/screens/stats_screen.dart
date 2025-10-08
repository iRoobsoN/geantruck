import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../models/maintenance_model.dart';
import '../models/refueling_model.dart';
import '../models/record_model.dart';
import '../services/firestore_service.dart';

class StatsScreen extends StatefulWidget {
  final String truckId;

  const StatsScreen({super.key, required this.truckId});

  @override
  State<StatsScreen> createState() => StatsScreenState();
}

class StatsScreenState extends State<StatsScreen> {
  late Future<Map<String, List>> _recordsFuture;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _recordsFuture = _fetchRecordsForMonth(_selectedMonth);
  }

  Future<void> exportPdf() async {
    final user = Provider.of<User?>(context, listen: false);
    final records = await _recordsFuture;
    if (user != null && mounted) {
      _generatePdf(context, user.uid, _selectedMonth, records);
    }
  }

  Future<Map<String, List>> _fetchRecordsForMonth(DateTime month) async {
    final firestoreService = FirestoreService();
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return {};

    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final maintenances = await firestoreService.getRecordsForDateRange<MaintenanceModel>(
        user.uid, widget.truckId, 'maintenances', firstDay, lastDay);
    final refuelings = await firestoreService.getRecordsForDateRange<RefuelingModel>(
        user.uid, widget.truckId, 'refuelings', firstDay, lastDay);
    final expenses = await firestoreService.getRecordsForDateRange<ExpenseModel>(
        user.uid, widget.truckId, 'expenses', firstDay, lastDay);

    return {
      'maintenances': maintenances,
      'refuelings': refuelings,
      'expenses': expenses,
    };
  }

  void _changeMonth(int monthIncrement) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + monthIncrement, 1);
      _recordsFuture = _fetchRecordsForMonth(_selectedMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: FutureBuilder<Map<String, List>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum dado encontrado.'));
          }

          final records = snapshot.data!;
          final maintenances = records['maintenances'] as List<MaintenanceModel>;
          final refuelings = records['refuelings'] as List<RefuelingModel>;
          final expenses = records['expenses'] as List<ExpenseModel>;

          final totalMaintenanceCost = maintenances.fold<double>(0, (sum, item) => sum + item.cost);
          final totalRefuelingCost = refuelings.fold<double>(0, (sum, item) => sum + item.cost);
          final totalExpenseCost = expenses.fold<double>(0, (sum, item) => sum + item.cost);
          final totalCost = totalMaintenanceCost + totalRefuelingCost + totalExpenseCost;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthSelector(),
                const SizedBox(height: 16),
                _buildSummaryCards(totalMaintenanceCost, totalRefuelingCost, totalExpenseCost, totalCost),
                const SizedBox(height: 24),
                if (totalCost > 0) ...[
                  const Text('Distribuição de Custos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildPieChart(totalMaintenanceCost, totalRefuelingCost, totalExpenseCost),
                  const SizedBox(height: 24),
                  const Text('Custos Diários', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildBarChart(maintenances, refuelings, expenses),
                ] else
                  const Center(
                    child: Text(
                      'Nenhum registro encontrado para este mês.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeMonth(-1),
        ),
        Text(
          DateFormat.yMMMM('pt_BR').format(_selectedMonth),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(double maintenance, double refueling, double expense, double total) {
    return Column(
      children: [
        Row(
          children: [
            _buildSummaryCard('Manutenção', maintenance, Colors.orange, Icons.build),
            const SizedBox(width: 16),
            _buildSummaryCard('Abastecimento', refueling, Colors.blue, Icons.local_gas_station),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSummaryCard('Despesas', expense, Colors.red, Icons.receipt),
            const SizedBox(width: 16),
            _buildSummaryCard('Custo Total', total, Colors.deepPurple, Icons.summarize, isTotal: true),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon, {bool isTotal = false}) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  Icon(icon, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(amount),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isTotal ? Colors.deepPurple : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(double maintenance, double refueling, double expense) {
    final total = maintenance + refueling + expense;
    if (total == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: Colors.orange,
                  value: maintenance,
                  title: '${(maintenance / total * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: Colors.blue,
                  value: refueling,
                  title: '${(refueling / total * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: Colors.red,
                  value: expense,
                  title: '${(expense / total * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<MaintenanceModel> maintenances, List<RefuelingModel> refuelings, List<ExpenseModel> expenses) {
    final Map<int, double> dailyCosts = {};
    final allRecords = [...maintenances, ...refuelings, ...expenses];

    for (var record in allRecords) {
      final day = record.date.day;
      double cost = 0;
      if (record is MaintenanceModel) {
        cost = record.cost;
      } else if (record is RefuelingModel) {
        cost = record.cost;
      } else if (record is ExpenseModel) {
        cost = record.cost;
      }
      dailyCosts[day] = (dailyCosts[day] ?? 0) + cost;
    }

    if (dailyCosts.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 250,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: dailyCosts.values.reduce((a, b) => a > b ? a : b) * 1.2,
              barGroups: dailyCosts.entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value,
                      color: Colors.deepPurple,
                      width: 10,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                    },
                    reservedSize: 28,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 50),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context, String userId, DateTime month, Map<String, List> records) async {
    final pdf = pw.Document();
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final DateFormat dateFormat = DateFormat.yMd('pt_BR');

    final maintenances = records['maintenances'] as List<MaintenanceModel>;
    final refuelings = records['refuelings'] as List<RefuelingModel>;
    final expenses = records['expenses'] as List<ExpenseModel>;

    final totalMaintenanceCost = maintenances.fold<double>(0, (sum, item) => sum + item.cost);
    final totalRefuelingCost = refuelings.fold<double>(0, (sum, item) => sum + item.cost);
    final totalExpenseCost = expenses.fold<double>(0, (sum, item) => sum + item.cost);
    final totalCost = totalMaintenanceCost + totalRefuelingCost + totalExpenseCost;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Relatório Mensal', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat.yMMMM('pt_BR').format(month), style: const pw.TextStyle(fontSize: 18)),
              ],
            ),
          ),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 20),

          pw.Header(level: 1, child: pw.Text('Resumo de Custos')),
          pw.Table.fromTextArray(
            headers: ['Categoria', 'Custo Total'],
            data: [
              ['Manutenção', currencyFormat.format(totalMaintenanceCost)],
              ['Abastecimento', currencyFormat.format(totalRefuelingCost)],
              ['Despesas', currencyFormat.format(totalExpenseCost)],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Custo Total do Mês: ${currencyFormat.format(totalCost)}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),

          if (maintenances.isNotEmpty) ...[
            pw.Header(level: 1, child: pw.Text('Detalhes de Manutenção')),
            pw.Table.fromTextArray(
              headers: ['Data', 'Descrição', 'Custo'],
              data: maintenances.map((e) => [dateFormat.format(e.date), e.description, currencyFormat.format(e.cost)]).toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          if (refuelings.isNotEmpty) ...[
            pw.Header(level: 1, child: pw.Text('Detalhes de Abastecimento')),
            pw.Table.fromTextArray(
              headers: ['Data', 'Litros', 'Custo'],
              data: refuelings.map((e) => [dateFormat.format(e.date), '${e.liters} L', currencyFormat.format(e.cost)]).toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          if (expenses.isNotEmpty) ...[
            pw.Header(level: 1, child: pw.Text('Detalhes de Despesas')),
            pw.Table.fromTextArray(
              headers: ['Data', 'Descrição', 'Custo'],
              data: expenses.map((e) => [dateFormat.format(e.date), e.description, currencyFormat.format(e.cost)]).toList(),
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
