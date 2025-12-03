import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Usuarios',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade600,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Usuarios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final nombre = data['nombre'] ?? '';
              final email = data['email'] ?? '';
              final uid = data['uid'] ?? '';
              final fotoBase64 = data['fotoBase64'] ?? '';

              // Manejo de fecha
              String fechaRegistroStr = '';
              final fechaRegistroData = data['fechaRegistro'];
              if (fechaRegistroData is Timestamp) {
                final fechaRegistro = fechaRegistroData.toDate();
                fechaRegistroStr =
                    '${fechaRegistro.day}/${fechaRegistro.month}/${fechaRegistro.year} ${fechaRegistro.hour}:${fechaRegistro.minute.toString().padLeft(2, '0')}';
              } else if (fechaRegistroData is String) {
                fechaRegistroStr = fechaRegistroData;
              }

              // Avatar con fondo teal suave
              Widget avatar;
              if (fotoBase64.isNotEmpty) {
                try {
                  avatar = CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.teal.shade50,
                    backgroundImage: MemoryImage(base64Decode(fotoBase64)),
                  );
                } catch (e) {
                  avatar = CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.teal.shade50,
                    child: const Icon(Icons.person, color: Colors.teal),
                  );
                }
              } else {
                avatar = CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.teal.shade50,
                  child: const Icon(Icons.person, color: Colors.teal),
                );
              }

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                shadowColor: Colors.teal.withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ListTile(
                    leading: avatar,
                    title: Text(
                      nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(email, style: TextStyle(color: Colors.grey.shade700)),
                        const SizedBox(height: 2),
                        Text('Registrado: $fechaRegistroStr', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        Text('UID: $uid', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
