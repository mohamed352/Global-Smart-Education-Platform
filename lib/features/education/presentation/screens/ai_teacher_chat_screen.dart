import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_smart_education_platform/core/di/injection.dart';
import 'package:global_smart_education_platform/features/education/data/services/teacher_stt_service.dart';
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
  final TeacherSttService _stt = getIt<TeacherSttService>();

  final Set<int> _spokenMessageHashes = <int>{};
  int _previousMessageCount = 0;

  @override
  void dispose() {
    _tts.stop();
    _stt.cancelListening();
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

  void _speakLatestIfNew(List<ChatMessage> messages) {
    if (messages.isEmpty) return;
    final ChatMessage lastMsg = messages.last;
    if (lastMsg.isUser) return;

    final int hash = lastMsg.text.hashCode ^ (lastMsg.timestamp?.hashCode ?? 0);

    if (!_spokenMessageHashes.contains(hash) &&
        messages.length > _previousMessageCount) {
      _spokenMessageHashes.add(hash);
      _tts.speak(lastMsg.text);
    }
    _previousMessageCount = messages.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('المعلم الذكي'),
        actions: [
          StatefulBuilder(
            builder: (context, setLocalState) {
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
        ],
      ),
      body: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(
            child: BlocConsumer<TeacherExplanationCubit, TeacherExplanationState>(
              listener: (context, state) {
                state.maybeWhen(
                  loaded: (messages) {
                    _scrollToBottom();
                    _speakLatestIfNew(messages);
                  },
                  orElse: () {},
                );
              },
              builder: (context, state) {
                return state.when(
                  initial: () =>
                      const Center(child: Text('اختر درساً للبدء في الدردشة!')),
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
                      padding: const EdgeInsets.all(20),
                      itemCount: messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          // Use the cubit state to check if we should show typing
                          return BlocBuilder<
                            TeacherExplanationCubit,
                            TeacherExplanationState
                          >(
                            builder: (context, state) {
                              // This is a bit tricky because 'loaded' state doesn't have a 'isThinking' flag
                              // But we can check if the last message is from user
                              if (messages.isNotEmpty && messages.last.isUser) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const TalkingAvatarWidget(
                                        size: 32,
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface,
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(24),
                                            bottomLeft: Radius.circular(24),
                                            bottomRight: Radius.circular(24),
                                            topLeft: Radius.circular(4),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: List.generate(
                                            3,
                                            (i) => _AnimatedDot(
                                              delay: Duration(
                                                milliseconds: i * 200,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          );
                        }
                        return _EnhancedChatBubble(
                          message: messages[index],
                          ttsService: _tts,
                        );
                      },
                    );
                  },
                  error: (message) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(message, textAlign: TextAlign.center),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _tts.isSpeaking,
            builder: (context, speaking, child) {
              return TalkingAvatarWidget(size: 80, isSpeaking: speaking);
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المعلمة ذكية',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<bool>(
                  valueListenable: _tts.isSpeaking,
                  builder: (context, speaking, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: speaking
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        speaking ? 'تتحدث الآن...' : 'جاهزة لمساعدتك',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: speaking
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                          fontWeight: speaking
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Real-time voice feedback indicator
        ValueListenableBuilder<bool>(
          valueListenable: _stt.isListening,
          builder: (context, listening, child) {
            if (!listening) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const _WaveformIndicator(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: _stt.recognizedText,
                      builder: (context, text, child) {
                        return Text(
                          text.isEmpty ? 'جاري الاستماع...' : text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontStyle: text.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Container(
          padding: EdgeInsetsDirectional.fromSTEB(
            12,
            8,
            12,
            8 + MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, -2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: _stt.isListening,
                builder: (context, listening, child) {
                  return _MicButton(
                    isListening: listening,
                    onPressed: () => _handleMicPress(),
                  );
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'اسأل سؤالك هنا...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
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
        ),
      ],
    );
  }

  void _handleMicPress() {
    if (_stt.isListening.value) {
      _stt.stopListening();
    } else {
      _tts.stop();
      _stt.startListening(
        onResult: (finalText) {
          if (mounted) {
            _controller.text = finalText;
            // Slightly delay sending to let user see the final populated text
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted && _controller.text.trim().isNotEmpty) {
                _sendMessage();
              }
            });
          }
        },
      );
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _tts.stop();
      _stt.cancelListening();
      final cubit = context.read<TeacherExplanationCubit>();
      // Use the last initialized lesson content
      cubit.askQuestion('', text);
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }
}

class _EnhancedChatBubble extends StatelessWidget {
  const _EnhancedChatBubble({required this.message, required this.ttsService});

  final ChatMessage message;
  final TeacherTtsService ttsService;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    final timeStr = message.timestamp != null
        ? "${message.timestamp!.hour}:${message.timestamp!.minute.toString().padLeft(2, '0')}"
        : '';

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 16,
                ),
              ),
            ),
            if (timeStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: Text(
                  timeStr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: ttsService.isSpeaking,
                builder: (context, speaking, child) {
                  return TalkingAvatarWidget(size: 32, isSpeaking: speaking);
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                          topLeft: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Text(
                        message.text,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (timeStr.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              timeStr,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 18,
                          onPressed: () => ttsService.speak(message.text),
                          icon: Icon(
                            Icons.volume_up,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Re-use internal components or make them public in teacher_explanation_widget.dart
// For now duplication to ensure stability, will refactor later if time permits.
class _MicButton extends StatefulWidget {
  const _MicButton({required this.isListening, required this.onPressed});

  final bool isListening;
  final VoidCallback onPressed;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isListening) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = widget.isListening
            ? 1.0 + (_pulseController.value * 0.15)
            : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isListening
                  ? Colors.red.shade400
                  : theme.colorScheme.secondaryContainer,
            ),
            child: IconButton(
              onPressed: widget.onPressed,
              icon: Icon(
                widget.isListening ? Icons.stop : Icons.mic,
                color: widget.isListening
                    ? Colors.white
                    : theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveformIndicator extends StatefulWidget {
  const _WaveformIndicator();

  @override
  State<_WaveformIndicator> createState() => _WaveformIndicatorState();
}

class _WaveformIndicatorState extends State<_WaveformIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double waveValue =
                0.5 +
                0.5 *
                    (1.0 +
                            (0.8 *
                                (index % 2 == 0 ? 1 : -1) *
                                _controller.value))
                        .remainder(1.0);

            return Container(
              width: 3,
              height: 4 + (20 * waveValue),
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
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
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
