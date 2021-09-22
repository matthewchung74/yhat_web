import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inference_app/models/model.dart';
import 'package:inference_app/controller/providers.dart';
import 'package:inference_app/helpers/ui.dart';
import 'package:inference_app/main.dart';
import 'package:inference_app/models/user.dart';
import 'package:inference_app/page/build_nbs_page.dart';
import 'package:inference_app/widgets/model_card_grid.dart';
import 'package:inference_app/widgets/my_app_bar.dart';
import 'package:inference_app/widgets/snack_bar.dart';

import 'model_page.dart';

class ProfilePageResponse extends Equatable {
  ProfilePageResponse({
    required this.models,
    required this.user,
  });

  final List<Model> models;
  final User user;

  @override
  List<Object> get props => [models, user];
}

final provider = StateNotifierProvider.autoDispose<ProfileNotifier,
    AsyncValue<ProfilePageResponse>>((ref) {
  return ProfileNotifier(read: ref.read);
});

class ProfileNotifier extends StateNotifier<AsyncValue<ProfilePageResponse>> {
  ProfileNotifier({required this.read}) : super(AsyncLoading());

  final Reader read;
  void fetchModel({required String profileId}) async {
    state = AsyncLoading();
    try {
      List responses = await Future.wait([
        if (read(meController).id == profileId)
          read(apiProvider).fetchModelList(userId: profileId, mine: true),
        if (read(meController).id != profileId)
          read(apiProvider).fetchModelList(userId: profileId),
        if (read(meController).id == profileId) read(apiProvider).fetchMe(),
        if (read(meController).id != profileId)
          read(apiProvider).fetchUser(userId: profileId),
      ]);
      ProfilePageResponse profileResponse =
          ProfilePageResponse(models: responses[0], user: responses[1]);
      if (!mounted) return;
      state = AsyncData(profileResponse);
    } catch (e) {
      state = AsyncError(e);
    }
  }
}

class ProfilePage extends ConsumerStatefulWidget {
  final String profileId;

  ProfilePage({Key? key, required this.profileId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState(profileId: profileId);
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final String profileId;

  _ProfilePageState({required this.profileId});

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(provider.notifier).fetchModel(profileId: profileId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(provider);
    final isMe = ref.read(meController).id == profileId ? true : false;
    return Scaffold(
        appBar: myAppBar(context: context, ref: ref),
        body: Container(
            width: double.infinity,
            child: controller.when(
              data: (data) {
                return ProfileScrollWidget(
                  user: data.user,
                  models: data.models,
                  isMe: isMe,
                );
              },
              loading: () {
                return CustomScrollView(slivers: [
                  SliverToBoxAdapter(child: LinearProgressIndicator()),
                ]);
              },
              error: (error, st) {
                return SnackBarWidget(
                  snackBarStatus: SnackBarStatus.Alert,
                  message: error.toString(),
                );
              },
            )));
  }
}

class ProfileScrollWidget extends StatelessWidget {
  final User user;
  final List<Model> models;
  final bool isMe;

  const ProfileScrollWidget(
      {Key? key, required this.user, required this.models, required this.isMe})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [
      SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver:
              SliverToBoxAdapter(child: HeaderWidget(user: user, isMe: isMe))),
      SliverToBoxAdapter(child: Divider()),
      SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: BodyWidget(
            models: models,
          )),
    ]);
  }
}

class HeaderWidget extends ConsumerWidget {
  final User user;
  final bool isMe;

  const HeaderWidget({Key? key, required this.user, required this.isMe})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var screenWidth = MediaQuery.of(context).size.width;
    double calculatedTitleFontSize =
        (32 * screenWidth / 800) > 32 ? 32 : (32 * screenWidth / 800);
    double calculatedButtonFontSize =
        (20 * screenWidth / 600) > 20 ? 20 : 20 * screenWidth / 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 2,
              child: Text(
                user.githubUsername!,
                style: Theme.of(context)
                    .textTheme
                    .headline3!
                    .copyWith(fontSize: calculatedTitleFontSize),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isMe)
              Flexible(
                  flex: 1,
                  child: ElevatedButton(
                      onPressed: () {
                        ref.read(navigationStackProvider).push(MaterialPage(
                            key: ValueKey("BuildNbsPage"),
                            child: BuildNbsPage()));
                      },
                      style: Theme.of(context).elevatedButtonTheme.style,
                      child: SizedBox(
                        width: 220,
                        height: 40,
                        child: Center(
                          child: Text("Upload Model",
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5!
                                  .copyWith(
                                      color: Colors.white,
                                      fontSize: calculatedButtonFontSize)),
                        ),
                      ))),
          ],
        ),
        Row(
          children: [
            Text(
              "GITHUB: ",
              style: Theme.of(context)
                  .textTheme
                  .bodyText2!
                  .copyWith(color: Colors.grey.shade600),
            ),
            TextButton(
                onPressed: () async {
                  await launchURLBrowser(url: user.htmlUrl!);
                },
                style: Theme.of(context).textButtonTheme.style,
                child: SizedBox(
                  width: screenWidth * 0.7,
                  child: Text(
                    user.htmlUrl!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1!
                        .copyWith(color: Colors.blue.shade700),
                  ),
                )),
          ],
        ),
      ],
    );
  }
}

class BodyWidget extends StatelessWidget {
  final List<Model> models;

  const BodyWidget({Key? key, required this.models}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final columns = columnsForWidth(context: context);
    return Consumer(builder: (context, ref, _) {
      return ModelCardGrid(
        columns: columns,
        models: models,
        onModelPressed: ({required Model model}) {
          ref.read(navigationStackProvider).push(MaterialPage(
              key: ValueKey("ModelPage_${model.id}"),
              child: ModelPage(
                modelId: model.id,
              )));

          return Container();
        },
        onProfilePressed: ({required Model model}) {
          ref.read(navigationStackProvider).push(MaterialPage(
              key: ValueKey("ProfilePage_${model.userId}"),
              child: ProfilePage(
                profileId: model.userId,
              )));
        },
        onGithubPressed: ({required Model model}) async {
          await launchURLBrowser(url: model.homepage);
        },
      );
    });
  }
}
