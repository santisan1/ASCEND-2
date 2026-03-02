import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  Future<void> _openGoogleCalendar(BuildContext context) async {
    final uri = Uri.parse('https://calendar.google.com');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Google Calendar')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Iniciá sesión para ver tu agenda')),
      );
    }

    final eventsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('agenda_events')
        .orderBy('date', descending: false)
        .limit(30);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Agenda'),
        actions: [
          IconButton(
            onPressed: () => _openGoogleCalendar(context),
            icon: const Icon(Icons.link),
            tooltip: 'Abrir Google Calendar',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Conectá tu agenda con Google Calendar para ver eventos reales y sincronizados.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondaryDark),
                  ),
                ),
                TextButton(
                  onPressed: () => _openGoogleCalendar(context),
                  child: const Text('Conectar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: eventsRef.snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariantDark.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Text(
                    'No hay eventos cargados en agenda_events.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondaryDark),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp?)?.toDate();
                  return ListTile(
                    tileColor: AppColors.surfaceDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    title: Text(
                      '${data['title'] ?? 'Evento'}',
                      style: const TextStyle(color: AppColors.textPrimaryDark),
                    ),
                    subtitle: Text(
                      date != null
                          ? '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                          : 'Sin fecha',
                      style: const TextStyle(color: AppColors.textSecondaryDark),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
