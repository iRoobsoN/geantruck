import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/truck_model.dart';
import '../models/maintenance_model.dart';
import '../models/refueling_model.dart';
import '../models/expense_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Truck operations
  Stream<List<TruckModel>> getTrucks(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('trucks')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TruckModel(id: doc.id, name: doc.data()['name'], plate: doc.data()['plate']))
            .toList());
  }

  Future<void> addTruck(String userId, TruckModel truck) {
    return _db.collection('users').doc(userId).collection('trucks').add({
      'name': truck.name,
      'plate': truck.plate,
    });
  }

  // Maintenance operations
  Future<void> addMaintenance(String userId, String truckId, MaintenanceModel maintenance) {
    return _db.collection('users').doc(userId).collection('trucks').doc(truckId).collection('maintenances').add({
      'description': maintenance.description,
      'cost': maintenance.cost,
      'date': maintenance.date,
    });
  }

  // Refueling operations
  Future<void> addRefueling(String userId, String truckId, RefuelingModel refueling) {
    return _db.collection('users').doc(userId).collection('trucks').doc(truckId).collection('refuelings').add({
      'liters': refueling.liters,
      'cost': refueling.cost,
      'date': refueling.date,
    });
  }

  // Expense operations
  Future<void> addExpense(String userId, String truckId, ExpenseModel expense) {
    return _db.collection('users').doc(userId).collection('trucks').doc(truckId).collection('expenses').add({
      'description': expense.description,
      'cost': expense.cost,
      'date': expense.date,
    });
  }

  // Combined records for a single truck
  Stream<List<dynamic>> getCombinedRecords(String userId, String truckId) {
    final maintenanceStream = _db
        .collection('users')
        .doc(userId)
        .collection('trucks')
        .doc(truckId)
        .collection('maintenances')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return MaintenanceModel(
                id: doc.id,
                truckId: truckId,
                description: data['description'],
                cost: data['cost'],
                date: (data['date'] as Timestamp).toDate(),
              );
            }).toList());

    final refuelingStream = _db
        .collection('users')
        .doc(userId)
        .collection('trucks')
        .doc(truckId)
        .collection('refuelings')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return RefuelingModel(
                id: doc.id,
                truckId: truckId,
                liters: data['liters'],
                cost: data['cost'],
                date: (data['date'] as Timestamp).toDate(),
              );
            }).toList());

    final expenseStream = _db
        .collection('users')
        .doc(userId)
        .collection('trucks')
        .doc(truckId)
        .collection('expenses')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return ExpenseModel(
                id: doc.id,
                truckId: truckId,
                description: data['description'],
                cost: data['cost'],
                date: (data['date'] as Timestamp).toDate(),
              );
            }).toList());

    return CombineLatestStream.list([
      maintenanceStream,
      refuelingStream,
      expenseStream,
    ]).map((lists) {
      final combined = lists.expand((list) => list).toList();
      combined.sort((a, b) => (a as dynamic).date.compareTo((b as dynamic).date));
      return combined;
    });
  }

  Future<List<T>> getRecordsForDateRange<T>(
    String userId,
    String truckId,
    String collectionName,
    DateTime startDate,
    DateTime endDate) async {
  final snapshot = await _db
      .collection('users')
      .doc(userId)
      .collection('trucks')
      .doc(truckId)
      .collection(collectionName)
      .where('date', isGreaterThanOrEqualTo: startDate)
      .where('date', isLessThanOrEqualTo: endDate)
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data();
    final id = doc.id;
    
    switch (T) {
      case MaintenanceModel:
        return MaintenanceModel(
          id: id,
          truckId: truckId,
          description: data['description'],
          cost: data['cost'],
          date: (data['date'] as Timestamp).toDate(),
        ) as T;
      case RefuelingModel:
        return RefuelingModel(
          id: id,
          truckId: truckId,
          liters: data['liters'],
          cost: data['cost'],
          date: (data['date'] as Timestamp).toDate(),
        ) as T;
      case ExpenseModel:
        return ExpenseModel(
          id: id,
          truckId: truckId,
          description: data['description'],
          cost: data['cost'],
          date: (data['date'] as Timestamp).toDate(),
        ) as T;
      default:
        throw Exception('Unknown model type: $T');
    }
  }).toList();
}
}
