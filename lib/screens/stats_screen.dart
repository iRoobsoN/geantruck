import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StatsScreen extends StatelessWidget {
  final String truckId;

  StatsScreen({required this.truckId});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Estatísticas')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _generatePdf(context, user!.uid),
          child: Text('Exportar PDF do Mês'),
        ),
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context, String userId) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    final maintenances = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('trucks')
        .doc(truckId)
        .collection('maintenances')
        .where('date', isGreaterThanOrEqualTo: firstDayOfMonth)
        .where('date', isLessThanOrEqualTo: lastDayOfMonth)
        .get();

    final refuelings = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('trucks')
        .doc(truckId)
        .collection('refuelings')
        .where('date', isGreaterThanOrEqualTo: firstDayOfMonth)
        .where('date', isLessThanOrEqualTo: lastDayOfMonth)
        .get();

    final expenses = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('trucks')
        .doc(truckId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: firstDayOfMonth)
        .where('date', isLessThanOrEqualTo: lastDayOfMonth)
        .get();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Relatório Mensal')),
          pw.Header(level: 1, child: pw.Text('Manutenções')),
          ...maintenances.docs.map((doc) {
            final data = doc.data();
            return pw.Text(
                '${DateFormat.yMd().format((data['date'] as Timestamp).toDate())}: ${data['description']} - R\$ ${data['cost']}');
          }),
          pw.Header(level: 1, child: pw.Text('Abastecimentos')),
          ...refuelings.docs.map((doc) {
            final data = doc.data();
            return pw.Text(
                '${DateFormat.yMd().format((data['date'] as Timestamp).toDate())}: ${data['liters']}L - R\$ ${data['cost']}');
          }),
          pw.Header(level: 1, child: pw.Text('Despesas')),
          ...expenses.docs.map((doc) {
            final data = doc.data();
            return pw.Text(
                '${DateFormat.yMd().format((data['date'] as Timestamp).toDate())}: ${data['description']} - R\$ ${data['cost']}');
          }),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
