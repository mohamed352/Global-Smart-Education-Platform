import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:global_smart_education_platform/core/di/injection.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';
import 'package:global_smart_education_platform/features/education/data/services/sync_manager.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/dashboard_cubit.dart';
import 'package:global_smart_education_platform/features/education/presentation/pages/dashboard_page.dart';
import 'package:global_smart_education_platform/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log.i('Firebase initialized');

  // Initialize dependency injection
  await configureDependencies();
  log.i('Dependencies configured');

  // Initialize SyncManager (connectivity listener)
  final SyncManager syncManager = getIt<SyncManager>();
  syncManager.initialize();

  // Seed initial data (Users & Lessons from mock)
  await syncManager.seedInitialData();

  runApp(const EducationApp());
}

class EducationApp extends StatelessWidget {
  const EducationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardCubit>(
      create: (_) => getIt<DashboardCubit>(),
      child: MaterialApp(
        title: 'Offline-First Education POC',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const DashboardPage(),
      ),
    );
  }
}
