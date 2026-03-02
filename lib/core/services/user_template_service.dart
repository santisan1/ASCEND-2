import 'package:cloud_firestore/cloud_firestore.dart';

class UserTemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> ensureUserTemplate(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    final batch = _firestore.batch();

    final dashboardTemplateRef = userRef.collection('settings').doc('dashboard_template');
    final nutritionTargetsRef = userRef.collection('settings').doc('nutrition_targets');
    final healthProfileRef = userRef.collection('settings').doc('health_profile');
    final syncStatusRef = userRef.collection('settings').doc('sync_status');

    final dashboardTemplate = await dashboardTemplateRef.get();
    if (!dashboardTemplate.exists) {
      batch.set(dashboardTemplateRef, {
        'weights': {
          'spirituality': 0.20,
          'habits': 0.25,
          'finance': 0.20,
          'health': 0.20,
          'relationships': 0.15,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final nutritionTargets = await nutritionTargetsRef.get();
    if (!nutritionTargets.exists) {
      batch.set(nutritionTargetsRef, {
        'calories': 2200,
        'proteinG': 140,
        'carbsG': 260,
        'fatG': 70,
        'waterMl': 2500,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    final healthProfile = await healthProfileRef.get();
    if (!healthProfile.exists) {
      batch.set(healthProfileRef, {
        'weightKg': null,
        'heightCm': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    final syncStatus = await syncStatusRef.get();
    if (!syncStatus.exists) {
      batch.set(syncStatusRef, {
        'status': 'synced',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    final stockMetaRef = userRef.collection('stock').doc('_meta');
    final stockMeta = await stockMetaRef.get();
    if (!stockMeta.exists) {
      batch.set(stockMetaRef, {
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'user_template_bootstrap',
      });
    }

    final mealsMetaRef = userRef.collection('meals').doc('_meta');
    final mealsMeta = await mealsMetaRef.get();
    if (!mealsMeta.exists) {
      batch.set(mealsMetaRef, {
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'user_template_bootstrap',
      });
    }

    await batch.commit();
  }
}
