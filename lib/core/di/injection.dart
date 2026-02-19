import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:global_smart_education_platform/core/di/injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(preferRelativeImports: true)
Future<void> configureDependencies() async => getIt.init();
