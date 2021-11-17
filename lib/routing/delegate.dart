import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
// import 'package:firebase_analytics/observer.dart';
import 'package:yhat_app/routing/stack.dart';

class MainRouterDelegate extends RouterDelegate<NavigationStack>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  final NavigationStack stack;
  final FirebaseAnalyticsObserver observer;

  @override
  void dispose() {
    stack.removeListener(notifyListeners);
    super.dispose();
  }

  MainRouterDelegate({required this.stack, required this.observer}) : super() {
    stack.addListener(notifyListeners);
  }

  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      observers: [observer],
      pages: _pages(context: context),
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        stack.pop();
        return true;
      },
    );
  }

  List<Page> _pages({required BuildContext context}) {
    return stack.items.toList();
  }

  @override
  NavigationStack get currentConfiguration {
    return stack;
  }

  @override
  Future<void> setNewRoutePath(NavigationStack configuration) async {
    stack.items = configuration.items;
  }
}
