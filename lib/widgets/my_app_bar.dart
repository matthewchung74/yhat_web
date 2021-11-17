import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yhat_app/controller/providers.dart';
import 'package:yhat_app/helpers/ui.dart';
import 'package:yhat_app/page/profile_page.dart';
import 'package:yhat_app/page/signin_page.dart';
// import 'package:uuid/uuid.dart';

import '../main.dart';

AppBar myAppBar(
    {required BuildContext context,
    required WidgetRef ref,
    String? title,
    bool showRightAction = true}) {
  final notifier = ref.read(meController.notifier);
  final controller = ref.read(meController);
  var screenWidth = MediaQuery.of(context).size.width;

  Widget rightAction() {
    if (showRightAction == false) return Container();

    if (!notifier.isLoggedIn()) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 6),
        child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            onPressed: () {
              ref.read(navigationStackProvider).push(MaterialPage(
                  name: "SignInPage",
                  key: ValueKey("SignIn"),
                  child: SignInPage()));
            },
            child: Text(
              "Sign In",
              style: Theme.of(context).textTheme.headline5,
            )),
      );
    }
    MaterialPage lastPage = ref.read(navigationStackProvider).items.last;
    String userId = ref.read(meController).id!;
    if (lastPage.child is ProfilePage &&
        (lastPage.child as ProfilePage).profileId == userId) {
      return TextButton(
          child: Text(
            "Sign Out",
            style: Theme.of(context).textTheme.headline5,
          ),
          onPressed: () {
            ref.read(meController.notifier).logout();
            ref.read(navigationStackProvider).popToRoot();
          });
    }
    if (controller.avatarUrl == null) {
      var username = controller.githubUsername != null
          ? controller.githubUsername!
          : "Profile";

      return TextButton(
          child: Text(
            username,
            style: Theme.of(context).textTheme.headline5,
          ),
          onPressed: () {
            ref.read(navigationStackProvider).push(MaterialPage(
                name: "ProfilePage",
                child: ProfilePage(
                  profileId: controller.id!,
                )));
          });
    } else {
      return TextButton(
          child: CircleAvatar(
              backgroundImage: NetworkImage(controller.avatarUrl!)),
          onPressed: () {
            ref.read(navigationStackProvider).push(MaterialPage(
                name: "ProfilePage",
                child: ProfilePage(
                  profileId: controller.id!,
                )));
          });
    }
  }

  TextStyle? titleStyle;
  if (screenWidth > 540) {
    titleStyle = Theme.of(context).textTheme.headline5!.copyWith(fontSize: 20);
  } else {
    titleStyle = Theme.of(context).textTheme.headline5!;
  }
  return AppBar(
    centerTitle: true,
    title: TextButton(
      onPressed: () {
        if (title == null) {
          ref.read(navigationStackProvider).popToRoot();
        } else {
          ref.read(navigationStackProvider).pop();
        }
      },
      child: Text(
        title != null ? title : "YHat.pub",
        style: titleStyle,
        overflow: TextOverflow.clip,
        maxLines: 1,
      ),
    ),
    elevation: 0,
    actions: [
      if (screenWidth > 540)
        IconButton(
          color: Colors.grey.shade300,
          icon: const Icon(Icons.help_outline_outlined),
          onPressed: () async {
            await launchURLBrowser(url: "https://github.com/yhatpub/yhatpub");
          },
        ),
      SizedBox(
        width: 8,
      ),
      if (showRightAction) rightAction(),
      if (showRightAction)
        SizedBox(
          width: 12,
        )
    ],
  );
}
