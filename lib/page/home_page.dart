import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inference_app/controller/providers.dart';
import 'package:inference_app/helpers/ui.dart';
import 'package:inference_app/main.dart';
import 'package:inference_app/models/model.dart';
import 'package:inference_app/page/model_page.dart';
import 'package:inference_app/page/profile_page.dart';
import 'package:inference_app/page/provider/model_provider.dart';
import 'package:inference_app/widgets/model_card_grid.dart';
import 'package:inference_app/widgets/my_app_bar.dart';
import 'package:inference_app/widgets/snack_bar.dart';

final provider = StateNotifierProvider.autoDispose<HomeModelNotifier,
    AsyncValue<List<Model>>>((ref) {
  return HomeModelNotifier(ref: ref);
});

class HomeModelNotifier extends StateNotifier<AsyncValue<List<Model>>> {
  final AutoDisposeProviderRefBase ref;
  List<Model>? _models;
  var mounted = true;

  HomeModelNotifier({required this.ref}) : super(AsyncLoading()); // {

  void fetchFeaturedModels() async {
    state = AsyncLoading();
    try {
      _models = await ref.read(apiProvider).fetchModelList();
      state = AsyncData(_models!);

      ref.listen<AsyncValue<Model>>(modelProvider, (wrapped) async {
        Model model = wrapped.data!.value;
        if (!mounted) return;
        if (model.status == ModelStatus.Deleted) {
          _models!.removeWhere((m) => m.id == model.id);
          state = AsyncData(_models!);
        } else {
          final index = _models!.indexWhere((m) => m.id == model.id);
          if (index > -1) {
            _models![index] = model;
            state = AsyncData(_models!);
          }
        }
      });
    } catch (e) {
      state = AsyncError(e);
    }
  }

  @override
  void dispose() {
    mounted = false;
    super.dispose();
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  _HomePageState();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(provider.notifier).fetchFeaturedModels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(provider);
    return Scaffold(
        appBar: myAppBar(context: context, ref: ref),
        body: Container(
            width: double.infinity,
            child: controller.when(
              data: (data) {
                return HomeScrollWidget(
                  models: data,
                  loading: false,
                  ref: ref,
                );
              },
              loading: () {
                List<Model> models = [
                  Model(
                      id: "",
                      githubUsername: "",
                      repository: "",
                      notebook: "",
                      userId: "",
                      status: ModelStatus.Public),
                  Model(
                      id: "",
                      githubUsername: "",
                      repository: "",
                      notebook: "",
                      userId: "",
                      status: ModelStatus.Public),
                ];
                return HomeScrollWidget(
                    models: models, loading: true, ref: ref);
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

class HomeScrollWidget extends StatelessWidget {
  final List<Model> models;
  final bool loading;
  final WidgetRef ref;
  const HomeScrollWidget(
      {Key? key,
      required this.models,
      required this.loading,
      required this.ref})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final columns = columnsForWidth(context: context);

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: HeroWidget(),
      ),
      if (loading) SliverToBoxAdapter(child: LinearProgressIndicator()),
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverToBoxAdapter(
          child: HeaderWidget(),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        sliver: ModelCardGrid(
          columns: columns,
          models: models,
          onModelPressed: ({required Model model}) {
            ref.read(navigationStackProvider).push(MaterialPage(
                key: ValueKey("ModelPage_${model.id}"),
                child: ModelPage(
                  modelId: model.id,
                )));
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
        ),
      )
    ]);
  }
}

class HeroWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image(
            image: AssetImage('image/hero.gif'),
            fit: BoxFit.cover,
            height: MediaQuery.of(context).size.height / 3.0,
            width: MediaQuery.of(context).size.width),
        Container(
          color: Colors.transparent,
          height: MediaQuery.of(context).size.height / 3.0,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "yhat.pub",
                style: Theme.of(context).textTheme.headline2,
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 8,
              ),
              Text(
                "Running your models with a few taps.",
                style: Theme.of(context).textTheme.headline4,
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Click to ",
                    style: Theme.of(context).textTheme.headline4,
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                      onPressed: () {},
                      child: Text(
                        "learn more",
                        style: Theme.of(context)
                            .textTheme
                            .headline4!
                            .copyWith(color: Colors.blue.shade700),
                      )),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HeaderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inference Featured Models',
              style: Theme.of(context).textTheme.headline3,
            ),
            SizedBox(
              height: 8,
            ),
            Text(
              'Some of the featured packages that represent Inference.codes models',
              style: Theme.of(context).textTheme.bodyText2,
            ),
          ],
        )
      ],
    );
  }
}
