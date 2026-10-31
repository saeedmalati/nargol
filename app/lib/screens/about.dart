import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../format.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'admin/admin_home.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final s = state.catalog!.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('درباره ما')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Center(child: Image.asset('assets/logo.png', width: 170)),
          Text(
            s.shopName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: NColors.oliveDark),
          ),
          if (s.slogan.isNotEmpty)
            Text(
              s.slogan,
              textAlign: TextAlign.center,
              style: const TextStyle(color: NColors.orange, fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 8),
          const Text(
            'تهیه‌شده به روش خانگی، با مواد اولیه تازه و باکیفیت',
            textAlign: TextAlign.center,
            style: TextStyle(color: NColors.muted),
          ),
          const SectionTitle('شعبه‌های ما'),
          for (final b in s.branches)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront, color: NColors.orange),
                          const SizedBox(width: 8),
                          Text(b.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(b.address, style: const TextStyle(height: 1.7, color: NColors.text)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => launchUrl(Uri.parse('tel:${b.phone}')),
                              icon: const Icon(Icons.call, size: 18),
                              label: Text(faDigits(b.phone)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => launchUrl(
                                Uri.parse('https://neshan.org/maps/search/${Uri.encodeComponent(b.address)}'),
                                mode: LaunchMode.externalApplication,
                              ),
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text('مسیریابی'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (s.healthCertificate.isNotEmpty || s.healthCard.isNotEmpty) ...[
            const SectionTitle('مجوزها'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    if (s.healthCertificate.isNotEmpty) _lic(Icons.verified_outlined, 'گواهینامه بهداشت', s.healthCertificate),
                    if (s.healthCard.isNotEmpty) _lic(Icons.badge_outlined, 'کارت بهداشت', s.healthCard),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => state.isAdmin ? const AdminHome() : const AdminLoginScreen())),
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 18, color: NColors.muted),
              label: const Text('ورود مدیر فروشگاه', style: TextStyle(color: NColors.muted)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lic(IconData icon, String title, String number) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, color: NColors.success, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(title)),
        Text(faDigits(number), style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final pass = TextEditingController();
  bool busy = false;

  Future<void> _login() async {
    setState(() => busy = true);
    final ok = await context.read<ShopState>().adminLogin(enDigits(pass.text.trim()));
    if (!mounted) return;
    setState(() => busy = false);
    if (ok) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminHome()));
    } else {
      showMsg(context, 'رمز اشتباه است', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ورود مدیر')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.lock_outline, size: 56, color: NColors.olive),
              const SizedBox(height: 16),
              TextField(
                controller: pass,
                obscureText: true,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.visiblePassword,
                onSubmitted: (_) => _login(),
                decoration: const InputDecoration(labelText: 'رمز مدیریت', prefixIcon: Icon(Icons.key)),
              ),
              if (isDemo)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('رمز نسخه نمایشی: ۱۲۳۴', style: TextStyle(color: NColors.muted, fontSize: 12)),
                ),
              const SizedBox(height: 16),
              FilledButton(onPressed: busy ? null : _login, child: const Text('ورود')),
            ],
          ),
        ),
      ),
    );
  }
}
