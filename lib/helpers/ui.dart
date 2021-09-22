import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> launchURLBrowser(
    {required String url, String target = '_blank'}) async {
  if (url.startsWith("data:application") || await canLaunch(url)) {
    return await launch(
      url,
      webOnlyWindowName: target,
    );
  } else {
    throw 'Could not launch $url';
  }
}

int columnsForWidth({required BuildContext context}) {
  var screenWidth = MediaQuery.of(context).size.width;
  return screenWidth > 1024
      ? 4
      : screenWidth > 800
          ? 3
          : screenWidth > 540
              ? 2
              : 1;
}
