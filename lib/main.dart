import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:curf_app/core/routing/app_router.dart';

void main() async {
  // 1. This line ensures Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. This line starts the Supabase engine BEFORE the app starts
  await Supabase.initialize(
    url: 'https://shwhobyoczvwmfkjjozv.supabase.co',
    anonKey: 'sb_publishable_bo-E12YusBVbIdtiSwglfQ_sN9F_6S0',
  );

  // 3. Start the background database listener
  startRealTimePassListener();

  // 4. Now it is safe to run the app
  runApp(const ProviderScope(child: CurfApp()));
}

class CurfApp extends ConsumerWidget {
  const CurfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
} // <--- CurfApp ends cleanly here

// ==========================================
// STANDALONE GLOBAL FUNCTION (AT THE BOTTOM)
// ==========================================
void startRealTimePassListener() {
  try {
    Supabase.instance.client
        .channel('public:out_passes')
        .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'out_passes',
        callback: (payload) {
          print("REALTIME STATUS UPDATE: ${payload.newRecord}");
          // This triggers automatically whenever a pass status changes
        })
        .subscribe();
  } catch (e) {
    print("Realtime listener error: $e");
  }
}