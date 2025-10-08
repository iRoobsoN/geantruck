import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/maintenance_model.dart';
import '../models/refueling_model.dart';
import '../models/expense_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  Future<File> generateReport(
    String truckId,
    List<MaintenanceModel> maintenances,
    List<RefuelingModel> refuelings,
    List<ExpenseModel> expenses,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final month = DateFormat.yMMMM('pt_BR').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Relatório Mensal de Despesas - $month'),
            ),
            pw.Header(level: 1, text: 'Manutenções'),
            _buildMaintenanceTable(maintenances),
            pw.Header(level: 1, text: 'Abastecimentos'),
            _buildRefuelingTable(refuelings),
            pw.Header(level: 1, text: 'Outras Despesas'),
            _buildExpenseTable(expenses),
            pw.Divider(),
            _buildTotals(maintenances, refuelings, expenses),
          ];
        },
      ),
    );

    // Use the printing package to show a preview and allow saving/printing
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());

    // This part is tricky because we don't save the file directly,
    // but the printing package handles it. We return a dummy file path.
    return File('report.pdf');
  }

  pw.Widget _buildMaintenanceTable(List<MaintenanceModel> data) {
    if (data.isEmpty) return pw.Text('Nenhuma manutenção registrada.');
    return pw.Table.fromTextArray(
      headers: ['Data', 'Descrição', 'Custo'],
      data: data.map((item) => [
        DateFormat.yMd('pt_BR').format(item.date),
        item.description,
        'R\$ ${item.cost.toStringAsFixed(2)}',
      ]).toList(),
    );
  }

  pw.Widget _buildRefuelingTable(List<RefuelingModel> data) {
    if (data.isEmpty) return pw.Text('Nenhum abastecimento registrado.');
    return pw.Table.fromTextArray(
      headers: ['Data', 'Litros', 'Custo'],
      data: data.map((item) => [
        DateFormat.yMd('pt_BR').format(item.date),
        item.liters.toString(),
        'R\$ ${item.cost.toStringAsFixed(2)}',
      ]).toList(),
    );
  }

  pw.Widget _buildExpenseTable(List<ExpenseModel> data) {
    if (data.isEmpty) return pw.Text('Nenhuma despesa registrada.');
    return pw.Table.fromTextArray(
      headers: ['Data', 'Descrição', 'Custo'],
      data: data.map((item) => [
        DateFormat.yMd('pt_BR').format(item.date),
        item.description,
        'R\$ ${item.cost.toStringAsFixed(2)}',
      ]).toList(),
    );
  }

  pw.Widget _buildTotals(
    List<MaintenanceModel> maintenances,
    List<RefuelingModel> refuelings,
    List<ExpenseModel> expenses,
  ) {
    final totalMaintenance = maintenances.fold(0.0, (sum, item) => sum + item.cost);
    final totalRefueling = refuelings.fold(0.0, (sum, item) => sum + item.cost);
    final totalExpense = expenses.fold(0.0, (sum, item) => sum + item.cost);
    final grandTotal = totalMaintenance + totalRefueling + totalExpense;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Total Manutenções: R\$ ${totalMaintenance.toStringAsFixed(2)}'),
        pw.Text('Total Abastecimentos: R\$ ${totalRefueling.toStringAsFixed(2)}'),
        pw.Text('Total Outras Despesas: R\$ ${totalExpense.toStringAsFixed(2)}'),
        pw.Divider(),
        pw.Text('Total Geral: R\$ ${grandTotal.toStringAsFixed(2)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}