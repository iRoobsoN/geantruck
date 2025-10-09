import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/truck_model.dart';
import '../models/maintenance_model.dart';
import '../models/refueling_model.dart';
import '../models/expense_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- MÉTODOS DE USUÁRIO ---


Stream<List<RefuelingModel>> getRefuelingsForTruck(String ownerId, String truckId) {
    return _db
        .collection('users')
        .doc(ownerId)
        .collection('trucks')
        .doc(truckId)
        .collection('refuelings')
        .orderBy('date', descending: true) // Ordena do mais recente para o mais antigo
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RefuelingModel.fromFirestore(doc, truckId))
            .toList());
  }

Future<void> deleteRecord(String ownerId, String truckId, String collectionName, String recordId) {
    return _db
        .collection('users')
        .doc(ownerId)
        .collection('trucks')
        .doc(truckId)
        .collection(collectionName)
        .doc(recordId)
        .delete();
  }

  Future<QuerySnapshot> findEmployeeByEmail(String email) {
    if (email.trim().isEmpty) {
      // Retorna um Future com um snapshot vazio se a busca for vazia.
      return Future.value(null); // Essa linha precisará de um ajuste no tipo de retorno se o Dart reclamar.
                                 // Uma forma mais segura seria lançar uma exceção, mas vamos tratar na UI.
    }
    return _db
        .collection('users')
        .where('role', isEqualTo: 'funcionario') 
        .where('email', isEqualTo: email.trim())
        .limit(1) // Busca no máximo 1 resultado, pois o e-mail deve ser único.
        .get();
  }

  Future<void> createUserDocument(String uid, String email, String name, String role) {
    return _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name,
      'role': role, // Usa o cargo passado como parâmetro.
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot> getUserById(String userId) {
    return _db.collection('users').doc(userId).get();
  }

  Future<void> updateUserProfile(String userId, String name, String newRole) {
    if (newRole != 'gerente' && newRole != 'funcionario') {
      throw Exception("Cargo inválido selecionado.");
    }
    if (name.trim().isEmpty) {
      throw Exception("O nome não pode estar vazio.");
    }
    return _db.collection('users').doc(userId).update({
      'name': name,
      'role': newRole,
    });
  }

  Stream<QuerySnapshot> searchEmployeesByEmail(String emailQuery) {
    if (emailQuery.trim().isEmpty) {
      return Stream.empty();
    }
    return _db
        .collection('users')
        .where('role', isEqualTo: 'funcionario')
        .where('email', isGreaterThanOrEqualTo: emailQuery)
        .where('email', isLessThanOrEqualTo: '$emailQuery\uf8ff')
        .snapshots();
  }

  // --- MÉTODOS DE CAMINHÃO ---

  Stream<List<TruckModel>> getTrucks(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('trucks')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TruckModel.fromFirestore(doc)).toList());
  }

  Stream<List<TruckModel>> getTrucksAssignedToEmployee(String employeeId) {
    return _db
        .collectionGroup('trucks')
        .where('responsibleUserId', isEqualTo: employeeId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TruckModel.fromFirestore(doc)).toList());
  }

  Stream<DocumentSnapshot> getTruckStream(String ownerId, String truckId) {
    return _db.collection('users').doc(ownerId).collection('trucks').doc(truckId).snapshots();
  }
  
  Future<void> addTruck(String userId, TruckModel truck) {
    // CORREÇÃO: Garante que o 'ownerId' seja o do gerente que está criando o caminhão.
    final truckData = truck.toFirestore();
    truckData['ownerId'] = userId;
    return _db.collection('users').doc(userId).collection('trucks').add(truckData);
  }

  Future<void> assignResponsibleToTruck(String ownerId, String truckId, String responsibleUserId) {
    return _db.collection('users').doc(ownerId).collection('trucks').doc(truckId).update({'responsibleUserId': responsibleUserId});
  }

  Future<void> removeResponsibleFromTruck(String ownerId, String truckId) {
    return _db.collection('users').doc(ownerId).collection('trucks').doc(truckId).update({'responsibleUserId': null});
  }

  // --- MÉTODOS DE REGISTROS (Manutenção, Abastecimento, etc.) ---

  Future<void> addMaintenance(String ownerId, String truckId, MaintenanceModel maintenance) {
    // CORREÇÃO: Usa o ownerId para o caminho e o método .toFirestore() do modelo.
    return _db.collection('users').doc(ownerId).collection('trucks').doc(truckId).collection('maintenances').add(maintenance.toFirestore());
  }

  Future<void> addRefueling(String ownerId, String truckId, RefuelingModel refueling) {
    // CORREÇÃO: Usa o ownerId para o caminho e o método .toFirestore() do modelo.
    return _db.collection('users').doc(ownerId).collection('trucks').doc(truckId).collection('refuelings').add(refueling.toFirestore());
  }

  Future<void> addExpense(String ownerId, String truckId, ExpenseModel expense) {
    // CORREÇÃO: Usa o ownerId para o caminho e o método .toFirestore() do modelo.
    return _db.collection('users').doc(ownerId).collection('trucks').doc(truckId).collection('expenses').add(expense.toFirestore());
  }
  
  Stream<List<dynamic>> getCombinedRecords(String ownerId, String truckId) {
    final maintenanceStream = _db
        .collection('users')
        .doc(ownerId) // CORREÇÃO: usa ownerId
        .collection('trucks')
        .doc(truckId)
        .collection('maintenances')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              // CORREÇÃO: Usa o factory constructor que já lida com todos os campos.
              return MaintenanceModel.fromFirestore(doc, truckId);
            }).toList());

    final refuelingStream = _db
        .collection('users')
        .doc(ownerId) // CORREÇÃO: usa ownerId
        .collection('trucks')
        .doc(truckId)
        .collection('refuelings')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              // CORREÇÃO: Usa o factory constructor.
              return RefuelingModel.fromFirestore(doc, truckId);
            }).toList());

    final expenseStream = _db
        .collection('users')
        .doc(ownerId) // CORREÇÃO: usa ownerId
        .collection('trucks')
        .doc(truckId)
        .collection('expenses')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              // CORREÇÃO: Usa o factory constructor.
              return ExpenseModel.fromFirestore(doc, truckId);
            }).toList());

    return CombineLatestStream.list([
      maintenanceStream,
      refuelingStream,
      expenseStream,
    ]).map((lists) {
      final combined = lists.expand((list) => list).toList();
      combined.sort((a, b) => (b as dynamic).date.compareTo((a as dynamic).date));
      return combined;
    });
  }

  Future<List<T>> getRecordsForDateRange<T>(
    String ownerId,
    String truckId,
    String collectionName,
    DateTime startDate,
    DateTime endDate) async {
    final snapshot = await _db
        .collection('users')
        .doc(ownerId) // CORREÇÃO: usa ownerId
        .collection('trucks')
        .doc(truckId)
        .collection(collectionName)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();

    return snapshot.docs.map((doc) {
      switch (T) {
        case MaintenanceModel:
          // CORREÇÃO: Usa o factory constructor.
          return MaintenanceModel.fromFirestore(doc, truckId) as T;
        case RefuelingModel:
          // CORREÇÃO: Usa o factory constructor.
          return RefuelingModel.fromFirestore(doc, truckId) as T;
        case ExpenseModel:
          // CORREÇÃO: Usa o factory constructor.
          return ExpenseModel.fromFirestore(doc, truckId) as T;
        default:
          throw Exception('Unknown model type: $T');
      }
    }).toList();
  }
}