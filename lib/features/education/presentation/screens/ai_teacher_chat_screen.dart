import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_smart_education_platform/core/di/injection.dart';
import 'package:global_smart_education_platform/features/education/data/services/teacher_tts_service.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/teacher_explanation_cubit.dart';
import 'package:global_smart_education_platform/features/education/presentation/widgets/talking_avatar_widget.dart';

class AiTeacherChatScreen extends StatefulWidget {
  const AiTeacherChatScreen({super.key});

  @override
  State<AiTeacherChatScreen> createState() => _AiTeacherChatScreenState();
}

class _AiTeacherChatScreenState extends State<AiTeacherChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TeacherTtsService _tts = getIt<TeacherTtsService>();

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        title: Row(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: _tts.isSpeaking,
              builder: (context, speaking, child) {
                return Container(
                  margin: const EdgeInsetsDirectional.only(start: 8),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: speaking
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: TalkingAvatarWidget(size: 40, isSpeaking: speaking),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'المعلمة الذكية',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _tts.isSpeaking,
                    builder: (context, speaking, child) {
                      return Row(
                        children: [
                          _StatusDot(isSpeaking: speaking),
                          const SizedBox(width: 4),
                          Text(
                            speaking ? 'تتحدث الآن...' : 'متصلة الآن',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: speaking
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          StatefulBuilder(
            builder: (context, setLocalState) {
              return IconButton(
                onPressed: () {
                  _tts.toggleMute();
                  setLocalState(() {});
                },
                icon: Icon(
                  _tts.isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: _tts.isMuted ? Colors.grey : theme.colorScheme.primary,
                ),
                tooltip: _tts.isMuted ? 'تشغيل الصوت' : 'كتم الصوت',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                BlocConsumer<TeacherExplanationCubit, TeacherExplanationState>(
                  listener: (context, state) {
                    state.maybeWhen(
                      loaded: (messages) => _scrollToBottom(),
                      orElse: () {},
                    );
                  },
                  builder: (context, state) {
                    return state.when(
                      initial: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          context
                              .read<TeacherExplanationCubit>()
                              .initializeGenericChat();
                        });
                        return const Center(child: CircularProgressIndicator());
                      },
                      loading: () => const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('جاري التحضير...'),
                          ],
                        ),
                      ),
                      loaded: (messages) {
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == messages.length) {
                              if (messages.isNotEmpty && messages.last.isUser) {
                                return _buildTypingIndicator(theme);
                              }
                              return const SizedBox.shrink();
                            }
                            return _ChatBubble(
                              message: messages[index],
                              ttsService: _tts,
                            );
                          },
                        );
                      },
                      error: (message) => Center(child: Text(message)),
                    );
                  },
                ),
          ),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Row(
            children: List.generate(
              3,
              (i) => _AnimatedDot(delay: Duration(milliseconds: i * 200)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'المعلمة تكتب...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(
        16,
        8,
        16,
        8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
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
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withOpacity(0.5),
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
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _tts.stop();
      context.read<TeacherExplanationCubit>().askQuestion('', text);
      _controller.clear();
    }
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.ttsService});
  final ChatMessage message;
  final TeacherTtsService ttsService;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isUser
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              message.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 15,
                height: 1.7,
              ),
            ),
          ),
          if (!isUser && message.text.isNotEmpty) ...[
            const SizedBox(width: 12),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 22,
              onPressed: () => ttsService.speak(message.text),
              icon: Icon(
                Icons.volume_up_rounded,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusDot extends StatefulWidget {
  final bool isSpeaking;
  const _StatusDot({required this.isSpeaking});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.isSpeaking
          ? _controller
          : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isSpeaking ? Colors.green : Colors.grey[400],
          boxShadow: [
            if (widget.isSpeaking)
              BoxShadow(
                color: Colors.green.withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: 2,
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  const _AnimatedDot({required this.delay});
  final Duration delay;

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ScaleTransition(
      scale: _animation,
      child: FadeTransition(
        opacity: _animation,
        child: Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
