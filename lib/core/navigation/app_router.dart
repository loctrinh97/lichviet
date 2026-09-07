import 'package:flutter/material.dart';
import '../../features/auth/view/login_screen.dart';
import '../../features/calendar/view/home_screen.dart';
import 'app_routes.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return _page(const LoginScreen());
      case AppRoutes.lichViet:
        return _page(const HomeScreen());
      default:
        return _page(const HomeScreen());
    }
  }

  static MaterialPageRoute<T> _page<T>(Widget child) =>
      MaterialPageRoute<T>(builder: (_) => child);
}
