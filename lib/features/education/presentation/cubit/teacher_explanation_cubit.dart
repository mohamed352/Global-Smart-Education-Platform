import 'package:drift/drift.dart' show Value;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';
import 'package:global_smart_education_platform/features/education/data/services/lesson_ai_service.dart';

part 'teacher_explanation_state.dart';
part 'teacher_explanation_cubit.freezed.dart';

@injectable
class TeacherExplanationCubit extends Cubit<TeacherExplanationState> {
  TeacherExplanationCubit(this._aiService, this._db)
    : super(const TeacherExplanationState.initial());

  final LessonAiService _aiService;
  final AppDatabase _db;

  String _lessonContent = '';
  String _lessonTitle = '';
  String _lessonId = '';

  /// Initialize for a specific lesson — always succeeds, no model download needed
  Future<void> initializeForLesson({
    required String lessonId,
    required String lessonTitle,
    required String lessonContent,
  }) async {
    log.i('Initializing for lesson: $lessonTitle', tag: LogTags.bloc);

    _lessonContent = lessonContent;
    _lessonTitle = lessonTitle;
    _lessonId = lessonId;

    emit(const TeacherExplanationState.loading());

    try {
      final List<QaHistoryItem> history = await _db.getQaHistoryForLesson(
        lessonId,
      );
      log.d('Loaded ${history.length} history items', tag: LogTags.db);

      final List<ChatMessage> messages = <ChatMessage>[];

      if (history.isEmpty) {
        final String greeting = _aiService.generateGreeting(lessonTitle);
        messages.add(
          ChatMessage(text: greeting, isUser: false, timestamp: DateTime.now()),
        );

        await _db.insertQaItem(
          QaHistoryItemsCompanion.insert(
            lessonId: lessonId,
            question: '',
            answer: greeting,
            isGreeting: const Value(true),
            createdAt: DateTime.now(),
          ),
        );
      } else {
        for (final QaHistoryItem item in history) {
          if (!item.isGreeting && item.question.isNotEmpty) {
            messages.add(
              ChatMessage(
                text: item.question,
                isUser: true,
                timestamp: item.createdAt,
              ),
            );
          }
          messages.add(
            ChatMessage(
              text: item.answer,
              isUser: false,
              timestamp: item.createdAt,
            ),
          );
        }
      }

      emit(TeacherExplanationState.loaded(messages));
      log.i(
        'AI Teacher ready with ${messages.length} messages',
        tag: LogTags.bloc,
      );
    } catch (e) {
      log.e('Error initializing', tag: LogTags.error, error: e);
      final String greeting = _aiService.generateGreeting(lessonTitle);
      emit(
        TeacherExplanationState.loaded(<ChatMessage>[
          ChatMessage(text: greeting, isUser: false, timestamp: DateTime.now()),
        ]),
      );
    }
  }

  /// Ask a question — generates answer 100% offline from lesson content
  Future<void> askQuestion(String content, String question) async {
    final TeacherExplanationState currentState = state;
    if (currentState is! _Loaded) return;

    final List<ChatMessage> currentMessages = List<ChatMessage>.from(
      currentState.messages,
    );

    currentMessages.add(
      ChatMessage(text: question, isUser: true, timestamp: DateTime.now()),
    );
    emit(
      TeacherExplanationState.loaded(List<ChatMessage>.from(currentMessages)),
    );

    try {
      final String answer = _aiService.answerQuestion(
        lessonContent: _lessonContent.isNotEmpty ? _lessonContent : content,
        lessonTitle: _lessonTitle,
        question: question,
      );

      currentMessages.add(
        ChatMessage(text: answer, isUser: false, timestamp: DateTime.now()),
      );
      emit(
        TeacherExplanationState.loaded(List<ChatMessage>.from(currentMessages)),
      );

      if (_lessonId.isNotEmpty) {
        await _db.insertQaItem(
          QaHistoryItemsCompanion.insert(
            lessonId: _lessonId,
            question: question,
            answer: answer,
            createdAt: DateTime.now(),
          ),
        );
        log.d('Q&A saved to local database', tag: LogTags.db);
      }
    } catch (e) {
      log.e('Error answering', tag: LogTags.error, error: e);
      currentMessages.add(
        ChatMessage(
          text: 'معلش حصلت مشكلة بسيطة. حاول تسأل مرة ثانية يا بطل! 💪',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      emit(
        TeacherExplanationState.loaded(List<ChatMessage>.from(currentMessages)),
      );
    }
  }

  /// Legacy method — kept for backward compat, delegates to initializeForLesson
  Future<void> explainLesson(String content) async {
    _lessonContent = content;
    if (_lessonTitle.isEmpty) _lessonTitle = 'الدرس';
    if (_lessonId.isEmpty) _lessonId = content.hashCode.toString();

    await initializeForLesson(
      lessonId: _lessonId,
      lessonTitle: _lessonTitle,
      lessonContent: content,
    );
  }
}
