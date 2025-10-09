import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/truck_model.dart';
import '../models/maintenance_model.dart';
import '../models/refueling_model.dart';
import '../models/expense_model.dart';

import '../services/firestore_service.dart';
import 'add_record_screen.dart';
import 'stats_screen.dart';
import 'truck_health_screen.dart';

class TruckDetailsScreen extends StatefulWidget {
  final String truckId;
  final String ownerId;

  const TruckDetailsScreen({
    super.key, 
    required this.truckId,
    required this.ownerId,
  });

  @override
  State<TruckDetailsScreen> createState() => _TruckDetailsScreenState();
}

class _TruckDetailsScreenState extends State<TruckDetailsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _currentIndex = 0;
  String _currentTitle = 'Saúde'; // Título inicial

  final GlobalKey<StatsScreenState> _statsScreenKey = GlobalKey<StatsScreenState>();
  final FirestoreService _firestoreService = FirestoreService();

  void _setupTabController(bool isManager) {
    int tabLength = isManager ? 4 : 3;
    if (_tabController?.length == tabLength) return;
    
    _tabController?.dispose();
    _tabController = TabController(length: tabLength, vsync: this);
    _tabController!.addListener(() {
      if (!mounted) return;
      setState(() {
        _currentIndex = _tabController!.index;
        // ATUALIZA O TÍTULO DA ABA ATUAL
        _currentTitle = _getTabTitle(_currentIndex, isManager);
      });
    });
    // Define o título inicial
    _currentTitle = _getTabTitle(0, isManager);
  }
  
  // Função para obter o título da aba com base no índice
  String _getTabTitle(int index, bool isManager) {
    final titles = ['Saúde', 'Registros', 'Relatórios', if (isManager) 'Responsável'];
    return titles[index];
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Usuário não encontrado.")));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _firestoreService.getUserById(user.uid),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final userRole = userData['role'] as String? ?? 'funcionario';
        final isManager = userRole == 'gerente';

        _setupTabController(isManager);

        return StreamBuilder<DocumentSnapshot>(
          stream: _firestoreService.getTruckStream(widget.ownerId, widget.truckId),
          builder: (context, truckSnapshot) {
            if (!truckSnapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (!truckSnapshot.data!.exists) {
              return const Scaffold(body: Center(child: Text("Caminhão não encontrado.")));
            }

            final TruckModel currentTruck = TruckModel.fromFirestore(truckSnapshot.data!);

            return Scaffold(
              appBar: AppBar(
                // O título da AppBar agora mostra o nome do caminhão e o nome da aba
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(currentTruck.name, style: const TextStyle(fontSize: 18)),
                    Text(_currentTitle, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                  ],
                ),
                backgroundColor: Colors.blue.shade800,
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3.0,
                  // MUDANÇA: 'isScrollable' removido para distribuir o espaço igualmente
                  tabs: [
  const Tab(
    icon: Tooltip(
      message: 'Saúde',
      child: Icon(Icons.favorite_border),
    ),
  ),
  const Tab(
    icon: Tooltip(
      message: 'Registros',
      child: Icon(Icons.history),
    ),
  ),
  const Tab(
    icon: Tooltip(
      message: 'Relatórios',
      child: Icon(Icons.bar_chart),
    ),
  ),
  if (isManager)
    const Tab(
      icon: Tooltip(
        message: 'Responsável',
        child: Icon(Icons.person_add_alt_1),
      ),
    ),
],
                ),
                actions: [
                  if (_currentIndex == 2) 
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf),
                      onPressed: () => _statsScreenKey.currentState?.exportPdf(),
                      tooltip: 'Exportar PDF',
                    ),
                ],
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  TruckHealthScreen(ownerId: widget.ownerId, truckId: widget.truckId),
                  _RecordsList(truck: currentTruck),
                  StatsScreen(
                    key: _statsScreenKey,
                    ownerId: widget.ownerId,
                    truckId: widget.truckId,
                  ),
                  if (isManager)
                    _ResponsibleTab(truck: currentTruck),
                ],
              ),
              floatingActionButton: _currentIndex == 1
                  ? FloatingActionButton(
                      backgroundColor: Colors.blue.shade800,
                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (context) => AddRecordScreen(
                          truckId: widget.truckId,
                          ownerId: widget.ownerId,
                        ),
                      )),
                      child: const Icon(Icons.add, color: Colors.white),
                      tooltip: 'Adicionar Registro',
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

// --- As classes _RecordsList e _ResponsibleTab permanecem exatamente as mesmas ---

class _RecordsList extends StatelessWidget {
  final TruckModel truck;
  const _RecordsList({required this.truck});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final user = Provider.of<User?>(context);
    if (user == null) return const Center(child: Text('Usuário não autenticado.'));
    
    final ownerIdToUse = truck.ownerId.isNotEmpty ? truck.ownerId : user.uid;

    return StreamBuilder<List<dynamic>>(
      stream: firestoreService.getCombinedRecords(ownerIdToUse, truck.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
        if (snapshot.hasError) { return Center(child: Text('Erro: ${snapshot.error}')); }
        if (!snapshot.hasData || snapshot.data!.isEmpty) { return Center( child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Nenhum registro encontrado', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Pressione e segure um registro para excluí-lo.', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ]));}
        final records = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _buildRecordTile(context, record, firestoreService, ownerIdToUse);
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, dynamic record, FirestoreService service, String ownerId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const SingleChildScrollView(child: ListBody(children: <Widget>[Text('Tem certeza que deseja excluir este registro?'), Text('Esta ação não pode ser desfeita.')])),
          actions: <Widget>[
            TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(dialogContext).pop()),
            TextButton(
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                String collectionName;
                if (record is MaintenanceModel) collectionName = 'maintenances';
                else if (record is RefuelingModel) collectionName = 'refuelings';
                else if (record is ExpenseModel) collectionName = 'expenses';
                else return;
                try {
                  await service.deleteRecord(ownerId, truck.id, collectionName, record.id);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro excluído com sucesso.'), backgroundColor: Colors.green));
                } catch (e) {
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red));
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecordTile(BuildContext context, dynamic record, FirestoreService firestoreService, String ownerId) {
    IconData icon; String title; String subtitle; String amount; String createdByUid = record.createdBy;
    if (record is MaintenanceModel) { icon = Icons.build; title = 'Manutenção'; subtitle = record.description; amount = '- R\$ ${record.cost.toStringAsFixed(2)}';
    } else if (record is RefuelingModel) { icon = Icons.local_gas_station; title = 'Abastecimento'; subtitle = '${record.liters.toStringAsFixed(2)} L  •  ${record.odometer} km'; amount = '- R\$ ${record.cost.toStringAsFixed(2)}';
    } else if (record is ExpenseModel) { icon = Icons.receipt_long; title = 'Outra Despesa'; subtitle = record.description; amount = '- R\$ ${record.cost.toStringAsFixed(2)}';
    } else { return const SizedBox.shrink(); }
    return GestureDetector(
      onLongPress: () => _showDeleteConfirmationDialog(context, record, firestoreService, ownerId),
      child: Card( margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding( padding: const EdgeInsets.only(top: 12, bottom: 8, left: 16, right: 16), child: Column( children: [
        Row( crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1), child: Icon(icon, color: Theme.of(context).primaryColor)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700], fontSize: 15)), const SizedBox(height: 4), Text(DateFormat('dd/MM/yy').format(record.date), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ]),
        ]),
        if (createdByUid.isNotEmpty) ...[ const Divider(height: 16), _buildCreatorInfo(context, createdByUid, firestoreService), ]
      ]))),
    );
  }

  Widget _buildCreatorInfo(BuildContext context, String creatorUid, FirestoreService firestoreService) {
    return FutureBuilder<DocumentSnapshot>(
      future: firestoreService.getUserById(creatorUid),
      builder: (context, snapshot) {
        String creatorName = 'Carregando...';
        if (snapshot.hasData && snapshot.data!.exists) { final data = snapshot.data!.data() as Map<String, dynamic>; creatorName = data['name'] ?? 'Usuário desconhecido';
        } else if (snapshot.hasError || (snapshot.connectionState == ConnectionState.done && !snapshot.data!.exists)) { creatorName = 'Usuário não encontrado'; }
        return Row( children: [
          Icon(Icons.person, size: 14, color: Colors.grey[600]), const SizedBox(width: 4), Text('Adicionado por: ', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          Expanded(child: Text(creatorName, style: TextStyle(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        ]);
      },
    );
  }
}

// --- WIDGET PARA A ABA DE RESPONSÁVEL (COM A NOVA LÓGICA DE BUSCA) ---
class _ResponsibleTab extends StatefulWidget {
  final TruckModel truck;
  const _ResponsibleTab({required this.truck});

  @override
  State<_ResponsibleTab> createState() => _ResponsibleTabState();
}

class _ResponsibleTabState extends State<_ResponsibleTab> {
  final _searchController = TextEditingController();
  final _firestoreService = FirestoreService();
  
  Future<QuerySnapshot>? _searchFuture;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _assignResponsible(String responsibleUserId) async {
    try {
      await _firestoreService.assignResponsibleToTruck(widget.truck.ownerId, widget.truck.id, responsibleUserId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Responsável atribuído com sucesso!'), backgroundColor: Colors.green));
      setState(() {
        _searchFuture = null;
        _searchController.clear();
      });
    } catch (error) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atribuir responsável: $error'), backgroundColor: Colors.red));
    }
  }

  void _removeResponsible() async {
    try {
      await _firestoreService.removeResponsibleFromTruck(widget.truck.ownerId, widget.truck.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Responsável removido com sucesso!'), backgroundColor: Colors.orange));
    } catch(error) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao remover responsável: $error'), backgroundColor: Colors.red));
    }
  }
  
  void _performSearch() {
    final email = _searchController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite um e-mail para buscar.'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() {
      _searchFuture = _firestoreService.findEmployeeByEmail(email);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Responsável Atual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: FutureBuilder<DocumentSnapshot>(
              future: widget.truck.responsibleUserId != null && widget.truck.responsibleUserId!.isNotEmpty
                  ? _firestoreService.getUserById(widget.truck.responsibleUserId!)
                  : null,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) { return const ListTile(title: Center(child: LinearProgressIndicator())); }
                if (snapshot.hasData && snapshot.data!.exists) {
                    final responsibleData = snapshot.data!.data() as Map<String, dynamic>;
                    final name = responsibleData['name'] ?? 'Nome não encontrado';
                    return ListTile(
                      leading: const Icon(Icons.person, color: Colors.blue),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _removeResponsible, tooltip: 'Remover Responsável'),
                    );
                }
                return const ListTile(leading: Icon(Icons.person_off_outlined, color: Colors.grey), title: Text('Nenhum responsável atribuído'));
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text('Atribuir Novo Responsável', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'E-mail completo do funcionário',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _performSearch,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                ),
                tooltip: 'Buscar',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchResults(),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchFuture == null) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Digite um e-mail e clique em buscar.')),
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return SizedBox(height: 100, child: Center(child: Text('Erro na busca: ${snapshot.error}')));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'Nenhum funcionário encontrado com este e-mail.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final userDoc = snapshot.data!.docs.first;
        final userData = userDoc.data() as Map<String, dynamic>;
        final userName = userData['name'] ?? 'Sem nome';
        final userEmail = userData['email'] ?? 'Sem e-mail';
        final userId = userDoc.id;

        if (userId == widget.truck.responsibleUserId) {
          return Card(
            color: Colors.green[100],
            child: ListTile(
              title: Text(userName),
              subtitle: Text(userEmail),
              trailing: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 4),
                  Text('Já é o responsável'),
                ],
              ),
            ),
          );
        }

        return Card(
          color: Colors.blue[50],
          child: ListTile(
            title: Text(userName),
            subtitle: Text(userEmail),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _assignResponsible(userId),
              child: const Text('Atribuir'),
            ),
          ),
        );
      },
    );
  }
}