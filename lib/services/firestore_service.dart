import 'package:cloud_firestore/cloud_firestore.dart';
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
}
