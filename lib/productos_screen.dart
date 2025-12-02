import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final Color turquesa = Colors.teal.shade400;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery =
            quitarAcentos(_searchController.text.trim().toLowerCase());
      });
    });
  }

  String quitarAcentos(String texto) {
    const acentos = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'ñ': 'n',
      'Ñ': 'N'
    };
    return texto.split('').map((c) => acentos[c] ?? c).join();
  }

  Future<void> actualizarCampo(
      String docId, Map<String, dynamic> cambio) async {
    await FirebaseFirestore.instance
        .collection('productos')
        .doc(docId)
        .update(cambio);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Producto actualizado"),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> eliminarProducto(String docId, String nombreProducto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Confirmar Eliminación'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Estás seguro que deseas eliminar este producto?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nombreProducto,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await FirebaseFirestore.instance.collection('productos').doc(docId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Producto eliminado exitosamente"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al eliminar: ${e.toString()}"),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void mostrarEditor(String docId, Map<String, dynamic> data) {
    final nombreC = TextEditingController(text: data["Nombre"]);
    final precioC = TextEditingController(text: data["Precio"].toString());
    final marcaC = TextEditingController(text: data["Marca"]);
    final stockC = TextEditingController(text: data["Stock"].toString());
    final cantidadC = TextEditingController(text: (data["Cantidad"] ?? '').toString());
    final imagenC = TextEditingController(text: data["imagen"]);
    bool disponibilidad = data["Disponibilidad"] ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 18,
                right: 18,
                top: 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Editar Producto",
                          style: TextStyle(
                            color: turquesa,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_rounded, color: Colors.red.shade400),
                          tooltip: 'Eliminar producto',
                          onPressed: () {
                            Navigator.pop(context);
                            eliminarProducto(docId, data["Nombre"] ?? "");
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Campos de edición
                    ...[
                      {'label': 'Nombre', 'controller': nombreC, 'icon': Icons.shopping_bag_outlined, 'type': TextInputType.text},
                      {'label': 'Precio', 'controller': precioC, 'icon': Icons.attach_money, 'type': TextInputType.number},
                      {'label': 'Marca', 'controller': marcaC, 'icon': Icons.bookmark_outline, 'type': TextInputType.text},
                      {'label': 'Imagen (URL)', 'controller': imagenC, 'icon': Icons.image_outlined, 'type': TextInputType.text},
                      {'label': 'Stock', 'controller': stockC, 'icon': Icons.inventory_2_outlined, 'type': TextInputType.number},
                      {'label': 'Presentación / Contenido', 'controller': cantidadC, 'icon': Icons.square_foot_outlined, 'type': TextInputType.text},
                    ].map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: e['controller'] as TextEditingController,
                          decoration: InputDecoration(
                            labelText: e['label'] as String,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: Icon(e['icon'] as IconData),
                          ),
                          keyboardType: e['type'] as TextInputType,
                        ),
                      );
                    }).toList(),
                    // Switch solo dentro del editor
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Disponibilidad",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          Switch(
                            value: disponibilidad,
                            activeColor: turquesa,
                            onChanged: (v) {
                              setModalState(() {
                                disponibilidad = v;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.close_rounded),
                            label: const Text("Cancelar"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey.shade400),
                              foregroundColor: Colors.grey.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                            label: Text(
                              "Eliminar",
                              style: TextStyle(color: Colors.red.shade400),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.red.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              eliminarProducto(docId, data["Nombre"] ?? "");
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save_rounded),
                            label: const Text("Guardar"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: turquesa,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final cambios = {
                                "Nombre": nombreC.text.trim(),
                                "Precio": double.tryParse(precioC.text) ?? data["Precio"],
                                "Marca": marcaC.text.trim(),
                                "imagen": imagenC.text.trim(),
                                "Disponibilidad": disponibilidad,
                                "Stock": int.tryParse(stockC.text) ?? data["Stock"],
                                "Cantidad": cantidadC.text.trim(),
                              };
                              if (cambios["Stock"] <= 0) {
                                cambios["Stock"] = 0;
                                cambios["Disponibilidad"] = false;
                              }
                              await actualizarCampo(docId, cambios);
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: turquesa,
        centerTitle: true,
        title: const Text(
          "Gestión de Productos",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('productos')
                  .orderBy('Nombre')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nombre =
                      quitarAcentos((data['Nombre'] ?? '').toString().toLowerCase())
                          .trim();
                  return nombre.contains(_searchQuery);
                }).toList();

                if (docs.isEmpty) return const Center(child: Text("No se encontraron productos"));

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    childAspectRatio: 1.25,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    final nombre = data['Nombre'] ?? '';
                    final precio = double.tryParse(data['Precio'].toString()) ?? 0.0;
                    final stock = data['Stock'] ?? 0;
                    final cantidad = (data['Cantidad'] ?? '').toString();
                    final marca = (data['Marca'] ?? '').toString();

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: Icon(Icons.shopping_bag, size: 35, color: turquesa),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          nombre, 
                                          maxLines: 2, 
                                          overflow: TextOverflow.ellipsis, 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => mostrarEditor(docId, data),
                                        child: Icon(Icons.edit, color: turquesa, size: 18),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (marca.isNotEmpty || cantidad.isNotEmpty)
                                    Row(
                                      children: [
                                        if (marca.isNotEmpty)
                                          Flexible(
                                            child: Text(
                                              marca,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        if (marca.isNotEmpty && cantidad.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: Text(
                                              "•",
                                              style: TextStyle(color: Colors.grey[400], fontSize: 10),
                                            ),
                                          ),
                                        if (cantidad.isNotEmpty)
                                          Flexible(
                                            child: Text(
                                              cantidad,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "S/. ${precio.toStringAsFixed(2)}", 
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: turquesa)
                                  ),
                                  Text(
                                    "Stock: $stock", 
                                    style: const TextStyle(fontSize: 11, color: Colors.black87)
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
