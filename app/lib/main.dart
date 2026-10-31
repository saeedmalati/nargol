import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'repo.dart';
import 'screens/shell.dart';
import 'state.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (const bool.fromEnvironment('SEMANTICS')) SemanticsBinding.instance.ensureSemantics();
  final state = ShopState(ShopRepository.create())..init();
  runApp(ChangeNotifierProvider.value(value: state, child: const NargolApp()));
}

class NargolApp extends StatelessWidget {
  const NargolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نارگل',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Shell(),
    );
  }
}
