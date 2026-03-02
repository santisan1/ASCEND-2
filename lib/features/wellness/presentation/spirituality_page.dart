import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SpiritualityPage extends StatefulWidget {
  const SpiritualityPage({super.key});

  @override
  State<SpiritualityPage> createState() => _SpiritualityPageState();
}

class _SpiritualityPageState extends State<SpiritualityPage> {
  final _devotionalController = TextEditingController();
  final _verseController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _devotionalController.dispose();
    _verseController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_devotionalController.text.trim().isEmpty) return;

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('spiritual_entries')
          .add({
            'devotional': _devotionalController.text.trim(),
            'verse': _verseController.text.trim(),
            'createdAt': Timestamp.now(),
          });
      _devotionalController.clear();
      _verseController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrada espiritual guardada ✅')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Espiritualidad'),
      ),
      body: user == null
          ? const Center(child: Text('Iniciá sesión para registrar tu devocional'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('spiritual_entries')
                  .orderBy('createdAt', descending: true)
                  .limit(30)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Devocional y diario espiritual',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _devotionalController,
                      maxLines: 3,
                      style: const TextStyle(color: AppColors.textPrimaryDark),
                      decoration: const InputDecoration(
                        hintText: '¿Qué aprendiste hoy en tu tiempo con Dios?',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _verseController,
                      style: const TextStyle(color: AppColors.textPrimaryDark),
                      decoration: const InputDecoration(
                        hintText: 'Versículo del día (opcional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _saveEntry,
                      icon: const Icon(Icons.bookmark_add),
                      label: Text(_loading ? 'Guardando...' : 'Guardar entrada'),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Historial reciente (${docs.length})',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final date =
                          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${date.day}/${date.month}/${date.year}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondaryDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data['devotional']?.toString() ?? '',
                              style: const TextStyle(color: AppColors.textPrimaryDark),
                            ),
                            if ((data['verse']?.toString() ?? '').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                '📖 ${data['verse']}',
                                style: const TextStyle(color: AppColors.accent),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}
