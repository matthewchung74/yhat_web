import 'package:flutter/material.dart';
import 'package:yhat_app/controller/providers.dart';
import 'package:yhat_app/page/home_page.dart';
import 'package:yhat_app/page/signin_page.dart';
import 'dart:developer';

enum PushStatus { Success, NotLoggedIn }

class NavigationStack with ChangeNotifier {
  List<MaterialPage> _items;
  MeNotifier _meNotifier;

  List<String> authPages = ["ModelRunPage", "ModelEditPage", "BuildNbsPage"];

  NavigationStack(List<MaterialPage> items, MeNotifier _meNotifier)
      : _items = items,
        _meNotifier = _meNotifier;

  List<MaterialPage> get items => _items;
  set items(List<MaterialPage> newItems) {
    _items = newItems;
    notifyListeners();
  }

  void push(MaterialPage item) {
    print('push $authPages ${item.child.runtimeType.toString()}');
    print('push login ${_meNotifier.isLoggedIn()}');
    if (authPages.contains(item.child.runtimeType.toString()) &&
        !_meNotifier.isLoggedIn()) {
      return push(MaterialPage(
          key: ValueKey("SignIn"), child: SignInPage(referrer: item)));
    }

    _items.add(item);
    notifyListeners();
  }

  Page? pop() {
    try {
      final poppedItem = _items.removeLast();
      // var foo = _items.last.child as HomePage;
      // foo = "abc";
      notifyListeners();
      return poppedItem;
    } catch (e) {
      return null;
    }
  }

  void popToRoot() {
    try {
      _items.clear();
      push(MaterialPage(key: ValueKey("HomePage"), child: HomePage()));
      notifyListeners();
    } catch (e) {
      return null;
    }
  }
}
