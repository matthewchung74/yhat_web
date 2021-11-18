import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:yhat_app/controller/providers.dart';
import 'package:yhat_app/page/build_nbs_page.dart';
import 'package:yhat_app/page/home_page.dart';
import 'package:yhat_app/page/model_edit_page.dart';
import 'package:yhat_app/page/signin_page.dart';

enum PushStatus { Success, NotLoggedIn }

class NavigationStack with ChangeNotifier {
  List<MaterialPage> _items;
  MeNotifier _meNotifier;
  FirebaseAnalytics _analytics;

  NavigationStack(List<MaterialPage> items, MeNotifier _meNotifier,
      FirebaseAnalytics analytics)
      : _items = items,
        _meNotifier = _meNotifier,
        _analytics = analytics;

  List<MaterialPage> get items => _items;
  set items(List<MaterialPage> newItems) {
    _items = newItems;
    notifyListeners();
  }

  void push(MaterialPage item) {
    print("push $item");
    if ((item.child is ModelEditPage || item.child is BuildNbsPage) &&
        !_meNotifier.isLoggedIn()) {
      return push(MaterialPage(
          key: ValueKey("SignIn"), child: SignInPage(referrer: item)));
    }

    if (item.name != null) {
      _analytics.logEvent(name: item.name!);
    }

    _items.add(item);
    notifyListeners();
  }

  Page? pop() {
    try {
      final poppedItem = _items.removeLast();
      notifyListeners();
      return poppedItem;
    } catch (e) {
      return null;
    }
  }

  void popToRoot() {
    try {
      _items.clear();
      push(MaterialPage(
          name: "HomePage", key: ValueKey("HomePage"), child: HomePage()));
      notifyListeners();
    } catch (e) {
      return null;
    }
  }
}
