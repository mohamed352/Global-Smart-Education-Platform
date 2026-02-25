import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_installation_state.freezed.dart';

@freezed
class ModelInstallationState with _$ModelInstallationState {
  const factory ModelInstallationState.initial() = _Initial;
  const factory ModelInstallationState.checking() = _Checking;
  const factory ModelInstallationState.notInstalled() = _NotInstalled;
  const factory ModelInstallationState.installing(int progress) = _Installing;
  const factory ModelInstallationState.installed() = _Installed;
  const factory ModelInstallationState.error(String message) = _Error;
}
