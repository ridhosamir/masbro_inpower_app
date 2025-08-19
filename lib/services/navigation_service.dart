import 'package:flutter/material.dart';

class NavigationService {
  // Global key untuk navigator
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Getter untuk mendapatkan current context
  BuildContext? get currentContext => navigatorKey.currentContext;

  // Getter untuk mendapatkan current navigator state
  NavigatorState? get currentNavigator => navigatorKey.currentState;

  // Method untuk navigasi push
  Future<dynamic> pushNamed(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!
        .pushNamed(routeName, arguments: arguments);
  }

  // Method untuk navigasi push replacement
  Future<dynamic> pushReplacementNamed(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!
        .pushReplacementNamed(routeName, arguments: arguments);
  }

  // Method untuk navigasi push and remove until
  Future<dynamic> pushNamedAndRemoveUntil(
    String routeName,
    bool Function(Route<dynamic>) predicate, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
      predicate,
      arguments: arguments,
    );
  }

  // Method untuk pop
  void pop([dynamic result]) {
    return navigatorKey.currentState!.pop(result);
  }

  // Method untuk pop until
  void popUntil(bool Function(Route<dynamic>) predicate) {
    return navigatorKey.currentState!.popUntil(predicate);
  }

  // Method untuk push dengan MaterialPageRoute
  Future<dynamic> push(Widget page) {
    return navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  // Method untuk push replacement dengan MaterialPageRoute
  Future<dynamic> pushReplacement(Widget page) {
    return navigatorKey.currentState!.pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  // Method untuk push dan clear stack
  Future<dynamic> pushAndClearStack(Widget page) {
    return navigatorKey.currentState!.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  // Method untuk mendapatkan current route name
  String? get currentRoute {
    String? currentPath;
    navigatorKey.currentState!.popUntil((route) {
      currentPath = route.settings.name;
      return true;
    });
    return currentPath;
  }

  // Method untuk cek apakah bisa pop
  bool canPop() {
    return navigatorKey.currentState!.canPop();
  }

  // Method untuk show dialog
  Future<T?> showDialogCustom<T>({
    required Widget Function(BuildContext) builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
  }) {
    return showDialog<T>(
      context: navigatorKey.currentContext!,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
    );
  }

  // Method untuk show bottom sheet
  Future<T?> showBottomSheetCustom<T>({
    required Widget Function(BuildContext) builder,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: navigatorKey.currentContext!,
      builder: builder,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
    );
  }

  // Method untuk show snackbar
  void showSnackBar({
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final messenger = ScaffoldMessenger.of(navigatorKey.currentContext!);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor),
        ),
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
      ),
    );
  }

  // Method untuk show success snackbar
  void showSuccessSnackBar(String message) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  // Method untuk show error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  // Method untuk show warning snackbar
  void showWarningSnackBar(String message) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
  }
}
