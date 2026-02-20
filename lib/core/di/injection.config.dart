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
import '../../features/education/data/services/sync_manager.dart' as _i388;
import '../../features/education/presentation/cubit/dashboard_cubit.dart'
    as _i694;
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
    gh.lazySingleton<_i562.EducationRepository>(
      () => _i562.EducationRepository(gh<_i228.AppDatabase>()),
    );
    gh.lazySingleton<_i898.FirebaseRemoteDataSource>(
      () => _i898.FirebaseRemoteDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i187.SyncRepository>(
      () => _i187.SyncRepository(
        gh<_i187.RemoteDataSource>(),
        gh<_i898.FirebaseRemoteDataSource>(),
      ),
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
    return this;
  }
}

class _$FirebaseModule extends _i616.FirebaseModule {}
