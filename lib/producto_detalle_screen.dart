import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductoDetalleScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final bool soloEliminar;

  const ProductoDetalleScreen({
    required this.docId,
    required this.data,
    this.soloEliminar = false,
    super.key,
  });

  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  late TextEditingController nombreC;
  late TextEditingController precioC;
  late TextEditingController marcaC;
  late TextEditingController stockC;
  late TextEditingController cantidadC;
  late TextEditingController imagenC;
  bool disponibilidad = true;

  final Color turquesa = Colors.teal.shade400;

  @override
  void initState() {
    super.initState();
    final data = widget.data;
    nombreC = TextEditingController(text: data["Nombre"]);
    precioC = TextEditingController(text: data["Precio"].toString());
    marcaC = TextEditingController(text: data["Marca"]);
    stockC = TextEditingController(text: data["Stock"].toString());
    cantidadC = TextEditingController(text: (data["Cantidad"] ?? '').toString());
    imagenC = TextEditingController(text: data["imagen"]);
    disponibilidad = data["Disponibilidad"] ?? true;
  }

  @override
  void dispose() {
    nombreC.dispose();
    precioC.dispose();
    marcaC.dispose();
    stockC.dispose();
    cantidadC.dispose();
    imagenC.dispose();
    super.dispose();
  }

  Future<void> actualizarProducto() async {
    final cambios = {
      "Nombre": nombreC.text.trim(),
      "Precio": double.tryParse(precioC.text) ?? widget.data["Precio"],
      "Marca": marcaC.text.trim(),
      "imagen": imagenC.text.trim(),
      "Disponibilidad": disponibilidad,
      "Stock": int.tryParse(stockC.text) ?? widget.data["Stock"],
      "Cantidad": cantidadC.text.trim(),
    };
    if ((cambios["Stock"] as int) <= 0) {
      cambios["Stock"] = 0;
      cambios["Disponibilidad"] = false;
    }

    await FirebaseFirestore.instance
        .collection('productos')
        .doc(widget.docId)
        .update(cambios);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Producto actualizado"), backgroundColor: Colors.green.shade600),
      );
      Navigator.pop(context);
    }
  }

  Future<void> eliminarProducto() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: const Text("¿Deseas eliminar este producto? Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await FirebaseFirestore.instance.collection('productos').doc(widget.docId).delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Producto eliminado"), backgroundColor: Colors.red.shade600),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final imagenUrl = (data["imagen"] ?? "").toString();
    final nombre = data["Nombre"] ?? "";
    final precio = data["Precio"] ?? 0;
    final marca = data["Marca"] ?? "";
    final stock = data["Stock"] ?? 0;
    final cantidad = data["Cantidad"] ?? "";

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        centerTitle: true, // Texto centrado
        title: Text(
          widget.soloEliminar ? "Eliminar Producto" : "Detalle Producto",
          style: const TextStyle(
            color: Colors.white, // Texto blanco
            fontWeight: FontWeight.bold, // Resaltado
            fontSize: 20,
          ),
        ),
        backgroundColor: turquesa,
        elevation: 4,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 600,
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: Colors.black26,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Imagen
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imagenUrl.isEmpty
                            ? Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.photo, size: 60, color: Colors.grey),
                              )
                            : Image.network(imagenUrl, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Información
                    Center(
                      child: Column(
                        children: [
                          Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                          const SizedBox(height: 6),
                          Text("Precio: S/. $precio", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                          Text("Marca: $marca", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                          Text("Stock: $stock", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                          Text("Cantidad: $cantidad", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Formulario y botones
                    if (!widget.soloEliminar) ...[
                      _buildTextField("Nombre", nombreC),
                      _buildTextField("Precio", precioC, isNumber: true),
                      _buildTextField("Marca", marcaC),
                      _buildTextField("Stock", stockC, isNumber: true),
                      _buildTextField("Cantidad", cantidadC),
                      _buildTextField("Imagen (URL)", imagenC),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Disponibilidad", style: TextStyle(fontWeight: FontWeight.bold)),
                          Switch(
                            value: disponibilidad,
                            activeColor: turquesa,
                            onChanged: (v) => setState(() => disponibilidad = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: actualizarProducto,
                        icon: const Icon(Icons.save),
                        label: const Text("Guardar Cambios"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: turquesa,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: eliminarProducto,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text("Eliminar Producto", style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: eliminarProducto,
                        icon: const Icon(Icons.delete),
                        label: const Text("Eliminar Producto"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }
}
