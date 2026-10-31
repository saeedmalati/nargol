/// آدرس سرور. اگر خالی باشد، اپ در «حالت نمایشی» اجرا می‌شود
/// و همه اطلاعات روی خود گوشی ذخیره می‌شود.
///
/// هنگام ساخت نسخه نهایی:
///   flutter build apk --dart-define=API_BASE=https://api.nargol.ir
const String apiBase = String.fromEnvironment('API_BASE', defaultValue: '');

bool get isDemo => apiBase.isEmpty;

/// رمز پنل مدیریت در حالت نمایشی (در حالت سرور، رمز روی سرور تعیین می‌شود).
const String demoAdminPassword = '1234';
