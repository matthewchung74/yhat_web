import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yhat_app/api/api.dart';
import 'package:yhat_app/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

final analyticsProvider = Provider<FirebaseAnalytics>((ref) {
  FirebaseAnalytics analytics = FirebaseAnalytics();
  analytics.setAnalyticsCollectionEnabled(true);
  return analytics;
});

final analyticsObserver =
    Provider<FirebaseAnalyticsObserver>((ref) => FirebaseAnalyticsObserver(
          analytics: ref.read(analyticsProvider),
          nameExtractor: (RouteSettings settings) {
            MaterialPage page = (settings as MaterialPage);
            print("analytics ${page.child.toString()}");
            return page.child.toString();
          },
          onError: (error) {
            print(error);
          },
        ));

final apiProvider = Provider<API>((ref) => API(read: ref.read));

class MeNotifier extends StateNotifier<User> {
  MeNotifier(this.read) : super(User());

  final Reader read;

  bool isLoggedIn() {
    if (state.token != null) {
      if (!isExpired(state.token!.token)) {
        return true;
      }
    }
    logout();
    return false;
  }

  Future<void> persist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('me', json.encode(state));
  }

  Future<void> load() async {
    print('load');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print('load:SharedPreferences');
    if (prefs.getString('me') != null) {
      print('load: me ${prefs.getString('me')}');

      User user = User.fromJson(json.decode(prefs.getString('me')!));
      if (user.token == null) {
        prefs.remove('me');
      } else {
        bool expired = isExpired(user.token!.token);
        if (expired) {
          prefs.remove('me');
        } else {
          state = user;
        }
      }
      read(analyticsProvider).setUserId(user.id);
    } else {
      print('load:no me');
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('me');
    read(analyticsProvider).setUserId(null);

    state = User();
  }
}

final meController = StateNotifierProvider<MeNotifier, User>((ref) {
  return MeNotifier(ref.read);
});

class ReferrerNotifier extends StateNotifier<String?> {
  ReferrerNotifier(this.read) : super(null);

  final Reader read;

  String? get url => state;
  set url(String? url) {
    state = url;
  }

  Future<void> persist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (state == null) {
      await remove();
    } else {
      print("persist: $state");
      await prefs.setString('login_referrer', state!);
      print("persisted");
    }
  }

  Future<void> load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('login_referrer') != null) {
      state = prefs.getString('login_referrer');
      await remove();
    }
  }

  Future<void> remove() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('login_referrer');
  }
}

final referrerController =
    StateNotifierProvider<ReferrerNotifier, String?>((ref) {
  return ReferrerNotifier(ref.read);
});

// jwt helpers

bool isExpired(String token) {
  Map<String, dynamic> jwt = parseJwt(token);
  DateTime expires =
      DateTime.fromMillisecondsSinceEpoch((jwt['expires'] * 1000).toInt());
  return expires.isBefore(DateTime.now().subtract(Duration(hours: 1)));
}

Map<String, dynamic> parseJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw Exception('invalid token');
  }

  final payload = _decodeBase64(parts[1]);
  final payloadMap = json.decode(payload);
  if (payloadMap is! Map<String, dynamic>) {
    throw Exception('invalid payload');
  }

  return payloadMap;
}

String _decodeBase64(String str) {
  String output = str.replaceAll('-', '+').replaceAll('_', '/');

  switch (output.length % 4) {
    case 0:
      break;
    case 2:
      output += '==';
      break;
    case 3:
      output += '=';
      break;
    default:
      throw Exception('Illegal base64url string!"');
  }

  return utf8.decode(base64Url.decode(output));
}
