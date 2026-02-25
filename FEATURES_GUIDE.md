# الدليل السريع للمعلم الذكي

## ما هو المعلم الذكي؟

تطبيق تعليمي ذكي يوفر:
- 📚 محتوى تعليمي جديد
- 🎓 شروحات ذكية باستخدام الذكاء الاصطناعي (Gemma)
- 🎵 دعم الصوت والتحويل من النصوص إلى كلام
- 📸 دعم الصور والفيديو
- 📊 إحصائيات تعليمية متقدمة
- 🔄 مزامنة تلقائية مع قاعدة البيانات
- ✅ تتبع التقدم والإنجازات

## الميزات الرئيسية

### 1. لوحة التحكم الرئيسية
- عرض ملف الطالب
- إحصائيات التعلم (دروس مكملة، متوسط التقدم، ساعات التعلم)
- قائمة الدروس المتاحة مع شريط التقدم
- حالة الاتصال والمزامنة

### 2. صفحات الدروس
- عرض يتضمن تبويبات متعددة:
  - محتوى الدرس نصي
  - الصوت (إن وجد)
  - الصور التوضيحية
  - الفيديو التعليمي

### 3. المعلم الذكي
- **شرح مفصل**: شرح شامل لمحتوى الدرس
- **ملخص**: نقاط مهمة من الدرس
- **أسئلة اختبار**: أسئلة تقييمية متنوعة
- **نصائح دراسية**: نصائح عملية لفهم أفضل
- **تحويل إلى كلام**: قراءة النصوص بصوت واضح

### 4. إدارة الوسائط
- التقاط صور من الكاميرا أو اختيارها من المعرض
- تسجيل فيديوهات أو اختيار من المعرض
- حفظ وتنظيم الوسائط
- عرض سريع وسهل للوسائط

## الخطوات الأولى

### تثبيت المتطلبات

```bash
# تثبيت جميع المكتبات
flutter pub get

# تشغيل مولد الكود
dart run build_runner build
```

### تشغيل التطبيق

```bash
# تشغيل التطبيق في وضع Debug
flutter run

# تشغيل للجهاز المحدد
flutter run -d <device_id>
```

## هيكل المشروع

```
lib/
├── core/
│   ├── di/              # Dependency Injection
│   └── logger/          # نظام السجلات
├── features/
│   └── education/
│       ├── data/
│       │   ├── datasources/
│       │   ├── repositories/
│       │   └── services/
│       │       ├── gemma_service.dart          # خدمة الذكاء الاصطناعي
│       │       ├── smart_teacher_service.dart  # خدمة المعلم الذكي
│       │       ├── media_service.dart          # خدمة الوسائط
│       │       └── sync_manager.dart           # إدارة المزامنة
│       └── presentation/
│           ├── cubit/
│           │   ├── dashboard_cubit.dart                  # إدارة لوحة التحكم
│           │   ├── enhanced_dashboard_cubit.dart        # لوحة تحكم محسّنة
│           │   ├── smart_teacher_cubit.dart             # إدارة المعلم الذكي
│           │   └── lesson_cubit.dart                    # إدارة الدروس
│           ├── pages/
│           │   ├── dashboard_page.dart
│           │   ├── enhanced_dashboard_page.dart         # لوحة تحكم محسّنة
│           │   ├── lesson_page.dart
│           │   └── enhanced_lesson_page.dart            # دروس محسّنة
│           └── widgets/
│               ├── teacher_explanation_widget.dart
│               ├── enhanced_teacher_explanation_widget.dart   # معلم ذكي محسّن
│               ├── media_viewer_widget.dart                   # عارض الوسائط
│               ├── lesson_content.dart
│               └── enhanced_lesson_content.dart              # محتوى محسّن
```

## أمثلة الاستخدام

### استخدام المعلم الذكي

```dart
import 'package:global_smart_education_platform/core/di/injection.dart';
import 'package:global_smart_education_platform/features/education/presentation/cubit/smart_teacher_cubit.dart';

// في الواجهة
BlocProvider<SmartTeacherCubit>(
  create: (_) => getIt<SmartTeacherCubit>(),
  child: MyWidget(),
),

// الحصول على شرح
void _requestExplanation() {
  context.read<SmartTeacherCubit>().getDetailedExplanation(
    lessonContent,
    difficulty: 'medium',
  );
}

// الاستماع للتغييرات
BlocBuilder<SmartTeacherCubit, SmartTeacherState>(
  builder: (context, state) => state.when(
    loading: () => CircularProgressIndicator(),
    explanation: (text) => Text(text),
    error: (msg) => Text('خطأ: $msg'),
    // ...
  ),
),
```

### استخدام خدمة الوسائط

```dart
import 'package:global_smart_education_platform/features/education/data/services/media_service.dart';

final mediaService = getIt<MediaService>();

// التقاط صورة
final image = await mediaService.pickImageFromCamera();

// حفظ الصورة
if (image != null) {
  final savedPath = await mediaService.saveImageLocally(
    image,
    'lesson_image.jpg',
  );
}

// عرض الصورة
MediaViewerWidget(
  mediaPath: savedPath,
  mediaType: 'image',
  title: 'صورة الدرس',
),
```

## الإعدادات المطلوبة

### Android (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (Info.plist)

```xml
<key>NSCameraUsageDescription</key>
<string>نحتاج الوصول للكاميرا لالتقاط الصور</string>
<key>NSMicrophoneUsageDescription</key>
<string>نحتاج الوصول للميكروفون لتسجيل الصوت</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>نحتاج الوصول للمعرض لاختيار الصور</string>
```

## الأداء والتحسينات

### نصائح لتحسين الأداء

1. **استخدم المعالجة غير المتزامنة**
   - تجنب العمليات الثقيلة على الخيط الرئيسي
   - استخدم `async/await`

2. **تحميل الوسائط بذكاء**
   - قم بتحميل الصور بحجم مناسب
   - استخدم التحميل الكسول للفيديوهات الطويلة

3. **تخزين مؤقت فعال**
   - احفظ الشروحات المولدة
   - أعد استخدام البيانات المحملة

4. **مراقبة الموارد**
   - راقب استهلاك الذاكرة
   - تحقق من الأداء على أجهزة منخفضة الموارد

## استكشاف الأخطاء

### المشكلة: الصوت لا يعمل
**الحل:**
1. تحقق من الأذونات
2. تأكد من تهيئة TTS (`initTTS`)
3. جرّب لغة أخرى

### المشكلة: الصور لا تظهر
**الحل:**
1. تحقق من وجود الملف
2. تأكد من صلاحيات القراءة
3. جرّب إعادة تشغيل التطبيق

### المشكلة: بطء الشروحات
**الحل:**
1. تحقق من اتصال الإنترنت
2. جرب نموذج أصغر من Gemma
3. استخدم ذاكرة مؤقتة

## المساهمة والتطوير

للمساهمة في تطوير التطبيق:

1. أنشئ فرعاً جديداً (`feature/your-feature`)
2. أضف التحسينات
3. اختبر الكود جيداً
4. أرسل طلب دمج

## الترخيص

هذا المشروع مرخص بموجب [اختر الترخيص المناسب]

## الدعم

للمساعدة والدعم:
- 📧 البريد الإلكتروني: support@...
- 💬 المناقشات: [رابط]
- 🐛 الأخطاء: [رابط]

---

**آخر تحديث**: فبراير 2026
