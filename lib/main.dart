import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'presentation/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Supabase.initialize(
    url: 'https://uloizqbcvfgeerulcdin.supabase.co',
    anonKey: 'sb_publishable_4ShQj8Ms-Y_FDy35rg4nDQ_I8vd2h0k',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RuaiTV Presensi',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}
