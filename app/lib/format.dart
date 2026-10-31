const _fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

String faDigits(Object s) => s.toString().replaceAllMapped(RegExp(r'\d'), (m) => _fa[int.parse(m[0]!)]);

/// تبدیل ارقام فارسی/عربی به انگلیسی (برای ورودی کاربر)
String enDigits(String s) {
  const fa = '۰۱۲۳۴۵۶۷۸۹', ar = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = fa.indexOf(ch), j = ar.indexOf(ch);
    b.write(
      i >= 0
          ? '$i'
          : j >= 0
          ? '$j'
          : ch,
    );
  }
  return b.toString();
}

String groupDigits(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('٬');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
}

String toman(int n) => '${faDigits(groupDigits(n))} تومان';

String faDate(DateTime d) {
  // تاریخ شمسی (الگوریتم ساده تبدیل میلادی به جلالی)
  final j = _toJalali(d.year, d.month, d.day);
  String two(int x) => x.toString().padLeft(2, '0');
  return faDigits('${j[0]}/${two(j[1])}/${two(j[2])} - ${two(d.hour)}:${two(d.minute)}');
}

List<int> _toJalali(int gy, int gm, int gd) {
  const gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  final gy2 = gm > 2 ? gy + 1 : gy;
  var days = 355666 + 365 * gy + (gy2 + 3) ~/ 4 - (gy2 + 99) ~/ 100 + (gy2 + 399) ~/ 400 + gd + gdm[gm - 1];
  var jy = -1595 + 33 * (days ~/ 12053);
  days %= 12053;
  jy += 4 * (days ~/ 1461);
  days %= 1461;
  if (days > 365) {
    jy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }
  final jm = days < 186 ? 1 + days ~/ 31 : 7 + (days - 186) ~/ 30;
  final jd = 1 + (days < 186 ? days % 31 : (days - 186) % 30);
  return [jy, jm, jd];
}
