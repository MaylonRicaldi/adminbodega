import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgregarProductoScreen extends StatefulWidget {
  const AgregarProductoScreen({super.key});

  @override
  State<AgregarProductoScreen> createState() => _AgregarProductoScreenState();
}

class _AgregarProductoScreenState extends State<AgregarProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final idController = TextEditingController();
  final nombreController = TextEditingController();
  final precioController = TextEditingController();
  final marcaController = TextEditingController();
  final stockController = TextEditingController();
  final cantidadController = TextEditingController();
  final imagenController = TextEditingController();

  bool disponibilidad = true;
  bool isLoading = false;
  bool imagenAdaptada = false;
  String? imagenPreview;
  final Color turquesa = Colors.teal.shade400;

  @override
  void dispose() {
    idController.dispose();
    nombreController.dispose();
    precioController.dispose();
    marcaController.dispose();
    stockController.dispose();
    cantidadController.dispose();
    imagenController.dispose();
    super.dispose();
  }

  Future<void> agregarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final idProducto = idController.text.trim();

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('productos')
          .doc(idProducto)
          .get();
      if (docSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('El ID $idProducto ya existe. Usa otro ID.'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      final precio = double.tryParse(precioController.text.trim()) ?? 0.0;
      final stock = int.tryParse(stockController.text.trim()) ?? 0;
      final cantidad = cantidadController.text.trim();
      bool disponible = stock > 0 ? disponibilidad : false;

      final imagenFormateada = imagenPreview ?? imagenController.text.trim();

      await FirebaseFirestore.instance
          .collection('productos')
          .doc(idProducto)
          .set({
        'Nombre': nombreController.text.trim(),
        'Precio': precio,
        'Marca': marcaController.text.trim(),
        'Stock': stock,
        'Cantidad': cantidad,
        'imagen': imagenFormateada,
        'Disponibilidad': disponible,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Producto agregado exitosamente!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      idController.clear();
      nombreController.clear();
      precioController.clear();
      marcaController.clear();
      stockController.clear();
      cantidadController.clear();
      imagenController.clear();
      setState(() {
        disponibilidad = true;
        imagenAdaptada = false;
        imagenPreview = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar producto: ${e.toString()}'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> verificarID() async {
    final idProducto = idController.text.trim();
    if (idProducto.isEmpty) return;

    final docSnapshot =
        await FirebaseFirestore.instance.collection('productos').doc(idProducto).get();
    if (docSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ID ya existe'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ID disponible'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> adaptarImagen() async {
    final urlOriginal = imagenController.text.trim();
    if (urlOriginal.isEmpty) {
      setState(() {
        imagenAdaptada = false;
        imagenPreview = null;
      });
      return;
    }

    // Validamos que sea un enlace de Cloudinary (opcional)
    if (!urlOriginal.contains("cloudinary.com")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor ingresa un enlace de Cloudinary válido"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        imagenAdaptada = false;
        imagenPreview = null;
      });
      return;
    }

    final image = NetworkImage(urlOriginal);
    image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (info, _) {
          setState(() {
            imagenAdaptada = true;
            imagenPreview = urlOriginal;
          });
        },
        onError: (_, __) {
          setState(() {
            imagenAdaptada = false;
            imagenPreview = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No se pudo cargar la imagen"),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: turquesa,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Center(
          child: const Text(
            'Agregar Nuevo Producto',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: Colors.white
            ),
          ),
        ),
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [turquesa.withOpacity(0.1), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: turquesa.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add_shopping_cart_rounded,
                              size: 50, color: turquesa),
                        ),
                        const SizedBox(height: 20),

                        // ID + Botón Verificar
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: idController,
                                decoration: InputDecoration(
                                  labelText: 'ID del Producto *',
                                  hintText: 'Ej: PROD001',
                                  prefixIcon:
                                      Icon(Icons.badge_outlined, color: turquesa),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty)
                                    return 'El ID es obligatorio';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: verificarID,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: turquesa,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Verificar ID'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Nombre
                        TextFormField(
                          controller: nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre del Producto *',
                            hintText: 'Ej: Coca Cola 500ml',
                            prefixIcon:
                                Icon(Icons.shopping_bag_outlined, color: turquesa),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty)
                              return 'El nombre es obligatorio';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Marca
                        TextFormField(
                          controller: marcaController,
                          decoration: InputDecoration(
                            labelText: 'Marca',
                            hintText: 'Ej: Coca Cola',
                            prefixIcon:
                                Icon(Icons.bookmark_outline, color: turquesa),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Presentación / Contenido
                        TextFormField(
                          controller: cantidadController,
                          decoration: InputDecoration(
                            labelText: 'Presentación / Contenido',
                            hintText: 'Ej: 500ml, 1kg, 100g, 2L, 350ml',
                            prefixIcon: Icon(Icons.square_foot_outlined, color: turquesa),
                            helperText: "Tamaño o peso del producto",
                            helperStyle: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Precio
                        TextFormField(
                          controller: precioController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Precio (S/.) *',
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.attach_money, color: turquesa),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty)
                              return 'El precio es obligatorio';
                            final precio = double.tryParse(value.trim());
                            if (precio == null || precio < 0)
                              return 'Ingrese un precio válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Stock
                        TextFormField(
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Stock (Unidades) *',
                            hintText: '0',
                            prefixIcon:
                                Icon(Icons.inventory_2_outlined, color: turquesa),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty)
                              return 'El stock es obligatorio';
                            final stock = int.tryParse(value.trim());
                            if (stock == null || stock < 0)
                              return 'Ingrese un stock válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Imagen + Botón Adaptar
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: imagenController,
                                decoration: InputDecoration(
                                  labelText: 'URL de Imagen (opcional)',
                                  hintText:
                                      'https://res.cloudinary.com/.../imagen.jpg',
                                  prefixIcon:
                                      Icon(Icons.image_outlined, color: turquesa),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: adaptarImagen,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: turquesa,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Adaptar Imagen'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Preview de imagen
                        if (imagenAdaptada && imagenPreview != null)
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imagenPreview!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Disponibilidad
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle_outline, color: turquesa),
                                  const SizedBox(width: 12),
                                  const Text('Producto Disponible',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                              Switch(
                                value: disponibilidad,
                                activeColor: turquesa,
                                onChanged: (value) =>
                                    setState(() => disponibilidad = value),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Botón Guardar
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: isLoading
                              ? Center(
                                  child: CircularProgressIndicator(color: turquesa))
                              : ElevatedButton.icon(
                                  onPressed: agregarProducto,
                                  icon: const Icon(Icons.save_rounded),
                                  label: const Text('Agregar Producto',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: turquesa,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('* Campos obligatorios',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
