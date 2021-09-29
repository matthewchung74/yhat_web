import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yhat_app/helpers/ui.dart';
import 'package:yhat_app/page/signin_page.dart';
import 'package:yhat_app/routing/stack.dart';

import '../main.dart';

enum SnackBarStatus { Alert, Info, Success }
enum CTA { None, Login }

void showSnackBar(
    {required BuildContext context,
    required String message,
    required SnackBarStatus status}) {
  new Future.microtask(() {
    Color backgroundColor = Colors.red;
    Color textColor = Colors.white;
    switch (status) {
      case SnackBarStatus.Alert:
        backgroundColor = Colors.red.shade700;
        textColor = Colors.white;
        break;
      case SnackBarStatus.Info:
        backgroundColor = Colors.green.shade700;
        textColor = Colors.white;
        break;
      case SnackBarStatus.Success:
        backgroundColor = Colors.green.shade700;
        textColor = Colors.white;
        break;
      default:
    }

    Flushbar(
        duration: Duration(seconds: 5),
        flushbarPosition: FlushbarPosition.TOP,
        backgroundColor: backgroundColor,
        messageText: Text(message,
            style: Theme.of(context)
                .textTheme
                .headline5!
                .copyWith(color: textColor)))
      ..show(context);
  });
}

//ignore: must_be_immutable
class SnackBarWidget extends StatefulWidget {
  final SnackBarStatus? snackBarStatus;
  final String? message;
  CTA? cta;
  SnackBarWidget({Key? key, this.snackBarStatus, this.message})
      : super(key: key) {
    if (message == "Not able to sign in, please try again.") {
      cta = CTA.Login;
    } else {
      cta = CTA.None;
    }
  }

  @override
  _SnackBarWidgetState createState() => _SnackBarWidgetState(
      snackBarStatus: snackBarStatus, message: message, cta: cta!);
}

class _SnackBarWidgetState extends State<SnackBarWidget> {
  final SnackBarStatus? snackBarStatus;
  final String? message;
  final CTA cta;
  _SnackBarWidgetState(
      {required this.snackBarStatus,
      required this.message,
      this.cta = CTA.None});

  @override
  void initState() {
    if (message != null && snackBarStatus != null) {
      showSnackBar(
          context: context, message: message!, status: snackBarStatus!);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    if (cta == CTA.Login) {
      return Container(
        height: screenHeight * 0.4,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SelectableText(
                    "TRY SIGNING IN AGAIN",
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                  SizedBox(
                    width: 4,
                  ),
                  Icon(
                    Icons.sentiment_neutral,
                    color: Theme.of(context).textTheme.bodyText2!.color,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 60,
                    width: 200,
                    child: Consumer(builder: (context, ref, _) {
                      NavigationStack nav = ref.read(navigationStackProvider);
                      return OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.grey.shade800, width: 1),
                          ),
                          onPressed: () {
                            nav.push(MaterialPage(
                                key: ValueKey("SignIn"), child: SignInPage()));
                          },
                          child: Text(
                            "Sign In",
                            style: Theme.of(context)
                                .textTheme
                                .headline5!
                                .copyWith(color: Colors.grey.shade800),
                          ));
                    }),
                  ),
                ],
              )
            ]),
      );
    } else {
      return Container(
        height: screenHeight * 0.4,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SelectableText(
                    "TRY REFRESHING PAGE",
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                  SizedBox(
                    width: 4,
                  ),
                  Icon(
                    Icons.sentiment_neutral,
                    color: Theme.of(context).textTheme.bodyText2!.color,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 60,
                    width: 200,
                    child: Consumer(builder: (context, ref, _) {
                      return OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.grey.shade800, width: 1),
                          ),
                          onPressed: () {
                            launchURLBrowser(
                                url:
                                    "${Uri.base.scheme}://${Uri.base.host}:${Uri.base.port}",
                                target: "_self");
                          },
                          child: Text(
                            "Refresh",
                            style: Theme.of(context)
                                .textTheme
                                .headline5!
                                .copyWith(color: Colors.grey.shade800),
                          ));
                    }),
                  ),
                ],
              )
            ]),
      );
    }
  }
}
