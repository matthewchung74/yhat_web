import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inference_app/controller/providers.dart';
import 'package:inference_app/page/model_edit_page.dart';
import 'package:inference_app/page/home_page.dart';
import 'package:inference_app/page/build_start_page.dart';
import 'package:inference_app/page/model_page.dart';
import 'package:inference_app/page/build_nbs_page.dart';
import 'package:inference_app/page/profile_page.dart';
import 'package:inference_app/page/model_run_page.dart';
import 'package:inference_app/page/run_list_page.dart';
import 'package:inference_app/page/signin_page.dart';
import 'package:inference_app/routing/stack.dart';

class MainRouterInformationParser
    extends RouteInformationParser<NavigationStack> {
  final WidgetRef ref;
  MainRouterInformationParser({required this.ref});

  @override
  Future<NavigationStack> parseRouteInformation(
      RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location!);

    final items = <MaterialPage>[];

    for (var i = 0; i < uri.pathSegments.length; i++) {
      var segment = uri.pathSegments[i];
      if (segment == "model") {
        var modelId = uri.pathSegments[i + 1];

        items.add(MaterialPage(
            key: ValueKey("ModelPage_$modelId"),
            child: ModelPage(
              modelId: modelId,
            )));
      } else if (segment == "profile") {
        var id = uri.pathSegments[i + 1];
        items.add(MaterialPage(
            key: ValueKey("ProfilePage_$id"),
            child: ProfilePage(
              profileId: id,
            )));
      } else if (segment == "run_model") {
        var id = uri.pathSegments[i + 1];
        items.add(MaterialPage(
            key: ValueKey("RunModelPage_$id"),
            child: ModelRunPage(
              modelId: id,
            )));
      } else if (segment == "run_list") {
        var id = uri.pathSegments[i + 1];
        items.add(MaterialPage(
            key: ValueKey("RunListPage_$id"),
            child: RunListPage(
              modelId: id,
            )));
      } else if (segment == "signin") {
        if (uri.queryParameters.containsKey('code')) {
          if (ref.read(meController.notifier).isLoggedIn()) {
          } else {
            String code = uri.queryParameters['code']!;
            items.add(MaterialPage(
                key: ValueKey("SignIn"),
                child: SignInPage(
                  code: code,
                )));
          }
        } else {
          items.add(MaterialPage(key: ValueKey("SignIn"), child: SignInPage()));
        }
      } else if (segment == "build_nbs") {
        items.add(
            MaterialPage(key: ValueKey("BuildNbsPage"), child: BuildNbsPage()));
      } else if (segment == "build_edit") {
        var modelId = uri.pathSegments[i + 1];
        items.add(MaterialPage(
            key: ValueKey("ModelEditPage"),
            child: ModelEditPage(
              modelId: modelId,
            )));
      } else if (segment == "build_start") {
        var buildId = uri.pathSegments[i + 1];
        items.add(MaterialPage(
            key: ValueKey("BuildStart_$buildId"),
            child: BuildStartPage(
              buildId: buildId,
            )));
      }
    }

    if (items.length == 0) {
      items.add(MaterialPage(key: ValueKey("HomePage"), child: HomePage()));
    }

    return NavigationStack(items, ref.read(meController.notifier));
  }

  @override
  RouteInformation restoreRouteInformation(NavigationStack configuration) {
    List<String> path = [];
    for (MaterialPage page in configuration.items) {
      if (page.child is HomePage) {
      } else if (page.child is ModelPage) {
        final modelPage = page.child as ModelPage;
        path.add('/model/${modelPage.modelId}');
      } else if (page.child is ProfilePage) {
        final profilePage = page.child as ProfilePage;
        path.add('/profile/${profilePage.profileId}');
      } else if (page.child is ModelRunPage) {
        final runModelPage = page.child as ModelRunPage;
        path.add('/run_model/${runModelPage.modelId}');
      } else if (page.child is RunListPage) {
        final runListPage = page.child as RunListPage;
        path.add('/run_list/${runListPage.modelId}');
      } else if (page.child is SignInPage) {
        final signInPage = page.child as SignInPage;
        if (signInPage.code != null) {
          path.add('/signin?code=${signInPage.code!}');
        } else {
          path.add('/signin');
        }
      } else if (page.child is BuildNbsPage) {
        path.add('/build_nbs/');
      } else if (page.child is ModelEditPage) {
        final buildEditPage = page.child as ModelEditPage;
        final modelId = buildEditPage.modelId;
        path.add('/model_edit/$modelId');
      } else if (page.child is BuildStartPage) {
        final modelInstallPage = page.child as BuildStartPage;
        final buildId = modelInstallPage.buildId;
        path.add('/build_start/$buildId');
      }
    }

    if (path.length == 0) {
      path.add("/");
    }
    return RouteInformation(location: path.join(""));
  }
}
