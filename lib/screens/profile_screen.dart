import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  String _selectedRole = 'funcionario';
  bool _isSaving = false;
  bool _isEditing = false;
  
  // 1. ADICIONAR UMA FLAG DE CONTROLE
  // Esta flag garantirá que os dados do Firestore só sejam lidos uma vez.
  bool _isDataInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;
    
    final newName = _nameController.text.trim();
    
    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await _firestoreService.updateUserProfile(user.uid, newName, _selectedRole);
      } else {
        // Ao criar, o cargo selecionado pelo usuário no dropdown será usado.
        await _firestoreService.createUserDocument(user.uid, user.email ?? '', newName, _selectedRole);
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil salvo com sucesso!'), backgroundColor: Colors.green),
      );
      
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar o perfil: $e'), backgroundColor: Colors.red),
      );
    } finally {
       if (mounted) setState(() => _isSaving = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: user == null
          ? const Center(child: Text('Nenhum usuário logado.'))
          : FutureBuilder<DocumentSnapshot>(
              future: _firestoreService.getUserById(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. USAR A FLAG DE CONTROLE
                // Só preenchemos os dados se eles ainda não foram inicializados.
                if (snapshot.hasData && snapshot.data!.exists && !_isDataInitialized) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  _nameController.text = userData['name'] as String? ?? '';
                  _selectedRole = userData['role'] as String? ?? 'funcionario';
                  _isEditing = true;
                  // Marca os dados como inicializados.
                  _isDataInitialized = true;
                } else if (!snapshot.hasData || !snapshot.data!.exists) {
                  _isEditing = false;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProfileInfoCard('E-mail', user.email ?? 'Não disponível', Icons.email),
                        const SizedBox(height: 16),
                        _buildNameTextField(),
                        const SizedBox(height: 24),
                        const Text('Seu Cargo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildRoleSelectorCard(),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isSaving ? null : _submitProfile,
                          child: _isSaving
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : Text(_isEditing ? 'Salvar Alterações' : 'Criar Perfil', style: const TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildNameTextField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16, top: 4, bottom: 4),
        child: TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            icon: Icon(Icons.person, color: Colors.grey[600]),
            labelText: 'Nome Completo',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, insira seu nome.';
            }
            return null;
          },
        ),
      ),
    );
  }
  
  Widget _buildProfileInfoCard(String title, String subtitle, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[600]),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
      ),
    );
  }

  Widget _buildRoleSelectorCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedRole,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.blue.shade800),
            items: const [
              DropdownMenuItem(value: 'gerente', child: Text('Gerente', style: TextStyle(fontWeight: FontWeight.w500))),
              DropdownMenuItem(value: 'funcionario', child: Text('Funcionário', style: TextStyle(fontWeight: FontWeight.w500))),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedRole = value);
              }
            },
          ),
        ),
      ),
    );
  }
}