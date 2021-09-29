import 'package:flutter/material.dart';
import 'package:yhat_app/controller/providers.dart';
import 'package:yhat_app/page/home_page.dart';
import 'package:yhat_app/page/signin_page.dart';

enum PushStatus { Success, NotLoggedIn }

class NavigationStack with ChangeNotifier {
  List<MaterialPage> _items;
  MeNotifier _meNotifier;

  List<String> authPages = ["RunModelPage"];

  NavigationStack(List<MaterialPage> items, MeNotifier _meNotifier)
      : _items = items,
        _meNotifier = _meNotifier;

  List<MaterialPage> get items => _items;
  set items(List<MaterialPage> newItems) {
    _items = newItems;
    notifyListeners();
  }

  void push(MaterialPage item) {
    String key = item.key != null ? item.key!.toString() : '';
    key = item.key.toString().replaceAll("[<'", "");
    key = key.replaceAll("'>]", "");
    key = key.split("_")[0];
    if (authPages.contains(key) && !_meNotifier.isLoggedIn()) {
      return push(MaterialPage(
          key: ValueKey("SignIn"), child: SignInPage(referrer: item)));
    }

    // for (MaterialPage map in _items) {
    //   if (map.key.toString() == item.key.toString()) {
    //     _items.remove(map);
    //   }
    // }

    if (_items.isEmpty || _items.last.key != item.key) {
      _items.add(item);
      notifyListeners();
    }
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
