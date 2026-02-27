import 'dart:math' as math;
import 'package:injectable/injectable.dart';
import 'package:global_smart_education_platform/core/logger/app_logger.dart';

/// محرك ذكاء اصطناعي محلي يعتمد على محتوى الدرس
/// يعمل 100% بدون إنترنت - بدون تحميل موديل - بدون API
///
/// How it works internally:
/// 1. Content Segmentation: Splits lesson content into semantic paragraphs/sentences
/// 2. Keyword Extraction: Extracts meaningful Arabic keywords from the question
/// 3. Relevance Scoring: Scores each segment using TF-IDF-inspired keyword overlap
/// 4. Answer Composition: Selects top relevant segments and composes a natural answer
/// 5. Yemeni Dialect Wrapping: Wraps the answer in Yemeni Arabic teacher personality
/// 6. Topic Guardrails: Detects off-topic questions and gently redirects
@lazySingleton
class LessonAiService {
  LessonAiService();

  final _random = math.Random();

  // ─── Arabic stop words to filter out during keyword extraction ───
  static const _stopWords = <String>{
    'في',
    'من',
    'على',
    'إلى',
    'عن',
    'مع',
    'هذا',
    'هذه',
    'ذلك',
    'تلك',
    'التي',
    'الذي',
    'الذين',
    'اللذين',
    'اللتين',
    'اللواتي',
    'اللائي',
    'هو',
    'هي',
    'هم',
    'هن',
    'أنا',
    'نحن',
    'أنت',
    'أنتم',
    'أنتن',
    'كان',
    'كانت',
    'كانوا',
    'يكون',
    'تكون',
    'يكونون',
    'أن',
    'إن',
    'لكن',
    'لكنه',
    'لكنها',
    'أو',
    'و',
    'ف',
    'ب',
    'ل',
    'ك',
    'ما',
    'لا',
    'لم',
    'لن',
    'قد',
    'بل',
    'حتى',
    'إذا',
    'إذ',
    'ثم',
    'كل',
    'بعض',
    'غير',
    'بين',
    'عند',
    'فوق',
    'تحت',
    'بعد',
    'قبل',
    'هل',
    'كيف',
    'لماذا',
    'ماذا',
    'أين',
    'متى',
    'كم',
    'ال',
    'الى',
    'عليه',
    'عليها',
    'فيه',
    'فيها',
    'منه',
    'منها',
    'له',
    'لها',
    'لهم',
    'به',
    'بها',
    'بهم',
    'هؤلاء',
    'ذاك',
    'يا',
    'أي',
    'أيها',
    'أيتها',
    'نعم',
    'ليس',
    'ليست',
    'ليسوا',
    'وهو',
    'وهي',
    'وهم',
    'فإن',
    'وإن',
    'فهو',
    'فهي',
    'الدرس',
    'ده',
    'دي',
    'اللي',
    'يعني',
    'بس',
    'كمان',
    'ايش',
    'شو',
    'وش',
    'ليش',
  };

  // ─── Yemeni dialect greetings & encouragements ───
  static const _greetings = [
    'ياسلام عليك يا بطل، سؤال حلو! 🌟',
    'أحسنت يا غالي، خلني أوضحلك 📚',
    'ما شاء الله عليك، سؤال ذكي! ✨',
    'حيّاك الله يا طالبي العزيز! 🎓',
    'تسلم يا بطل على السؤال ده! 💪',
    'أهلاً وسهلاً، خلني أشرحلك الموضوع 📖',
  ];

  static const _redirects = [
    'يا غالي، هذا السؤال برّة محتوى درسنا اليوم. خلّنا نركز على الدرس وبعدين نتكلم في أي شيء ثاني. اسألني عن أي نقطة في الدرس! 📚',
    'يا بطل، أنا مُعلّمك في هذا الدرس بالذات. خلّنا نرجع للموضوع بتاعنا وأساعدك فيه أحسن مساعدة! 🎓',
    'حبيبي، هذا الموضوع مش في الدرس اللي عندنا. بس لو عندك أي سؤال عن محتوى الدرس، أنا جاهز لك! ✨',
  ];

  static const _closings = [
    '\n\nعندك سؤال ثاني يا بطل؟ أنا هنا عشانك! 😊',
    '\n\nلو فيه أي نقطة مش واضحة، اسألني ولا تتردد! 💪',
    '\n\nتحتاج توضيح أكثر؟ أنا ما راح أتعب منك! 📚',
    '\n\nواصل أسئلتك يا غالي، الفهم أهم شيء! 🌟',
  ];

  /// Generate a welcoming greeting when student opens the chat
  String generateGreeting(String lessonTitle) {
    log.d('Generating greeting for: $lessonTitle');
    return 'أهلاً وسهلاً يا بطل! 🎓\n\n'
        'أنا معلمك الذكي وجاهز أساعدك في درس "$lessonTitle".\n\n'
        'اسألني أي سؤال عن الدرس وأنا إن شاء الله أوضحلك كل شيء بطريقة سهلة وبسيطة.\n\n'
        'يلّا ابدأ اسأل! 💪📚';
  }

  /// Main answer generation method — 100% offline, no API needed
  ///
  /// Algorithm:
  /// 1. Extract keywords from the question
  /// 2. Segment the lesson content
  /// 3. Score segments by relevance to the question
  /// 4. If no relevant segments found → redirect (off-topic)
  /// 5. Compose answer from top segments with Yemeni dialect framing
  String answerQuestion({
    required String lessonContent,
    required String lessonTitle,
    required String question,
  }) {
    log.d('Processing question: "$question"');
    log.d(
      'Lesson: "$lessonTitle" (${lessonContent.length} chars)',
    );

    // Step 1: Extract keywords from question
    final questionKeywords = _extractKeywords(question);
    log.d('Question keywords: $questionKeywords');

    if (questionKeywords.isEmpty) {
      log.d(
        'No meaningful keywords, providing general summary',
      );
      return _buildGeneralSummary(lessonContent, lessonTitle);
    }

    // Step 2: Segment lesson content
    final segments = _segmentContent(lessonContent);
    log.d(
      'Content segmented into ${segments.length} segments',
    );

    // Step 3: Score segments by relevance
    final scoredSegments = _scoreSegments(segments, questionKeywords);

    // Step 4: Check if question is on-topic
    final topScore = scoredSegments.isNotEmpty
        ? scoredSegments.first.score
        : 0.0;
    log.d('Top relevance score: $topScore');

    if (topScore < 0.05) {
      // Check if question keywords appear in lesson title
      final titleKeywords = _extractKeywords(lessonTitle);
      final titleOverlap = questionKeywords
          .where(
            (k) => titleKeywords.any((tk) => tk.contains(k) || k.contains(tk)),
          )
          .length;

      if (titleOverlap == 0) {
        log.d('Off-topic question detected, redirecting');
        return _redirects[_random.nextInt(_redirects.length)];
      }
    }

    // Step 5: Compose answer from relevant segments
    final answer = _composeAnswer(
      scoredSegments: scoredSegments,
      question: question,
      questionKeywords: questionKeywords,
      lessonTitle: lessonTitle,
      fullContent: lessonContent,
    );

    log.d('Answer generated (${answer.length} chars)');
    return answer;
  }

  // ─── Internal methods ───

  List<String> _extractKeywords(String text) {
    final normalized = _removeDiacritics(text);
    final words = normalized
        .replaceAll(RegExp(r'[^\u0600-\u06FF\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .map(_removeArabicPrefix)
        .where((w) => w.length > 1)
        .where((w) => !_stopWords.contains(w))
        .toList();
    final seen = <String>{};
    return words.where((w) => seen.add(w)).toList();
  }

  String _removeDiacritics(String text) {
    return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  }

  String _removeArabicPrefix(String word) {
    if (word.length <= 2) return word;
    if (word.startsWith('ال') && word.length > 3) return word.substring(2);
    if (word.length > 4) {
      for (final prefix in ['وال', 'فال', 'بال', 'لل', 'كال']) {
        if (word.startsWith(prefix)) return word.substring(prefix.length);
      }
    }
    if (word.length > 3 && 'وفبلك'.contains(word[0])) {
      return word.substring(1);
    }
    return word;
  }

  List<String> _segmentContent(String content) {
    final paragraphs = content
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    final segments = <String>[];
    for (final paragraph in paragraphs) {
      final trimmed = paragraph.trim();
      if (trimmed.length <= 200) {
        segments.add(trimmed);
      } else {
        final sentences = trimmed
            .split(RegExp(r'[.。،؟!؛\n]'))
            .where((s) => s.trim().length > 10)
            .map((s) => s.trim())
            .toList();
        if (sentences.isEmpty) {
          segments.add(trimmed);
        } else {
          for (var i = 0; i < sentences.length; i += 2) {
            final end = (i + 2).clamp(0, sentences.length);
            segments.add(sentences.sublist(i, end).join('، '));
          }
        }
      }
    }
    if (segments.isEmpty && content.trim().isNotEmpty) {
      segments.add(content.trim());
    }
    return segments;
  }

  List<_ScoredSegment> _scoreSegments(
    List<String> segments,
    List<String> questionKeywords,
  ) {
    if (segments.isEmpty || questionKeywords.isEmpty) return [];

    final docFrequency = <String, int>{};
    for (final keyword in questionKeywords) {
      var count = 0;
      for (final segment in segments) {
        if (_segmentContainsKeyword(segment, keyword)) count++;
      }
      docFrequency[keyword] = count;
    }

    final scored = <_ScoredSegment>[];
    final totalSegments = segments.length;

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final segmentKeywords = _extractKeywords(segment);
      var score = 0.0;

      for (final qk in questionKeywords) {
        if (_segmentContainsKeyword(segment, qk)) {
          // TF-IDF inspired scoring
          final tf =
              _countKeywordOccurrences(segment, qk) /
              segmentKeywords.length.clamp(1, 1000);
          final df = docFrequency[qk] ?? 1;
          final idf = math.log(totalSegments / df) / math.log(10) + 1;

          // SPECIALIZED TERM WEIGHTING:
          // Longer keywords or words that appear in fewer segments are often more important
          final weight = (qk.length > 4 ? 1.5 : 1.0) * (idf > 1.2 ? 1.3 : 1.0);
          score += tf * idf * weight;
        }

        // Fuzzy matching for Arabic variations (root matches)
        for (final sk in segmentKeywords) {
          if (sk != qk && _fuzzyMatch(qk, sk)) {
            score += 0.2; // Minor boost for partial matches
          }
        }
      }

      // MULTI-KEYWORD COHERENCE BOOST:
      // If a segment contains MULTIPLE different keywords from the question,
      // it's significantly more likely to be the direct answer.
      final uniqueMatches = questionKeywords
          .where((k) => _segmentContainsKeyword(segment, k))
          .length;

      if (uniqueMatches > 1) {
        score *= (1.0 + (uniqueMatches * 0.4));
      }

      if (score > 0) {
        scored.add(_ScoredSegment(segment: segment, score: score, index: i));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }

  bool _segmentContainsKeyword(String segment, String keyword) {
    return _removeDiacritics(
      segment.toLowerCase(),
    ).contains(_removeDiacritics(keyword.toLowerCase()));
  }

  int _countKeywordOccurrences(String segment, String keyword) {
    final ns = _removeDiacritics(segment.toLowerCase());
    final nk = _removeDiacritics(keyword.toLowerCase());
    var count = 0;
    var index = 0;
    while ((index = ns.indexOf(nk, index)) != -1) {
      count++;
      index += nk.length;
    }
    return count;
  }

  bool _fuzzyMatch(String word1, String word2) {
    if (word1.length < 3 || word2.length < 3) return false;
    if (word1.contains(word2) || word2.contains(word1)) return true;
    final r1 = _removeDiacritics(word1);
    final r2 = _removeDiacritics(word2);
    if (r1.length >= 3 && r2.length >= 3) {
      for (var i = 0; i <= r1.length - 3; i++) {
        if (r2.contains(r1.substring(i, i + 3))) return true;
      }
    }
    return false;
  }

  String _composeAnswer({
    required List<_ScoredSegment> scoredSegments,
    required String question,
    required List<String> questionKeywords,
    required String lessonTitle,
    required String fullContent,
  }) {
    if (scoredSegments.isEmpty) {
      return _buildGeneralSummary(fullContent, lessonTitle);
    }

    final buffer = StringBuffer();
    buffer.writeln(_greetings[_random.nextInt(_greetings.length)]);
    buffer.writeln();

    final questionType = _detectQuestionType(question);
    switch (questionType) {
      case _QuestionType.definition:
        buffer.writeln('خلني أعرّفلك الموضوع ده بطريقة بسيطة:');
      case _QuestionType.explanation:
        buffer.writeln('أوكي، خلني أوضحلك الموضوع ده:');
      case _QuestionType.reason:
        buffer.writeln('سؤال مهم! خلني أقول لك السبب:');
      case _QuestionType.comparison:
        buffer.writeln('تمام، خلني أقارن لك بين الموضوعين:');
      case _QuestionType.howTo:
        buffer.writeln('أوكي يا بطل، الطريقة كالتالي:');
      case _QuestionType.general:
        buffer.writeln('بحسب ما في الدرس بتاعنا:');
    }
    buffer.writeln();

    // Select top segments but maintain some variety
    final topSegments = scoredSegments.take(3).toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    // Confidence heuristic
    final avgScore = topSegments.isEmpty
        ? 0.0
        : topSegments.map((s) => s.score).reduce((a, b) => a + b) /
              topSegments.length;

    for (var i = 0; i < topSegments.length; i++) {
      if (i > 0) buffer.writeln();
      final segmentText = topSegments[i].segment.trim();

      // If confidence is high, present as factual, otherwise as "it seems"
      if (avgScore > 0.8 || i == 0) {
        buffer.writeln('• $segmentText');
      } else {
        buffer.writeln('• وتذكر المصادر كمان أن $segmentText');
      }
    }

    if (topSegments.length > 1) {
      buffer.writeln();
      buffer.writeln(
        'يعني باختصار، الموضوع مرتبط ببعضه وكل نقطة مكمّلة الثانية. 🔗',
      );
    }

    buffer.write(_closings[_random.nextInt(_closings.length)]);
    return buffer.toString();
  }

  String _buildGeneralSummary(String content, String lessonTitle) {
    final buffer = StringBuffer();
    buffer.writeln(_greetings[_random.nextInt(_greetings.length)]);
    buffer.writeln();
    buffer.writeln('خلني ألخّصلك درس "$lessonTitle" بطريقة بسيطة:');
    buffer.writeln();

    final segments = _segmentContent(content);
    for (var i = 0; i < segments.take(4).length; i++) {
      final segment = segments[i].trim();
      buffer.writeln(
        segment.length > 150
            ? '${i + 1}. ${segment.substring(0, 150)}...'
            : '${i + 1}. $segment',
      );
      buffer.writeln();
    }

    buffer.writeln(
      'هذي أهم النقاط في الدرس. لو تبي تفاصيل أكثر عن أي نقطة، اسألني! 💡',
    );
    buffer.write(_closings[_random.nextInt(_closings.length)]);
    return buffer.toString();
  }

  _QuestionType _detectQuestionType(String question) {
    final q = _removeDiacritics(question.toLowerCase());
    if (q.contains('ما هو') ||
        q.contains('ما هي') ||
        q.contains('ايش هو') ||
        q.contains('ايش هي') ||
        q.contains('ايش يعني') ||
        q.contains('شو يعني') ||
        q.contains('ماذا يعني') ||
        q.contains('ما معنى') ||
        q.contains('عرف') ||
        q.contains('تعريف')) {
      return _QuestionType.definition;
    }
    if (q.contains('لماذا') ||
        q.contains('ليش') ||
        q.contains('ليه') ||
        q.contains('لأي سبب') ||
        q.contains('السبب')) {
      return _QuestionType.reason;
    }
    if (q.contains('كيف') ||
        q.contains('كيفية') ||
        q.contains('طريقة') ||
        q.contains('خطوات')) {
      return _QuestionType.howTo;
    }
    if (q.contains('الفرق') ||
        q.contains('مقارنة') ||
        q.contains('قارن') ||
        q.contains('يختلف') ||
        q.contains('يتشابه')) {
      return _QuestionType.comparison;
    }
    if (q.contains('اشرح') ||
        q.contains('وضح') ||
        q.contains('فسر') ||
        q.contains('فهمني') ||
        q.contains('وضحلي')) {
      return _QuestionType.explanation;
    }
    return _QuestionType.general;
  }
}

class _ScoredSegment {
  _ScoredSegment({
    required this.segment,
    required this.score,
    required this.index,
  });
  final String segment;
  final double score;
  final int index;
}

enum _QuestionType {
  definition,
  explanation,
  reason,
  comparison,
  howTo,
  general,
}
