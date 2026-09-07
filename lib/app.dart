import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/app_routes.dart';
import 'core/navigation/navigation_service.dart';
import 'shared/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => ProviderScope(
        child: MaterialApp(
          title: 'Lịch Việt',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi'), Locale('en')],
          locale: const Locale('vi'),
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          initialRoute: AppRoutes.lichViet,
          onGenerateRoute: AppRouter.onGenerateRoute,
          builder: EasyLoading.init(),
        ),
      );
}

