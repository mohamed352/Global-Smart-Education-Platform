import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:global_smart_education_platform/features/education/data/services/gemma_service.dart';
import 'model_installation_state.dart';

@lazySingleton
class ModelInstallationCubit extends Cubit<ModelInstallationState> {

  ModelInstallationCubit(this._gemmaService)
    : super(const ModelInstallationState.initial());
  final GemmaService _gemmaService;
  StreamSubscription<int>? _subscription;

  Future<void> checkModelStatus() async {
    emit(const ModelInstallationState.checking());
    try {
      final isInstalled = await _gemmaService.isModelInstalled();
      if (isInstalled) {
        emit(const ModelInstallationState.installed());
      } else {
        emit(const ModelInstallationState.notInstalled());
      }
    } catch (e) {
      emit(ModelInstallationState.error('Failed to check model status: $e'));
    }
  }

  Future<void> installModel() async {
    if (state.maybeMap(installing: (_) => true, orElse: () => false)) return;

    emit(const ModelInstallationState.installing(0));

    await _subscription?.cancel();

    _subscription = _gemmaService.installModel().listen(
      (progress) {
        emit(ModelInstallationState.installing(progress));
      },
      onError: (Object e) {
        emit(ModelInstallationState.error('Installation failed: $e'));
      },
      onDone: () {
        emit(const ModelInstallationState.installed());
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
