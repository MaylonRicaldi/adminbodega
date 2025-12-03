import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pedidos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal.shade600,
        centerTitle: true,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Usuarios').snapshots(),
        builder: (context, usuariosSnapshot) {
          if (usuariosSnapshot.hasError) {
            return Center(child: Text('Error: ${usuariosSnapshot.error}'));
          }
          if (usuariosSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final usuariosDocs = usuariosSnapshot.data?.docs ?? [];

          return StreamBuilder<List<QueryDocumentSnapshot>>(
            stream: _pedidosStream(usuariosDocs),
            builder: (context, pedidosSnapshot) {
              final pedidosDocs = pedidosSnapshot.data ?? [];

              int pendientes = 0, entregados = 0, rechazados = 0;
              for (var pedidoDoc in pedidosDocs) {
                final estado = (pedidoDoc.data() as Map<String, dynamic>)['estado'] ?? '';
                if (estado == 'Pendiente') pendientes++;
                if (estado == 'Entregado') entregados++;
                if (estado == 'Rechazado') rechazados++;
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildResumenCard('Pendientes', pendientes, Colors.orange),
                          _buildResumenCard('Entregado', entregados, Colors.green),
                          _buildResumenCard('Rechazado', rechazados, Colors.red),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, uIndex) {
                        final usuarioDoc = usuariosDocs[uIndex];
                        final usuarioData = usuarioDoc.data() as Map<String, dynamic>;
                        final nombreUsuario = usuarioData['nombre'] ?? '';
                        final uidUsuario = usuarioDoc.id;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombreUsuario,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('Usuarios')
                                    .doc(uidUsuario)
                                    .collection('Pedidos')
                                    .orderBy('fecha', descending: true)
                                    .snapshots(),
                                builder: (context, userPedidosSnap) {
                                  if (userPedidosSnap.hasError) {
                                    return Text('Error: ${userPedidosSnap.error}');
                                  }
                                  if (!userPedidosSnap.hasData) {
                                    return const CircularProgressIndicator();
                                  }

                                  final pedidos = userPedidosSnap.data?.docs ?? [];
                                  if (pedidos.isEmpty) return const Text('No hay pedidos.');

                                  return Column(
                                    children: pedidos.map((pedidoDoc) {
                                      final pedidoData = pedidoDoc.data() as Map<String, dynamic>;

                                      String fechaStr = '';
                                      final fechaData = pedidoData['fecha'];
                                      if (fechaData is Timestamp) {
                                        fechaStr = DateFormat('dd/MM/yyyy HH:mm').format(fechaData.toDate());
                                      } else if (fechaData is String) {
                                        fechaStr = fechaData;
                                      }

                                      final estado = pedidoData['estado'] ?? '';
                                      final metodoPago = pedidoData['metodoPago'] ?? '';
                                      final productos = pedidoData['productos'] as List<dynamic>? ?? [];
                                      final igv = pedidoData['igv'] ?? 0.0;

                                      // Solo mostrar botones si el pedido está pendiente
                                      bool isPendiente = estado == 'Pendiente';

                                      return isPendiente
                                          ? Card(
                                              elevation: 3,
                                              margin: const EdgeInsets.symmetric(vertical: 6),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(16),
                                                  gradient: LinearGradient(
                                                    colors: [Colors.white, Colors.purple.shade50],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          'Pendiente',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.orange,
                                                          ),
                                                        ),
                                                        Text(fechaStr, style: const TextStyle(fontSize: 12)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text('Método de pago: $metodoPago', style: const TextStyle(fontSize: 12)),
                                                    Text('IGV: \$${igv.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                                                    const Divider(),
                                                    const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
                                                    const SizedBox(height: 4),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: productos.map((prod) {
                                                        final p = prod as Map<String, dynamic>;
                                                        return Text(
                                                          '${p['nombre']} x${p['cantidad']} - \$${p['total']}',
                                                          style: const TextStyle(fontSize: 12),
                                                        );
                                                      }).toList(),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.green),
                                                          onPressed: () {
                                                            _actualizarEstado(uidUsuario, pedidoDoc.id, 'Entregado');
                                                          },
                                                          child: const Text('Entregado'),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.red),
                                                          onPressed: () {
                                                            _actualizarEstado(uidUsuario, pedidoDoc.id, 'Rechazado');
                                                          },
                                                          child: const Text('Rechazado'),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              ),
                                            )
                                          : Card(
                                              elevation: 3,
                                              margin: const EdgeInsets.symmetric(vertical: 6),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(16),
                                                  gradient: LinearGradient(
                                                    colors: [Colors.white, Colors.purple.shade50],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          estado,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: estado == 'Entregado'
                                                                ? Colors.green
                                                                : Colors.red,
                                                          ),
                                                        ),
                                                        Text(fechaStr, style: const TextStyle(fontSize: 12)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text('Método de pago: $metodoPago', style: const TextStyle(fontSize: 12)),
                                                    Text('IGV: \$${igv.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                                                    const Divider(),
                                                    const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
                                                    const SizedBox(height: 4),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: productos.map((prod) {
                                                        final p = prod as Map<String, dynamic>;
                                                        return Text(
                                                          '${p['nombre']} x${p['cantidad']} - \$${p['total']}',
                                                          style: const TextStyle(fontSize: 12),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: usuariosDocs.length,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _actualizarEstado(String uidUsuario, String pedidoId, String nuevoEstado) {
    FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(uidUsuario)
        .collection('Pedidos')
        .doc(pedidoId)
        .update({'estado': nuevoEstado});
  }

  Stream<List<QueryDocumentSnapshot>> _pedidosStream(List<QueryDocumentSnapshot> usuariosDocs) {
    final controller = StreamController<List<QueryDocumentSnapshot>>();
    final subs = <StreamSubscription>[];

    void actualizar() async {
      List<QueryDocumentSnapshot> allPedidos = [];
      for (var uDoc in usuariosDocs) {
        final pedidosSnap = await FirebaseFirestore.instance
            .collection('Usuarios')
            .doc(uDoc.id)
            .collection('Pedidos')
            .get();
        allPedidos.addAll(pedidosSnap.docs);
      }
      controller.add(allPedidos);
    }

    for (var uDoc in usuariosDocs) {
      final sub = FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(uDoc.id)
          .collection('Pedidos')
          .snapshots()
          .listen((_) => actualizar());
      subs.add(sub);
    }

    actualizar();

    controller.onCancel = () {
      for (var s in subs) s.cancel();
    };

    return controller.stream;
  }

  Widget _buildResumenCard(String titulo, int cantidad, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [Colors.white, color.withOpacity(0.1)]),
        ),
        child: Column(
          children: [
            Text(
              '$cantidad',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(titulo, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}
