import 'dart:async';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:injectable/injectable.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';

@lazySingleton
class GemmaService {
  GemmaService();

  static const String _modelFileName = 'gemma-2b-it-cpu-int4.bin';
  static const String _modelUrl =
      'https://huggingface.co/google/gemma-2b-it-cpu-int4.bin';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      log.i('Initializing Gemma...');
      await FlutterGemma.initialize();

      // Attempt activation if on disk
      final isInstalled = await FlutterGemma.isModelInstalled(_modelFileName);
      if (isInstalled && !FlutterGemma.hasActiveModel()) {
        log.i('Model found on disk. Activating...');
        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
        ).fromNetwork(_modelUrl).install();
      }

      _initialized = true;
      log.i('Gemma initialized successfully');
    } catch (e, stack) {
      log.e('Failed to initialize Gemma', error: e, stackTrace: stack);
      // Don't rethrow here to allow app to start even if AI fails
    }
  }

  Future<bool> isModelInstalled() async {
    if (FlutterGemma.hasActiveModel()) return true;
    return await FlutterGemma.isModelInstalled(_modelFileName);
  }

  Stream<int> installModel() async* {
    try {
      log.i('Starting model installation...');

      // Using Gemma 2B IT CPU Int4 as a sample model
      // Note: This is a public URL for demonstration. In production, this might be gated.
      final installation = FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromNetwork(_modelUrl);

      int lastProgress = -1;

      // We'll create a controller to yield progress from the callback
      final progressController = StreamController<int>();

      installation.withProgress((progress) {
        if (progress != lastProgress) {
          lastProgress = progress;
          progressController.add(progress);
        }
      });

      // Start installation in background and wait for it
      installation
          .install()
          .then((_) {
            progressController.close();
          })
          .catchError((Object e) {
            progressController.addError(e);
            progressController.close();
            return null; // Add return as catchError expects a value if not rethrowing
          });

      yield* progressController.stream;

      log.i('Model installation completed successfully');
    } catch (e, stack) {
      log.e('Failed to install model', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<String> getExplanation(
    String lessonContent, {
    String? question,
  }) async {
    try {
      if (!_initialized) await init();

      log.i(
        question != null
            ? 'Answering specific question: $question'
            : 'Generating general explanation for lesson content...',
      );

      // Final check and attempt to activate if on disk
      if (!FlutterGemma.hasActiveModel()) {
        final isInstalled = await FlutterGemma.isModelInstalled(_modelFileName);
        if (isInstalled) {
          log.i('Model exists but not active. Activating now...');
          await FlutterGemma.installModel(
            modelType: ModelType.gemmaIt,
          ).fromNetwork(_modelUrl).install();
        } else {
          log.w('No active Gemma model found and not on disk.');
          return 'المعلم الذكي غير جاهز حالياً. يرجى التأكد من تحميل ملفات المعلم من الشاشة الرئيسية للدرس.';
        }
      }

      final model = await FlutterGemma.getActiveModel();
      final session = await model.createSession();

      try {
        final queryText = question != null
            ? 'سؤال الطالب: $question'
            : 'بص يا سيدي، اشرح لي الجزء ده من الدرس بأسلوبك الجميل.';

        final systemPrompt =
            '''
أنت "المعلم الذكي"، معلم مصري خبير مدمج داخل تطبيق تعليمي متطور.

دورك:
- الإجابة على أسئلة الطلاب بفعالية بناءً على محتوى الدرس المقدم فقط.
- استخدام لغة عربية مصرية (عامية مهذبة) لتسهيل الفهم والتقرب من الطالب.
- إذا لم تجد الإجابة في محتوى الدرس، قل بكل أدب: "يا بطل، السؤال ده بره الدرس بتاعنا النهاردة. ممكن تسأل في حاجة تخص الدرس؟"

السياق (محتوى الدرس):
$lessonContent

التعليمات الهامة للإجابة بفعالية:
- ابدأ الإجابة بأسلوب مشجع (مثل: "سؤال جميل يا بطل"، "بص يا سيدي..").
- اشرح الخطوات بوضوح وبساطة شديدة.
- استخدم أمثلة حية من محتوى الدرس لتقريب الصورة.
- اجعل الإجابة مختصرة ولكنها تغطي كل جوانب السؤال.
- الرد يكون بالعامية المصرية بأسلوب المعلم المبدع المحبوب.
''';

        await session.addQueryChunk(
          Message.text(text: '$systemPrompt\n\n$queryText', isUser: true),
        );

        final response = await session.getResponse();

        if (response.contains('is not installed yet') ||
            response.contains('.model files')) {
          return 'المعلم الذكي غير جاهز حالياً. يرجى التأكد من تحميل ملفات المعلم من الشاشة الرئيسية للدرس.';
        }

        return response.isNotEmpty
            ? response
            : 'مش قادر أطلع لك شرح دلوقتي، جرب تسألني سؤال محدد أكتر.';
      } finally {
        await session.close();
      }
    } catch (e, stack) {
      log.e(
        'Error generating explanation with Gemma',
        error: e,
        stackTrace: stack,
      );
      return 'معلش حصلت مشكلة صغيرة وأنا بحاول أشرح. ممكن تجرب تاني؟';
    }
  }
}
