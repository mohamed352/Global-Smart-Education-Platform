import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_smart_education_platform/core/di/injection.dart';
import 'package:global_smart_education_platform/features/education/data/services/teacher_tts_service.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/teacher_explanation_cubit.dart';

import 'package:global_smart_education_platform/features/education/presentation/widgets/talking_avatar_widget.dart';

// ─────────────────────────────────────────────────────────────
// Main Widget
// ─────────────────────────────────────────────────────────────

class TeacherExplanationWidget extends StatefulWidget {
  const TeacherExplanationWidget({super.key, required this.lessonContent});

  final String lessonContent;

  static void show(BuildContext context, String content) {
    final TeacherExplanationCubit cubit = context
        .read<TeacherExplanationCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) =>
          BlocProvider<TeacherExplanationCubit>.value(
            value: cubit,
            child: TeacherExplanationWidget(lessonContent: content),
          ),
    );
  }

  @override
  State<TeacherExplanationWidget> createState() =>
      _TeacherExplanationWidgetState();
}

class _TeacherExplanationWidgetState extends State<TeacherExplanationWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TeacherTtsService _tts = getIt<TeacherTtsService>();

  /// Track which messages have already been spoken to avoid re-speaking history
  final Set<int> _spokenMessageHashes = <int>{};
  int _previousMessageCount = 0;

  @override
  void dispose() {
    _tts.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Speak the latest AI message if it's new
  void _speakLatestIfNew(List<ChatMessage> messages) {
    if (messages.isEmpty) return;
    final ChatMessage lastMsg = messages.last;
    if (lastMsg.isUser) return;

    final int hash = lastMsg.text.hashCode ^ lastMsg.timestamp.hashCode;

    if (!_spokenMessageHashes.contains(hash) &&
        messages.length > _previousMessageCount) {
      _spokenMessageHashes.add(hash);
      _tts.speak(lastMsg.text);
    }
    _previousMessageCount = messages.length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Header with animated avatar + controls
          _buildHeader(context),
          const Divider(),
          // Chat area
          Expanded(
            child:
                BlocConsumer<TeacherExplanationCubit, TeacherExplanationState>(
                  listener:
                      (BuildContext context, TeacherExplanationState state) {
                        state.maybeWhen(
                          loaded: (List<ChatMessage> messages) {
                            _scrollToBottom();
                            _speakLatestIfNew(messages);
                          },
                          orElse: () {},
                        );
                      },
                  builder:
                      (BuildContext context, TeacherExplanationState state) {
                        return state.when(
                          initial: () {
                            context
                                .read<TeacherExplanationCubit>()
                                .explainLesson(widget.lessonContent);
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          loading: () => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('جاري التحضير...'),
                              ],
                            ),
                          ),
                          loaded: (List<ChatMessage> messages) =>
                              ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(20),
                                itemCount: messages.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return _ChatBubbleWithAvatar(
                                    message: messages[index],
                                    ttsService: _tts,
                                  );
                                },
                              ),
                          error: (String message) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(message, textAlign: TextAlign.center),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    onPressed: () => context
                                        .read<TeacherExplanationCubit>()
                                        .explainLesson(widget.lessonContent),
                                    child: const Text('إعادة المحاولة'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                ),
          ),
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          // Animated talking avatar
          ValueListenableBuilder<bool>(
            valueListenable: _tts.isSpeaking,
            builder: (BuildContext context, bool speaking, Widget? child) {
              return TalkingAvatarWidget(size: 48, isSpeaking: speaking);
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'المعلم الذكي',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _tts.isSpeaking,
                  builder:
                      (BuildContext context, bool speaking, Widget? child) {
                        return Text(
                          speaking ? 'يتحدث...' : 'جاهز للمساعدة',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: speaking
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                          ),
                        );
                      },
                ),
              ],
            ),
          ),
          // Mute / unmute toggle
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setLocalState) {
              return IconButton(
                onPressed: () {
                  _tts.toggleMute();
                  setLocalState(() {});
                },
                icon: Icon(
                  _tts.isMuted ? Icons.volume_off : Icons.volume_up,
                  color: _tts.isMuted ? Colors.grey : theme.colorScheme.primary,
                ),
                tooltip: _tts.isMuted ? 'تشغيل الصوت' : 'كتم الصوت',
              );
            },
          ),
          IconButton(
            onPressed: () {
              _tts.stop();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          // Text input
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'اسأل سؤالك هنا...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final String text = _controller.text.trim();
    if (text.isNotEmpty) {
      _tts.stop();
      context.read<TeacherExplanationCubit>().askQuestion(
        widget.lessonContent,
        text,
      );
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Chat Bubble with Avatar
// ─────────────────────────────────────────────────────────────

class _ChatBubbleWithAvatar extends StatelessWidget {
  const _ChatBubbleWithAvatar({
    required this.message,
    required this.ttsService,
  });

  final ChatMessage message;
  final TeacherTtsService ttsService;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;
    final ThemeData theme = Theme.of(context);

    if (isUser) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Container(
          margin: const EdgeInsetsDirectional.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(20),
              topEnd: Radius.circular(20),
              bottomStart: Radius.circular(20),
            ),
          ),
          child: Text(
            message.text,
            textDirection: TextDirection.rtl,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    // AI message with avatar + replay button
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ValueListenableBuilder<bool>(
                valueListenable: ttsService.isSpeaking,
                builder: (BuildContext context, bool speaking, Widget? child) {
                  return TalkingAvatarWidget(size: 30, isSpeaking: speaking);
                },
              ),
              const SizedBox(width: 8),
              Text(
                'المعلم الذكي',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 28,
                width: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  onPressed: () => ttsService.speak(message.text),
                  icon: Icon(
                    Icons.replay,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  ),
                  tooltip: 'إعادة الصوت',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadiusDirectional.only(
                topEnd: Radius.circular(20),
                bottomStart: Radius.circular(20),
                bottomEnd: Radius.circular(20),
              ),
            ),
            child: Text(
              message.text,
              textDirection: TextDirection.rtl,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
