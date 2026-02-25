# دليل التطوير - المعلم الذكي المحسّن

## الميزات الجديدة

### 1. لوحة التحكم المحسّنة (Enhanced Dashboard)
**الملف**: `enhanced_dashboard_page.dart`

#### الميزات:
- عرض إحصائيات التعلم (دروس مكملة، متوسط التقدم، ساعات التعلم)
- بطاقات إحصائية ملونة وتفاعلية
- عرض الدروس المميزة
- واجهة محسّنة مع صور توضيحية

#### الاستخدام:
```dart
// في main.dart أو الملفات التي تحتاج إلى عرض الـ Dashboard
BlocProvider<EnhancedDashboardCubit>(
  create: (_) => getIt<EnhancedDashboardCubit>(),
  child: EnhancedDashboardPage(),
),
```

### 2. خدمة المعلم الذكي (SmartTeacherService)
**الملف**: `smart_teacher_service.dart`

#### الميزات:
- شروحات تفصيلية للدروس
- ملخصات قصيرة
- إنشاء أسئلة اختبار
- الإجابة على الأسئلة
- تحويل النصوص إلى كلام (TTS)
- تحليل مستوى التعلم
- نصائح دراسية ذكية

#### الاستخدام:
```dart
final smartTeacherService = getIt<SmartTeacherService>();

// الحصول على شرح
final explanation = await smartTeacherService.getDetailedExplanation(
  lessonContent,
  difficulty: 'medium',
);

// تحويل إلى كلام
await smartTeacherService.speak(explanation);

// إنشاء أسئلة
final questions = await smartTeacherService.generateQuestions(
  lessonContent,
  count: 5,
);

// الحصول على ملخص
final summary = await smartTeacherService.getSummary(lessonContent);

// الإجابة على سؤال
final answer = await smartTeacherService.answerQuestion(
  lessonContent,
  'ما هو ...؟',
);
```

### 3. خدمة الوسائط (MediaService)
**الملف**: `media_service.dart`

#### الميزات:
- التقاط صور من الكاميرا
- اختيار صور من المعرض
- التقاط فيديو
- اختيار فيديو من المعرض
- حفظ الملفات محلياً
- حذف الملفات
- التحقق من وجود الملفات

#### الاستخدام:
```dart
final mediaService = getIt<MediaService>();

// التقاط صورة من الكاميرا
final image = await mediaService.pickImageFromCamera();

// اختيار فيديو
final video = await mediaService.pickVideoFromGallery();

// حفظ الصورة
final savedPath = await mediaService.saveImageLocally(
  image,
  'lesson_${DateTime.now().millisecondsSinceEpoch}.jpg',
);

// حذف ملف
await mediaService.deleteFile(filePath);
```

### 4. عارض الوسائط (MediaViewerWidget)
**الملف**: `media_viewer_widget.dart`

#### الميزات:
- عرض الصور بجودة عالية
- تشغيل الفيديوهات
- بطاقات وسائط تفاعلية

#### الاستخدام:
```dart
MediaViewerWidget(
  mediaPath: imagePath,
  mediaType: 'image', // أو 'video'
  title: 'عنوان الوسيط',
),
```

### 5. واجهة المعلم الذكي المحسّنة
**الملف**: `enhanced_teacher_explanation_widget.dart`

#### الميزات:
- خيارات متعددة (شرح مفصل، ملخص، أسئلة، نصائح)
- تحويل النصوص إلى كلام
- تحكم كامل على الصوت (تشغيل، إيقاف، توقيف مؤقت)
- واجهة حديثة وسهلة الاستخدام

#### الاستخدام:
```dart
ElevatedButton(
  onPressed: () => EnhancedTeacherExplanationWidget.show(
    context,
    lessonContent,
  ),
  child: const Text('المعلم الذكي'),
),
```

### 6. صفحة الدرس المحسّنة
**الملف**: `enhanced_lesson_page.dart` و `enhanced_lesson_content.dart`

#### الميزات:
- تبويبات متعددة (محتوى، صوت، صورة، فيديو)
- دعم الوسائط المختلفة
- عرض محسّن للمحتوى
- واجهة سهلة الاستخدام

## التكامل مع التطبيق الحالي

### تحديث main.dart
```dart
// استبدل DashboardCubit بـ EnhancedDashboardCubit
BlocProvider<EnhancedDashboardCubit>(
  create: (_) => getIt<EnhancedDashboardCubit>(),
),

// أضف SmartTeacherCubit
BlocProvider<SmartTeacherCubit>(
  create: (_) => getIt<SmartTeacherCubit>(),
),
```

### تحديث navigation
```dart
// استبدل الملاحة القديمة
Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => EnhancedLessonPage(
      lessonId: lesson.id,
      userId: userId,
    ),
  ),
),
```

## نموذج بيانات الدرس المحسّن

```dart
class Lesson {
  final String id;
  final String title;
  final String content;
  final String audioPath;
  final String? imagePath;      // جديد
  final String? videoPath;       // جديد
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

## الوصول إلى الخدمات

```dart
// في أي مكان في التطبيق
final smartTeacherService = getIt<SmartTeacherService>();
final mediaService = getIt<MediaService>();
final enhancedDashboardCubit = getIt<EnhancedDashboardCubit>();
```

## الخطوات التالية

1. **تحديث قاعدة البيانات**:
   - أضف الحقول الجديدة (imagePath, videoPath) إلى جدول الدروس
   - قم بتشغيل ترحيل قاعدة البيانات

2. **واجهة المستخدم**:
   - أضف زر لتحميل الصور والفيديو في محرر الدروس
   - أضف معاينات للوسائط المحملة

3. **الاختبار**:
   - اختبر الخدمات الجديدة بدروس فعلية
   - تحقق من أداء الصوت والفيديو
   - اختبر الشروحات الذكية

4. **التحسينات المستقبلية**:
   - إضافة دعم التعليقات التوضيحية على الصور
   - إضافة اختبارات سريعة تفاعلية
   - دعم الإشارات اليدوية في الفيديو
   - تحسين جودة الشروحات الذكية

## المشاكل الشائعة والحلول

### مشكلة: فشل تحميل الصور
**الحل**: تأكد من الأذونات في AndroidManifest.xml و Info.plist

### مشكلة: الصوت لا يشتغل
**الحل**: تأكد من تهيئة TTS بشكل صحيح واللغة معينة إلى العربية

### مشكلة: بطء التطبيق عند الوسائط الكبيرة
**الحل**: استخدم المعالجة غير المتزامنة (async/await) وأضف مؤشرات التحميل

## الدعم والمساعدة

للحصول على تفاصيل أكثر، راجع:
- [وثائق Flutter](https://flutter.dev)
- [وثائق Gemma](https://ai.google.dev/gemma)
- [وثائق BLoC](https://bloclibrary.dev)
