import 'package:firebase_core/firebase_core.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:global_smart_education_platform/core/di/injection.dart';
import 'package:global_smart_education_platform/features/education/data/services/sync_manager.dart';
import 'package:global_smart_education_platform/features/education/presentation/screens/main_screen.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/teacher_explanation_cubit.dart';
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

  // NOTE: No Gemma model download required!
  // AI Teacher uses local lesson-content analysis — always ready.
  log.i('AI Teacher engine ready (offline, no model needed)');

  runApp(const EducationApp());
}

class EducationApp extends StatelessWidget {
  const EducationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TeacherExplanationCubit>(
          create: (_) => getIt<TeacherExplanationCubit>(),
        ),
      ],
      child: MaterialApp(
        title: 'Offline-First Education POC',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color.fromARGB(255, 148, 155, 199),
          useMaterial3: true,
        ),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const MainScreen(),
      ),
    );
  }
}
