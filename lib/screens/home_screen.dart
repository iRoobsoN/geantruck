import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/truck_model.dart';
import 'add_truck_screen.dart';
import 'truck_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<DocumentSnapshot> _userProfileFuture;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      _userProfileFuture = _firestoreService.getUserById(user.uid);
    }
  }

  void _reloadUserProfile() {
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      setState(() {
        _userProfileFuture = _firestoreService.getUserById(user.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = Provider.of<User?>(context);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _userProfileFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        String userRole;
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          userRole = userData['role'] as String? ?? 'funcionario';
        } else {
          userRole = 'funcionario';
        }

        final isManager = userRole == 'gerente';

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: Text(isManager ? 'Minha Frota' : 'Meus Veículos'),
            backgroundColor: Colors.blue.shade800,
            elevation: 4,
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline),
                tooltip: 'Meu Perfil',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                  _reloadUserProfile();
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sair',
                onPressed: () => authService.signOut(),
              ),
            ],
          ),
          body: _buildTrucksList(context, user.uid, userRole, _firestoreService),
          
          floatingActionButton: isManager
              ? FloatingActionButton(
                  backgroundColor: Colors.blue.shade800,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTruckScreen())),
                  tooltip: 'Adicionar Caminhão',
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  Widget _buildTrucksList(BuildContext context, String userId, String userRole, FirestoreService firestoreService) {
    final Stream<List<TruckModel>> trucksStream = userRole == 'gerente'
        ? firestoreService.getTrucks(userId)
        : firestoreService.getTrucksAssignedToEmployee(userId);

    return StreamBuilder<List<TruckModel>>(
      stream: trucksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Ocorreu um erro ao carregar os dados.'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(context, userRole);
        }

        final trucks = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.85,
          ),
          itemCount: trucks.length,
          itemBuilder: (context, index) {
            final truck = trucks[index];
            return _buildTruckCard(context, truck, firestoreService);
          },
        );
      },
    );
  }
  
  Widget _buildEmptyState(BuildContext context, String userRole) {
    final String title = userRole == 'gerente' ? 'Nenhum caminhão cadastrado' : 'Nenhum veículo atribuído';
    final String subtitle = userRole == 'gerente' ? 'Adicione seu primeiro veículo no botão +' : 'Quando um gerente atribuir um veículo a você, ele aparecerá aqui.';
        
    return Center(
      child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.local_shipping_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ),
        ],
      ),
    );
  }

  Widget _buildTruckCard(BuildContext context, TruckModel truck, FirestoreService firestoreService) {
    final user = Provider.of<User?>(context, listen: false);
    final ownerIdToUse = truck.ownerId.isNotEmpty ? truck.ownerId : user!.uid;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TruckDetailsScreen(
                ownerId: ownerIdToUse,
                truckId: truck.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column( crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.local_shipping, size: 50, color: Colors.blue.shade700),
                    const SizedBox(height: 12),
                    Text(truck.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(truck.plate, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 8),
              _buildResponsibleInfo(truck, firestoreService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsibleInfo(TruckModel truck, FirestoreService firestoreService) {
    if (truck.responsibleUserId == null || truck.responsibleUserId!.isEmpty) {
      return Row( mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.person_off_outlined, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text('Sem responsável', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ]);
    }
    return FutureBuilder<DocumentSnapshot>(
      future: firestoreService.getUserById(truck.responsibleUserId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))); }
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final name = userData['name'] as String? ?? 'Sem nome';
          return Row( mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.person, size: 16, color: Colors.blue.shade800),
            const SizedBox(width: 4),
            Expanded(child: Text(name, style: TextStyle(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.w500), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
          ]);
        }
        return Row( mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 16, color: Colors.red[400]),
          const SizedBox(width: 4),
          Text('Inválido', style: TextStyle(fontSize: 12, color: Colors.red[700])),
        ]);
      },
    );
  }
}