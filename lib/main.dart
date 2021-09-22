import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inference_app/controller/providers.dart';
import 'package:inference_app/page/home_page.dart';
import 'package:inference_app/routing/delegate.dart';
import 'package:inference_app/routing/parser.dart';
import 'package:inference_app/routing/stack.dart';
import 'package:inference_app/routing/configure_nonweb.dart'
    if (dart.library.html) 'package:inference_app/routing/configure_web.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

final navigationStackProvider =
    ChangeNotifierProvider((ref) => NavigationStack([
          MaterialPage(key: ValueKey("HomePage"), child: HomePage()),
        ], ref.read(meController.notifier)));

Future main() async {
  configureApp();

  await DotEnv.load(fileName: ".env");

  await SentryFlutter.init(
    (options) => options.dsn = env['SENTRY_URL']!,
    appRunner: () => runApp(MyApp()),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Builder(builder: (context) {
        return LoadMeApp();
      }),
    );
  }
}

final provider = FutureProvider<void>((ref) async {
  await ref.read(meController.notifier).load();
  await ref.read(referrerController.notifier).load();
});

class LoadMeApp extends ConsumerWidget {
  const LoadMeApp({Key? key}) : super(key: key);

  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<void> me = ref.watch(provider);

    return me.when(
      loading: () => Directionality(
          textDirection: TextDirection.rtl,
          child: Container(child: Text('loading'))),
      error: (err, stack) => Container(child: Text('Error: $err')),
      data: (config) {
        return MyNavApp();
      },
    );
  }
}

class MyNavApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerDelegate:
          MainRouterDelegate(stack: ref.read(navigationStackProvider)),
      routeInformationParser: MainRouterInformationParser(ref: ref),
      theme: ThemeData(
          appBarTheme: const AppBarTheme(
              backgroundColor: Color.fromRGBO(26, 36, 54, 1),
              iconTheme: const IconThemeData(color: Colors.white)),
          scaffoldBackgroundColor: Color.fromRGBO(243, 243, 246, 1),
          primaryColor: Colors.white,
          // accentColor: Color(0xFF2AAF61),
          iconTheme: const IconThemeData(color: Colors.white),
          fontFamily: GoogleFonts.montserrat().fontFamily,
          textTheme: TextTheme(
            headline2: const TextStyle(
              color: Colors.white,
              fontSize: 48.0,
              fontWeight: FontWeight.bold,
            ),
            headline3: const TextStyle(
              color: Color.fromRGBO(26, 36, 54, 1),
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
            ),
            headline4: TextStyle(
                fontSize: 24.0,
                color: Colors.grey[300],
                fontWeight: FontWeight.w500,
                letterSpacing: 2.0),
            headline5: TextStyle(
                fontSize: 20.0,
                color: Colors.grey[300],
                fontWeight: FontWeight.w500,
                letterSpacing: 2.0),
            bodyText1: TextStyle(
              color: Color.fromRGBO(18, 29, 41, 1),
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
            bodyText2: TextStyle(
              color: Color.fromRGBO(70, 70, 70, 1),
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(primary: Colors.blue.shade700)),
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(primary: Colors.blue.shade700))),
    );
  }
}
