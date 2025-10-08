import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/truck_model.dart';
import 'add_truck_screen.dart';
import 'truck_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = FirestoreService();
    final user = Provider.of<User?>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Meus Caminhões'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: user == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<List<TruckModel>>(
              stream: firestoreService.getTrucks(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final trucks = snapshot.data!;
                return ListView.builder(
                  itemCount: trucks.length,
                  itemBuilder: (context, index) {
                    final truck = trucks[index];
                    return ListTile(
                      title: Text(truck.name),
                      subtitle: Text(truck.plate),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TruckDetailsScreen(truck: truck),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTruckScreen()),
          );
        },
      ),
    );
  }
}
