import 'package:flutter/material.dart';
import 'package:yhat_app/routing/stack.dart';

class MainRouterDelegate extends RouterDelegate<NavigationStack>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  final NavigationStack stack;

  @override
  void dispose() {
    stack.removeListener(notifyListeners);
    super.dispose();
  }

  MainRouterDelegate({required this.stack}) : super() {
    stack.addListener(notifyListeners);
  }

  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
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
