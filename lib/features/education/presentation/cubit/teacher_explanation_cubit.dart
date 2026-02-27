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
      log.e('Error initializing', error: e);
      final String greeting = _aiService.generateGreeting(lessonTitle);
      emit(
        TeacherExplanationState.loaded(<ChatMessage>[
          ChatMessage(text: greeting, isUser: false, timestamp: DateTime.now()),
        ]),
      );
    }
  }

  /// Initialize a generic chat when no lesson is selected
  Future<void> initializeGenericChat() async {
    log.i('Initializing generic AI Teacher chat', tag: LogTags.bloc);

    _lessonContent =
        'أنت معلمة ذكية عامة، مهمتك مساعدة الطالب في أي سؤال تعليمي يطرحه.';
    _lessonTitle = 'محادثة عامة';
    _lessonId = 'global_chat';

    emit(const TeacherExplanationState.loading());

    try {
      final List<QaHistoryItem> history = await _db.getQaHistoryForLesson(
        _lessonId,
      );

      final List<ChatMessage> messages = <ChatMessage>[];

      if (history.isEmpty) {
        const String greeting =
            'مرحباً! أنا المعلمة الذكية. كيف يمكنني مساعدتك اليوم؟';
        messages.add(
          ChatMessage(text: greeting, isUser: false, timestamp: DateTime.now()),
        );

        await _db.insertQaItem(
          QaHistoryItemsCompanion.insert(
            lessonId: _lessonId,
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
    } catch (e) {
      log.e('Error initializing generic chat', error: e);
      const String greeting =
          'مرحباً! أنا المعلمة الذكية. كيف يمكنني مساعدتك اليوم؟';
      emit(
        TeacherExplanationState.loaded(<ChatMessage>[
          ChatMessage(text: greeting, isUser: false, timestamp: DateTime.now()),
        ]),
      );
    }
  }

  /// Ask a question — generates answer 100% offline from lesson content
  Future<void> askQuestion(String content, String question) async {
    final currentState = state;
    if (currentState is! _Loaded) {
      log.w('Cannot ask question: state is not loaded', tag: LogTags.bloc);
      return;
    }

    // Use provided content if available, otherwise fall back to stored lesson content
    final effectiveContent = content.isNotEmpty ? content : _lessonContent;

    if (effectiveContent.isEmpty) {
      log.w(
        'Cannot ask question: no lesson content available',
        tag: LogTags.bloc,
      );
      return;
    }

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
      // Small delay before starting
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final String fullAnswer = _aiService.answerQuestion(
        lessonContent: effectiveContent,
        lessonTitle: _lessonTitle.isNotEmpty ? _lessonTitle : 'الدرس',
        question: question,
      );

      // Simulate streaming
      String currentAnswer = '';
      final words = fullAnswer.split(RegExp(r'\s+'));

      // Add empty message placeholder for AI
      final int messageIndex = currentMessages.length;
      currentMessages.add(
        ChatMessage(text: '', isUser: false, timestamp: DateTime.now()),
      );

      for (int i = 0; i < words.length; i++) {
        await Future<void>.delayed(
          const Duration(milliseconds: 60),
        ); // Fast typing effect
        currentAnswer += (i == 0 ? '' : ' ') + words[i];

        currentMessages[messageIndex] = ChatMessage(
          text: currentAnswer,
          isUser: false,
          timestamp: DateTime.now(),
        );
        emit(
          TeacherExplanationState.loaded(
            List<ChatMessage>.from(currentMessages),
          ),
        );
      }

      if (_lessonId.isNotEmpty) {
        await _db.insertQaItem(
          QaHistoryItemsCompanion.insert(
            lessonId: _lessonId,
            question: question,
            answer: fullAnswer,
            createdAt: DateTime.now(),
          ),
        );
        log.d('Q&A saved to local database', tag: LogTags.db);
      }
    } catch (e) {
      log.e('Error answering', error: e);
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
