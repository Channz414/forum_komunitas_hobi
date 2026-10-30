import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'core/config.dart';
import 'core/theme.dart';
import 'providers/community_provider.dart';
import 'providers/post_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
  timeago.setLocaleMessages('id', timeago.IdMessages());
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
      ],
      child: MaterialApp(
        title: 'Forum Komunitas Hobi',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: StreamBuilder<AuthState>(
          stream: supabase.auth.onAuthStateChange,
          builder: (context, _) => supabase.auth.currentSession == null
              ? const LoginScreen()
              : const MainShell(),
        ),
      ),
    );
  }
}
