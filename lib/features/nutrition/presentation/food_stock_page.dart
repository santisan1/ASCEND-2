import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../nueva_pagina.dart';

class FoodStockPage extends StatefulWidget {
  const FoodStockPage({super.key});

  @override
  State<FoodStockPage> createState() => _FoodStockPageState();
}

class _FoodStockPageState extends State<FoodStockPage> {
  Future<void> _showAddStockDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nameC = TextEditingController();
    final qtyC = TextEditingController();
    String unit = 'unidad';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Agregar stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Alimento')),
              const SizedBox(height: 8),
              TextField(controller: qtyC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Cantidad')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: unit,
                dropdownColor: AppColors.surfaceDark,
                items: const [
                  DropdownMenuItem(value: 'unidad', child: Text('unidad')),
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'g', child: Text('g')),
                  DropdownMenuItem(value: 'L', child: Text('L')),
                  DropdownMenuItem(value: 'ml', child: Text('ml')),
                ],
                onChanged: (v) => setStateDialog(() => unit = v ?? 'unidad'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final qty = double.tryParse(qtyC.text.trim()) ?? 0;
    if (nameC.text.trim().isEmpty || qty <= 0) return;

    final docId = nameC.text.trim().toLowerCase().replaceAll(' ', '_');
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('stock').doc(docId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = (snap.data()?['quantity'] ?? 0).toDouble();
      tx.set(ref, {
        'name': nameC.text.trim(),
        'quantity': current + qty,
        'unit': unit,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> _showMealDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final mealNameC = TextEditingController();
    final caloriesC = TextEditingController();
    final proteinC = TextEditingController();
    final carbsC = TextEditingController();
    final fatsC = TextEditingController();
    final ingredientC = TextEditingController();
    final ingredientQtyC = TextEditingController();
    final totalServingsC = TextEditingController(text: '1');
    final consumedServingsC = TextEditingController(text: '1');

    final ingredients = <Map<String, dynamic>>[];

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Registrar comida'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: mealNameC, decoration: const InputDecoration(labelText: 'Comida')),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: caloriesC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'kcal'))),
                  const SizedBox(width: 6),
                  Expanded(child: TextField(controller: proteinC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prot (g)'))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: carbsC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carbs (g)'))),
                  const SizedBox(width: 6),
                  Expanded(child: TextField(controller: fatsC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Grasas (g)'))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: totalServingsC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Porciones receta'))),
                  const SizedBox(width: 6),
                  Expanded(child: TextField(controller: consumedServingsC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Porciones comidas'))),
                ]),
                const Divider(height: 20),
                TextField(controller: ingredientC, decoration: const InputDecoration(labelText: 'Ingrediente (stock)')),
                const SizedBox(height: 8),
                TextField(controller: ingredientQtyC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Cantidad usada en receta completa')),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final name = ingredientC.text.trim();
                      final qty = double.tryParse(ingredientQtyC.text.trim()) ?? 0;
                      if (name.isEmpty || qty <= 0) return;
                      setStateDialog(() {
                        ingredients.add({'name': name, 'quantity': qty});
                        ingredientC.clear();
                        ingredientQtyC.clear();
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar ingrediente'),
                  ),
                ),
                if (ingredients.isNotEmpty)
                  ...ingredients.map((e) => Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('• ${e['name']}: ${e['quantity']}'),
                        ),
                      )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar comida')),
          ],
        ),
      ),
    );

    if (ok != true || mealNameC.text.trim().isEmpty) return;

    final totalServings = double.tryParse(totalServingsC.text.trim()) ?? 1;
    final consumedServings = double.tryParse(consumedServingsC.text.trim()) ?? 1;
    final ratio = (consumedServings / totalServings).clamp(0.0, 1.0);

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final mealRef = userRef.collection('meals').doc();

    final batch = FirebaseFirestore.instance.batch();

    batch.set(mealRef, {
      'name': mealNameC.text.trim(),
      'calories': double.tryParse(caloriesC.text.trim()) ?? 0,
      'proteinG': double.tryParse(proteinC.text.trim()) ?? 0,
      'carbsG': double.tryParse(carbsC.text.trim()) ?? 0,
      'fatG': double.tryParse(fatsC.text.trim()) ?? 0,
      'ingredients': ingredients,
      'recipeServings': totalServings,
      'consumedServings': consumedServings,
      'consumedRatio': ratio,
      'createdAt': FieldValue.serverTimestamp(),
    });

    for (final ing in ingredients) {
      final name = (ing['name'] as String).trim();
      final docId = name.toLowerCase().replaceAll(' ', '_');
      final stockRef = userRef.collection('stock').doc(docId);
      final snap = await stockRef.get();
      final current = (snap.data()?['quantity'] ?? 0).toDouble();
      final used = (ing['quantity'] as num).toDouble() * ratio;
      final next = (current - used).clamp(0.0, 9999999.0);

      batch.set(stockRef, {
        'name': name,
        'quantity': next,
        'unit': snap.data()?['unit'] ?? 'unidad',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Iniciá sesión')));
    }

    final mealsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('meals')
        .orderBy('createdAt', descending: true)
        .limit(10);

    final stockRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('stock')
        .where(FieldPath.documentId, isNotEqualTo: '_meta');

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Comidas & Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Carga por ticket OCR',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NuevaPagina()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showMealDialog,
                  icon: const Icon(Icons.restaurant),
                  label: const Text('Registrar comida'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddStockDialog,
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('Agregar stock'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Stock actual', style: AppTextStyles.h4.copyWith(color: AppColors.textPrimaryDark)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: stockRef.snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return _emptyBox('Sin stock cargado todavía');
              }
              return Column(
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return ListTile(
                    tileColor: AppColors.surfaceDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    title: Text('${data['name']}', style: const TextStyle(color: AppColors.textPrimaryDark)),
                    subtitle: Text('Disponible: ${(data['quantity'] ?? 0).toStringAsFixed(2)} ${data['unit'] ?? ''}', style: const TextStyle(color: AppColors.textSecondaryDark)),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          Text('Comidas recientes', style: AppTextStyles.h4.copyWith(color: AppColors.textPrimaryDark)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: mealsRef.snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return _emptyBox('Sin comidas registradas');
              }
              return Column(
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return ListTile(
                    tileColor: AppColors.surfaceDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    title: Text('${data['name']}', style: const TextStyle(color: AppColors.textPrimaryDark)),
                    subtitle: Text('kcal ${(data['calories'] ?? 0)} · P ${(data['proteinG'] ?? 0)}g · C ${(data['carbsG'] ?? 0)}g · G ${(data['fatG'] ?? 0)}g', style: const TextStyle(color: AppColors.textSecondaryDark)),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.textSecondaryDark)),
    );
  }
}
