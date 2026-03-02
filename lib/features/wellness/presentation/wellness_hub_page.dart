import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'health_page.dart';
import 'spirituality_page.dart';

class WellnessHubPage extends StatelessWidget {
  const WellnessHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Wellness'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.favorite), text: 'Salud'),
              Tab(icon: Icon(Icons.auto_stories), text: 'Espiritualidad'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HealthPage(),
            SpiritualityPage(),
          ],
        ),
      ),
    );
  }
}
