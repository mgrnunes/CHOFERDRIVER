// lib/screens/profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<Map<String, dynamic>?> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final snapshot = await FirebaseFirestore.instance.collection('motoristas').doc(uid).get();
    return snapshot.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Motorista'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Dados não encontrados.'));
          }

          final data = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                InfoTile(label: 'Nome', value: data['nome']),
                InfoTile(label: 'CPF', value: data['cpf']),
                InfoTile(label: 'CNH', value: data['cnh']),
                InfoTile(label: 'Telefone', value: data['telefone']),
                InfoTile(label: 'Email', value: data['email']),
                InfoTile(label: 'Veículo', value: data['veiculo']),
                InfoTile(label: 'Placa', value: data['placa']),
                InfoTile(label: 'Categoria', value: data['categoria']),
                const SizedBox(height: 20),
                if (data['cnhUrl'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Foto da CNH:'),
                      const SizedBox(height: 8),
                      Image.network(data['cnhUrl'], height: 150),
                    ],
                  ),
                const SizedBox(height: 20),
                if (data['docVeiculoUrl'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Documento do Veículo:'),
                      const SizedBox(height: 8),
                      Image.network(data['docVeiculoUrl'], height: 150),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const InfoTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
    );
  }
}
