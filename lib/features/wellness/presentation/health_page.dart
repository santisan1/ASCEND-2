import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  final _stepsController = TextEditingController();
  final _waterController = TextEditingController();

  @override
  void dispose() {
    _stepsController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  Future<void> _saveTodayMetrics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final dayId = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('health_daily')
        .doc(dayId)
        .set({
          'date': dayId,
          'steps': int.tryParse(_stepsController.text.trim()) ?? 0,
          'waterMl': int.tryParse(_waterController.text.trim()) ?? 0,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salud diaria guardada ✅')),
      );
    }
  }


  Future<void> _openHealthConnect() async {
    final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Salud'),
      ),
      body: user == null
          ? const Center(child: Text('Iniciá sesión para usar Salud'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Carga rápida diaria', style: AppTextStyles.h4.copyWith(color: AppColors.textPrimaryDark)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _stepsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Pasos de hoy'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _waterController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Agua (ml)'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _saveTodayMetrics,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar día'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Conectá Google Health (Health Connect) para traer pasos y calorías automáticas.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _openHealthConnect,
                        icon: const Icon(Icons.link),
                        label: const Text('Conectar Google Health'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
