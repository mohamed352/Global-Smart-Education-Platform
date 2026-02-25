// ignore_for_file: sort_constructors_first
part of 'teacher_explanation_cubit.dart';

@freezed
class TeacherExplanationState with _$TeacherExplanationState {
  const factory TeacherExplanationState.initial() = _Initial;
  const factory TeacherExplanationState.loading() = _Loading;
  const factory TeacherExplanationState.loaded(List<ChatMessage> messages) =
      _Loaded;
  const factory TeacherExplanationState.error(String message) = _Error;
}

class ChatMessage {
  ChatMessage({required this.text, required this.isUser, this.timestamp});

  final String text;
  final bool isUser;
  final DateTime? timestamp;
}
