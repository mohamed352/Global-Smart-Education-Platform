import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_smart_education_platform/core/di/injection.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/dashboard_cubit.dart';
import 'package:global_smart_education_platform/features/education/presentation/pages/dashboard_page.dart';
import 'package:global_smart_education_platform/features/education/presentation/screens/alternative_teacher_screen.dart';

import 'package:global_smart_education_platform/features/education/presentation/screens/ai_teacher_chat_screen.dart';
import 'package:global_smart_education_platform/features/education/presentation/pages/student_progress_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardPage(),
    const AlternativeTeacherScreen(),
    const AiTeacherChatScreen(),
    const StudentProgressPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider<DashboardCubit>(create: (_) => getIt<DashboardCubit>()),
      ],
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'لوحة التحكم',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: 'الدروس',
              ),
              NavigationDestination(
                icon: Icon(Icons.psychology_alt_outlined),
                selectedIcon: Icon(Icons.psychology_alt),
                label: 'المعلم الذكي',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'تقدمي',
              ),
            ],
            indicatorColor: theme.colorScheme.primaryContainer,
            backgroundColor: theme.colorScheme.surface,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          ),
        ),
      ),
    );
  }
}
