import 'package:yhat_app/controller/providers.dart';

class TokenException implements Exception {
  String? cause;
  MeNotifier? notifier;
  bool? shouldLogout;
  TokenException({this.cause, this.notifier, shouldLogout}) {
    if (shouldLogout != null && shouldLogout! == true) {
      if (notifier != null) {
        notifier!.logout();
      }
    }
  }
}

class NotFoundException implements Exception {
  NotFoundException();
}
