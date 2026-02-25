import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_smart_education_platform/core/di/injection.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';
import 'package:global_smart_education_platform/features/education/data/services/teacher_stt_service.dart';
import 'package:global_smart_education_platform/features/education/data/services/teacher_tts_service.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/teacher_explanation_cubit.dart';

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
  final TeacherSttService _stt = getIt<TeacherSttService>();

  /// Track which messages have already been spoken to avoid re-speaking history
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
              _stt.cancelListening();
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
          // Microphone button (STT)
          ValueListenableBuilder<bool>(
            valueListenable: _stt.isListening,
            builder: (BuildContext context, bool listening, Widget? child) {
              return _MicButton(
                isListening: listening,
                onPressed: () => _handleMicPress(),
              );
            },
          ),
          const SizedBox(width: 8),
          // Text input with STT preview
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: _stt.recognizedText,
              builder:
                  (BuildContext context, String partialText, Widget? child) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: _stt.isListening,
                      builder:
                          (
                            BuildContext context,
                            bool listening,
                            Widget? child,
                          ) {
                            return TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: listening
                                    ? (partialText.isNotEmpty
                                          ? partialText
                                          : 'جاري الاستماع...')
                                    : 'اسأل سؤالك هنا...',
                                hintStyle: listening
                                    ? TextStyle(
                                        color: theme.colorScheme.primary,
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: listening
                                      ? BorderSide(
                                          color: theme.colorScheme.primary,
                                        )
                                      : BorderSide.none,
                                ),
                                enabledBorder: listening
                                    ? OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.primary,
                                        ),
                                      )
                                    : OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: BorderSide.none,
                                      ),
                                filled: true,
                                fillColor: theme
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            );
                          },
                    );
                  },
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

  void _handleMicPress() {
    if (_stt.isListening.value) {
      _stt.stopListening();
    } else {
      _tts.stop(); // Stop any ongoing speech
      _stt.startListening(
        onResult: (String finalText) {
          _controller.text = finalText;
          log.i('STT result received: $finalText', tag: LogTags.app);
          // Auto-send after a short delay so user can see the text
          Future<void>.delayed(const Duration(milliseconds: 400), () {
            if (mounted && _controller.text.trim().isNotEmpty) {
              _sendMessage();
            }
          });
        },
      );
    }
  }

  void _sendMessage() {
    final String text = _controller.text.trim();
    if (text.isNotEmpty) {
      _tts.stop();
      _stt.cancelListening();
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
// Mic Button with animated states
// ─────────────────────────────────────────────────────────────

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
    if (widget.isListening) {
      _pulseController.repeat(reverse: true);
    }
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
    final ThemeData theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (BuildContext context, Widget? child) {
        final double scale = widget.isListening
            ? 1.0 + (_pulseController.value * 0.15)
            : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isListening
                  ? Colors.red.shade400
                  : theme.colorScheme.secondaryContainer,
              boxShadow: widget.isListening
                  ? <BoxShadow>[
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 22,
              onPressed: widget.onPressed,
              icon: Icon(
                widget.isListening ? Icons.stop : Icons.mic,
                color: widget.isListening
                    ? Colors.white
                    : theme.colorScheme.onSecondaryContainer,
              ),
              tooltip: widget.isListening ? 'إيقاف الاستماع' : 'تحدث سؤالك',
            ),
          ),
        );
      },
    );
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

// ─────────────────────────────────────────────────────────────
// Animated Talking Avatar
// ─────────────────────────────────────────────────────────────

class TalkingAvatarWidget extends StatefulWidget {
  const TalkingAvatarWidget({
    super.key,
    required this.size,
    this.isSpeaking = false,
  });

  final double size;
  final bool isSpeaking;

  @override
  State<TalkingAvatarWidget> createState() => _TalkingAvatarWidgetState();
}

class _TalkingAvatarWidgetState extends State<TalkingAvatarWidget>
    with TickerProviderStateMixin {
  // Glow pulse
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Mouth open/close (talking)
  late AnimationController _mouthController;
  late Animation<double> _mouthAnimation;

  // Blink
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  // Nod
  late AnimationController _nodController;
  late Animation<double> _nodAnimation;

  @override
  void initState() {
    super.initState();

    // Glow pulse animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Mouth animation (faster for talking illusion)
    _mouthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _mouthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mouthController, curve: Curves.easeInOut),
    );

    // Blink animation
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.1).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // Nod animation
    _nodController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _nodAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
    ).animate(CurvedAnimation(parent: _nodController, curve: Curves.easeInOut));

    // Start idle blink loop
    _startBlinkLoop();

    if (widget.isSpeaking) {
      _startSpeaking();
    }
  }

  @override
  void didUpdateWidget(covariant TalkingAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _startSpeaking();
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _stopSpeaking();
    }
  }

  void _startSpeaking() {
    _glowController.repeat(reverse: true);
    _mouthController.repeat(reverse: true);
    _nodController.repeat(reverse: true);
  }

  void _stopSpeaking() {
    _glowController.stop();
    _glowController.reset();
    _mouthController.stop();
    _mouthController.reset();
    _nodController.stop();
    _nodController.reset();
  }

  void _startBlinkLoop() async {
    while (mounted) {
      await Future<void>.delayed(
        Duration(milliseconds: 2500 + (500 * (DateTime.now().second % 4))),
      );
      if (!mounted) return;
      await _blinkController.forward();
      await _blinkController.reverse();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _mouthController.dispose();
    _blinkController.dispose();
    _nodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double s = widget.size;

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _glowAnimation,
        _mouthAnimation,
        _blinkAnimation,
        _nodAnimation,
      ]),
      builder: (BuildContext context, Widget? child) {
        return Transform.translate(
          offset: Offset(0, _nodAnimation.value * s),
          child: Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: widget.isSpeaking
                  ? <BoxShadow>[
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15 + _glowAnimation.value * 0.35,
                        ),
                        blurRadius: 8 + _glowAnimation.value * 12,
                        spreadRadius: 1 + _glowAnimation.value * 3,
                      ),
                    ]
                  : null,
            ),
            child: CustomPaint(
              painter: _AvatarFacePainter(
                mouthOpen: widget.isSpeaking ? _mouthAnimation.value : 0.0,
                eyeOpenness: _blinkAnimation.value,
                primaryColor: theme.colorScheme.primary,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Custom Painter for Avatar Face
// ─────────────────────────────────────────────────────────────

class _AvatarFacePainter extends CustomPainter {
  _AvatarFacePainter({
    required this.mouthOpen,
    required this.eyeOpenness,
    required this.primaryColor,
  });

  final double mouthOpen;
  final double eyeOpenness;
  final Color primaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;
    final Paint whitePaint = Paint()..color = Colors.white;

    // Eyes
    final double eyeY = cy - r * 0.12;
    final double eyeSpacing = r * 0.28;
    final double eyeW = r * 0.14;
    final double eyeH = r * 0.18 * eyeOpenness;

    // Left eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - eyeSpacing, eyeY),
        width: eyeW,
        height: eyeH.clamp(1.0, double.infinity),
      ),
      whitePaint,
    );
    // Right eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + eyeSpacing, eyeY),
        width: eyeW,
        height: eyeH.clamp(1.0, double.infinity),
      ),
      whitePaint,
    );

    // Pupils (only when eyes are open enough)
    if (eyeOpenness > 0.3) {
      final Paint pupilPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7);
      final double pupilR = eyeW * 0.3;
      canvas.drawCircle(Offset(cx - eyeSpacing, eyeY), pupilR, pupilPaint);
      canvas.drawCircle(Offset(cx + eyeSpacing, eyeY), pupilR, pupilPaint);
    }

    // Mouth
    final double mouthY = cy + r * 0.22;
    final double mouthW = r * 0.35;
    final double mouthH = r * 0.06 + (mouthOpen * r * 0.2);

    final Paint mouthPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = mouthOpen > 0.1 ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, mouthY),
        width: mouthW,
        height: mouthH.clamp(2.0, double.infinity),
      ),
      mouthPaint,
    );

    // Glasses (subtle)
    final Paint glassPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final double glassR = r * 0.2;
    canvas.drawCircle(Offset(cx - eyeSpacing, eyeY), glassR, glassPaint);
    canvas.drawCircle(Offset(cx + eyeSpacing, eyeY), glassR, glassPaint);
    // Bridge
    canvas.drawLine(
      Offset(cx - eyeSpacing + glassR, eyeY),
      Offset(cx + eyeSpacing - glassR, eyeY),
      glassPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarFacePainter oldDelegate) {
    return oldDelegate.mouthOpen != mouthOpen ||
        oldDelegate.eyeOpenness != eyeOpenness;
  }
}
