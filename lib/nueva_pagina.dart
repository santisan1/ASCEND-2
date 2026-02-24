import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Modelo mejorado con unidad de medida
class DetectedItem {
  String name;
  double quantity;
  String unit; // 'unidad', 'kg', 'g', 'L', 'ml'
  String originalLine;

  DetectedItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.originalLine,
  });

  @override
  String toString() =>
      '${quantity.toStringAsFixed(unit == "unidad" ? 0 : 2)} $unit de $name';
}

class NuevaPagina extends StatefulWidget {
  const NuevaPagina({super.key});

  @override
  State<NuevaPagina> createState() => _TicketOcrPageState();
}

class _TicketOcrPageState extends State<NuevaPagina> {
  File? _selectedImage;
  String _extractedText = '';
  List<DetectedItem> _detectedItems = [];
  bool _isProcessing = false;
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  // Lista de unidades soportadas
  final List<String> _availableUnits = ['unidad', 'kg', 'g', 'L', 'ml'];

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  // ---------------------
  // Manejo de imagen
  // ---------------------
  Future<void> _takePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (picked == null) return;
    _setImage(File(picked.path));
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (picked == null) return;
    _setImage(File(picked.path));
  }

  void _setImage(File image) {
    setState(() {
      _selectedImage = image;
      _extractedText = '';
      _detectedItems = [];
    });
    _processImage();
  }

  // ---------------------
  // Procesamiento OCR
  // ---------------------
  Future<void> _processImage() async {
    if (_selectedImage == null) return;
    setState(() => _isProcessing = true);

    try {
      final inputImage = InputImage.fromFilePath(_selectedImage!.path);
      final recognized = await _textRecognizer.processImage(inputImage);

      final text = recognized.text;
      setState(() {
        _extractedText = text;
      });

      _extractItemsFromText(text);

      _showToast("Texto extraído correctamente");
    } catch (e) {
      setState(() {
        _extractedText = 'Error: $e';
        _detectedItems = [];
      });
      _showToast("Error al procesar imagen", isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // ---------------------
  // PARSER mejorado con unidades
  // ---------------------
  void _extractItemsFromText(String rawText) {
    final lines = rawText.split(RegExp(r'\r?\n'));
    final List<DetectedItem> found = [];

    // Patrones para unidades
    final unitPattern = RegExp(
      r'(kg|g|gr|gramo|kilo|ml|l|litro|lt|un|u|ud|unidad)',
      caseSensitive: false,
    );
    final pricePattern = RegExp(r'\d+[.,]\d{2}'); // Precios
    final quantityPattern = RegExp(
      r'(\d+[.,]?\d*)\s*(kg|g|gr|ml|l|lt|un|u|ud|x)?',
    );

    for (String rawLine in lines) {
      String line = rawLine.trim();
      if (line.isEmpty) continue;

      // Saltar líneas comunes de ticket
      if (_isCommonTicketText(line)) continue;

      // Extraer información de la línea
      Map<String, dynamic>? extracted = _parseLine(line);
      if (extracted == null) continue;

      // Crear item detectado
      final item = DetectedItem(
        name: extracted['name'],
        quantity: extracted['quantity'],
        unit: extracted['unit'],
        originalLine: rawLine,
      );

      // Verificar si ya existe un producto similar
      final existingIndex = found.indexWhere(
        (existing) =>
            _normalize(existing.name) == _normalize(item.name) &&
            existing.unit == item.unit,
      );

      if (existingIndex >= 0) {
        // Sumar cantidades
        found[existingIndex] = DetectedItem(
          name: found[existingIndex].name,
          quantity: found[existingIndex].quantity + item.quantity,
          unit: item.unit,
          originalLine: '${found[existingIndex].originalLine} + $rawLine',
        );
      } else {
        found.add(item);
      }
    }

    setState(() {
      _detectedItems = found;
    });
  }

  // ---------------------
  // Parseo de línea individual
  // ---------------------
  Map<String, dynamic>? _parseLine(String line) {
    String cleanLine = line;

    // Remover precios
    cleanLine = cleanLine.replaceAll(RegExp(r'\d+[.,]\d{2}'), '').trim();

    // Detectar unidad
    String unit = 'unidad';
    double quantity = 1.0;
    String productName = cleanLine;

    // Buscar patrones de unidad
    final unitMatch = RegExp(
      r'(\d+[.,]?\d*)\s*(kg|g|gr|ml|l|lt|un|u|ud|x)?\s*(.+)?',
      caseSensitive: false,
    ).firstMatch(cleanLine);

    if (unitMatch != null) {
      // Extraer cantidad
      final qtyStr = unitMatch.group(1)?.replaceAll(',', '.') ?? '1';
      quantity = double.tryParse(qtyStr) ?? 1.0;

      // Determinar unidad
      final unitStr = unitMatch.group(2)?.toLowerCase() ?? '';
      if (unitStr.isNotEmpty) {
        if (unitStr.contains('kg') || unitStr.contains('kilo'))
          unit = 'kg';
        else if (unitStr.contains('g') || unitStr.contains('gr'))
          unit = 'g';
        else if (unitStr.contains('l') ||
            unitStr.contains('lt') ||
            unitStr.contains('litro'))
          unit = 'L';
        else if (unitStr.contains('ml'))
          unit = 'ml';
        else if (unitStr.contains('x'))
          unit = 'unidad';
        else if (unitStr.contains('un') ||
            unitStr.contains('u') ||
            unitStr.contains('ud'))
          unit = 'unidad';
      }

      // Extraer nombre del producto
      productName =
          unitMatch.group(3)?.trim() ??
          cleanLine.substring(unitMatch.end).trim();

      // Si no se encontró nombre en el patrón, intentar extraerlo de otra manera
      if (productName.isEmpty) {
        // Buscar texto después de la cantidad y posible unidad
        final afterQty = cleanLine.substring(unitMatch.end).trim();
        if (afterQty.isNotEmpty) {
          productName = afterQty;
        }
      }
    } else {
      // Si no hay patrón claro, buscar número al inicio
      final simpleMatch = RegExp(
        r'^(\d+[.,]?\d*)\s+(.+)$',
      ).firstMatch(cleanLine);
      if (simpleMatch != null) {
        final qtyStr = simpleMatch.group(1)?.replaceAll(',', '.') ?? '1';
        quantity = double.tryParse(qtyStr) ?? 1.0;
        productName = simpleMatch.group(2)?.trim() ?? '';
        unit = 'unidad';
      }
    }

    // Limpiar nombre del producto
    productName = _cleanProductName(productName);

    // Validar
    if (productName.length < 2 || _isCommonTicketText(productName)) {
      return null;
    }

    return {
      'name': _titleCase(productName),
      'quantity': quantity,
      'unit': unit,
    };
  }

  // ---------------------
  // Helpers
  // ---------------------
  String _cleanProductName(String s) {
    var name = s;

    // Remover símbolos de moneda y caracteres especiales
    name = name.replaceAll(RegExp(r'[\$€£]'), '');

    // Remover unidades que puedan estar mezcladas en el nombre
    name = name.replaceAll(
      RegExp(r'\s*(kg|g|gr|ml|l|lt|un|u|ud|x)\b', caseSensitive: false),
      '',
    );

    // Remover números sueltos
    name = name.replaceAll(RegExp(r'^\d+\s*'), '');

    // Remover caracteres especiales
    name = name.replaceAll(RegExp(r'[^A-Za-z0-9ÁÉÍÓÚÜÑáéíóúüñ\s\-]'), ' ');

    // Limpiar espacios múltiples
    name = name.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    return name;
  }

  String _normalize(String s) {
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9áéíóúüñ\s]'), '').trim();
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;

    final parts = s.split(RegExp(r'\s+'));
    final transformed = parts.map((p) {
      if (p.isEmpty) return p;
      final lower = p.toLowerCase();
      return lower[0].toUpperCase() +
          (lower.length > 1 ? lower.substring(1) : '');
    }).toList();

    return transformed.join(' ');
  }

  bool _isCommonTicketText(String text) {
    final t = text.toLowerCase();
    final common = [
      'total',
      'ticket',
      'factura',
      'iva',
      'caja',
      'cajero',
      'supermercado',
      'mercado',
      'compra',
      'pago',
      'tarjeta',
      'efectivo',
      'vuelto',
      'cambio',
      'gracias',
      'cliente',
      'sucursal',
      'hora',
      'fecha',
      'importe',
      'descuento',
      'bonificacion',
      'subtotal',
      'operacion',
      'cuit',
      'código',
      'codigo',
      'rut',
      'cantidad',
      'descripción',
      'precio',
      'unitario',
    ];

    // También considerar líneas muy cortas o que son solo números
    if (t.length < 3 || RegExp(r'^\d+$').hasMatch(t)) {
      return true;
    }

    return common.any((w) => t.contains(w));
  }

  // ---------------------
  // UI Helpers
  // ---------------------
  void _showToast(String msg, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: msg,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  void _copyFullTextToClipboard() {
    if (_extractedText.isEmpty) {
      _showToast('No hay texto para copiar', isError: true);
      return;
    }
    Clipboard.setData(ClipboardData(text: _extractedText));
    _showToast('Texto copiado al portapapeles');
  }

  void _clearAll() {
    setState(() {
      _selectedImage = null;
      _extractedText = '';
      _detectedItems = [];
      _isProcessing = false;
    });
  }

  // ---------------------
  // Edición de items
  // ---------------------
  void _editItem(int index) {
    final item = _detectedItems[index];
    final TextEditingController nameController = TextEditingController(
      text: item.name,
    );
    final TextEditingController quantityController = TextEditingController(
      text: item.quantity.toStringAsFixed(item.unit == 'unidad' ? 0 : 2),
    );
    String selectedUnit = item.unit;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedUnit,
                      items: _availableUnits.map((unit) {
                        return DropdownMenuItem(value: unit, child: Text(unit));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) selectedUnit = value;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Unidad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newQuantity =
                  double.tryParse(
                    quantityController.text.replaceAll(',', '.'),
                  ) ??
                  1.0;

              if (newName.isEmpty) {
                _showToast('El nombre no puede estar vacío', isError: true);
                return;
              }

              setState(() {
                _detectedItems[index] = DetectedItem(
                  name: newName,
                  quantity: newQuantity,
                  unit: selectedUnit,
                  originalLine: item.originalLine,
                );
              });

              Navigator.pop(context);
              _showToast('Producto actualizado');
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _addItemManually() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController(
      text: '1',
    );
    String selectedUnit = 'unidad';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Producto Manualmente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedUnit,
                      items: _availableUnits.map((unit) {
                        return DropdownMenuItem(value: unit, child: Text(unit));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) selectedUnit = value;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Unidad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final quantity =
                  double.tryParse(
                    quantityController.text.replaceAll(',', '.'),
                  ) ??
                  1.0;

              if (name.isEmpty) {
                _showToast('El nombre no puede estar vacío', isError: true);
                return;
              }

              setState(() {
                _detectedItems.add(
                  DetectedItem(
                    name: name,
                    quantity: quantity,
                    unit: selectedUnit,
                    originalLine: 'Agregado manualmente',
                  ),
                );
              });

              Navigator.pop(context);
              _showToast('Producto agregado');
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Eliminar "${_detectedItems[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _detectedItems.removeAt(index);
              });
              Navigator.pop(context);
              _showToast('Producto eliminado');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _saveToStock() {
    if (_detectedItems.isEmpty) {
      _showToast('No hay productos para guardar', isError: true);
      return;
    }

    // Aquí iría tu lógica para guardar en base de datos
    // Por ahora solo mostramos un resumen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resumen del Stock'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Se agregarán los siguientes productos:'),
              const SizedBox(height: 16),
              ..._detectedItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('• ${item.toString()}'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '(En una implementación real, aquí se guardaría en la base de datos)',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar guardado real aquí
              debugPrint('Guardando ${_detectedItems.length} productos...');
              _showToast('Stock actualizado correctamente');
              Navigator.pop(context);
            },
            child: const Text('Confirmar y Guardar'),
          ),
        ],
      ),
    );
  }

  // ---------------------
  // Build
  // ---------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Lector de Tickets con Unidades'),
        actions: [
          if (_selectedImage != null || _extractedText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _clearAll,
              tooltip: 'Limpiar todo',
            ),
          IconButton(
            icon: const Icon(Icons.copy_all),
            onPressed: _copyFullTextToClipboard,
            tooltip: 'Copiar texto extraído',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sección de imagen
            _buildImageSection(),

            const SizedBox(height: 16),

            // Botones de acción
            _buildActionButtons(),

            const SizedBox(height: 16),

            // Indicador de procesamiento
            if (_isProcessing) _buildProcessingIndicator(),

            const SizedBox(height: 16),

            // Productos detectados
            if (_detectedItems.isNotEmpty) _buildDetectedItemsSection(),

            const SizedBox(height: 16),

            // Texto extraído
            if (_extractedText.isNotEmpty) _buildRawTextSection(),
          ],
        ),
      ),
      floatingActionButton: _detectedItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _saveToStock,
              icon: const Icon(Icons.save),
              label: const Text('Guardar Stock'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.receipt, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Ticket de Compra',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _selectedImage == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Selecciona una imagen del ticket',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('Tomar Foto'),
            onPressed: _takePhoto,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text('Galería'),
            onPressed: _pickFromGallery,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blueGrey,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Agregar'),
          onPressed: _addItemManually,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            backgroundColor: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingIndicator() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Procesando ticket...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Extrayendo productos y unidades',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectedItemsSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Productos Detectados (${_detectedItems.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            ..._detectedItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 1,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade50,
                    child: Text(
                      item.quantity.toStringAsFixed(
                        item.unit == 'unidad' ? 0 : 1,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${item.quantity.toStringAsFixed(item.unit == 'unidad' ? 0 : 2)} ${item.unit}',
                    style: const TextStyle(color: Colors.blue),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editItem(index),
                        tooltip: 'Editar',
                        color: Colors.blue,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _deleteItem(index),
                        tooltip: 'Eliminar',
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRawTextSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_fields, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Texto Extraído',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: _copyFullTextToClipboard,
                  tooltip: 'Copiar texto',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: SelectableText(
                  _extractedText,
                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
