// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/education/data/datasources/local/database.dart' as _i228;
import '../../features/education/data/datasources/remote/firebase_remote_data_source.dart'
    as _i898;
import '../../features/education/data/datasources/remote/remote_data_source.dart'
    as _i187;
import '../../features/education/data/repositories/education_repository.dart'
    as _i562;
import '../../features/education/data/repositories/sync_repository.dart'
    as _i187;
import '../../features/education/data/services/gemma_service.dart' as _i694;
import '../../features/education/data/services/lesson_ai_service.dart' as _i477;
import '../../features/education/data/services/media_service.dart' as _i461;
import '../../features/education/data/services/smart_teacher_service.dart'
    as _i666;
import '../../features/education/data/services/sync_manager.dart' as _i388;
import '../../features/education/data/services/teacher_stt_service.dart'
    as _i683;
import '../../features/education/data/services/teacher_tts_service.dart'
    as _i701;
import '../../features/education/presentation/cubit/dashboard_cubit.dart'
    as _i694;
import '../../features/education/presentation/cubit/enhanced_dashboard_cubit.dart'
    as _i239;
import '../../features/education/presentation/cubit/lesson_cubit.dart' as _i247;
import '../../features/education/presentation/cubit/model_installation_cubit.dart'
    as _i472;
import '../../features/education/presentation/cubit/smart_teacher_cubit.dart'
    as _i515;
import '../../features/education/presentation/cubit/student_progress_cubit.dart'
    as _i259;
import '../../features/education/presentation/cubit/teacher_explanation_cubit.dart'
    as _i705;
import 'firebase_module.dart' as _i616;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final firebaseModule = _$FirebaseModule();
    gh.lazySingleton<_i974.FirebaseFirestore>(() => firebaseModule.firestore);
    gh.lazySingleton<_i228.AppDatabase>(() => _i228.AppDatabase());
    gh.lazySingleton<_i187.RemoteDataSource>(() => _i187.RemoteDataSource());
    gh.lazySingleton<_i694.GemmaService>(() => _i694.GemmaService());
    gh.lazySingleton<_i477.LessonAiService>(() => _i477.LessonAiService());
    gh.lazySingleton<_i461.MediaService>(() => _i461.MediaService());
    gh.lazySingleton<_i683.TeacherSttService>(() => _i683.TeacherSttService());
    gh.lazySingleton<_i701.TeacherTtsService>(() => _i701.TeacherTtsService());
    gh.lazySingleton<_i562.EducationRepository>(
      () => _i562.EducationRepository(gh<_i228.AppDatabase>()),
    );
    gh.lazySingleton<_i666.SmartTeacherService>(
      () => _i666.SmartTeacherService(gh<_i694.GemmaService>()),
    );
    gh.lazySingleton<_i472.ModelInstallationCubit>(
      () => _i472.ModelInstallationCubit(gh<_i694.GemmaService>()),
    );
    gh.factory<_i705.TeacherExplanationCubit>(
      () => _i705.TeacherExplanationCubit(
        gh<_i477.LessonAiService>(),
        gh<_i228.AppDatabase>(),
      ),
    );
    gh.lazySingleton<_i898.FirebaseRemoteDataSource>(
      () => _i898.FirebaseRemoteDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.factory<_i247.LessonCubit>(
      () => _i247.LessonCubit(gh<_i562.EducationRepository>()),
    );
    gh.factory<_i259.StudentProgressCubit>(
      () => _i259.StudentProgressCubit(gh<_i562.EducationRepository>()),
    );
    gh.lazySingleton<_i187.SyncRepository>(
      () => _i187.SyncRepository(
        gh<_i187.RemoteDataSource>(),
        gh<_i898.FirebaseRemoteDataSource>(),
      ),
    );
    gh.factory<_i515.SmartTeacherCubit>(
      () => _i515.SmartTeacherCubit(gh<_i666.SmartTeacherService>()),
    );
    gh.lazySingleton<_i388.SyncManager>(
      () => _i388.SyncManager(
        gh<_i562.EducationRepository>(),
        gh<_i187.SyncRepository>(),
      ),
      dispose: _i388.disposeSyncManager,
    );
    gh.factory<_i694.DashboardCubit>(
      () => _i694.DashboardCubit(
        gh<_i562.EducationRepository>(),
        gh<_i388.SyncManager>(),
      ),
    );
    gh.factory<_i239.EnhancedDashboardCubit>(
      () => _i239.EnhancedDashboardCubit(
        gh<_i562.EducationRepository>(),
        gh<_i388.SyncManager>(),
      ),
    );
    return this;
  }
}

class _$FirebaseModule extends _i616.FirebaseModule {}
