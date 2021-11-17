import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yhat_app/api/api.dart';
import 'package:yhat_app/controller/providers.dart';
import 'package:yhat_app/helpers/ui.dart';
import 'package:yhat_app/models/model.dart';
import 'package:yhat_app/models/run.dart';
import 'package:yhat_app/page/build_start_page.dart';
import 'package:yhat_app/page/model_run_page.dart';
import 'package:yhat_app/page/profile_page.dart';
import 'package:yhat_app/page/provider/model_provider.dart';
import 'package:yhat_app/widgets/my_app_bar.dart';
import 'package:yhat_app/widgets/run_list.dart';
import 'package:yhat_app/widgets/snack_bar.dart';

import '../main.dart';
import 'model_edit_page.dart';

class ModelNotifierResponse extends Equatable {
  ModelNotifierResponse({
    required this.model,
    required this.runs,
  });
  final Model model;
  final List<Run> runs;

  @override
  List<Object> get props {
    return [model, runs];
  }
}

final provider = StateNotifierProvider.autoDispose<ModelNotifier,
    AsyncValue<ModelNotifierResponse>>((ref) {
  return ModelNotifier(ref: ref);
});

class ModelNotifier extends StateNotifier<AsyncValue<ModelNotifierResponse>> {
  final AutoDisposeProviderRefBase ref;
  var mounted = true;
  List<Run>? _runList;
  ModelNotifier({required this.ref}) : super(AsyncLoading());

  void fetchModel({required String modelId}) async {
    state = AsyncLoading();
    try {
      ref.listen<AsyncValue<Model>>(modelProvider, (wrapped) async {
        // debugger();
        if (!mounted) return;
        Model model = wrapped.data!.value;
        if (model.status == ModelStatus.Deleted) {
          return;
        } else if (_runList == null) {
          _runList = await ref.read(apiProvider).fetchRunList(modelId: modelId);
        }
        if (!mounted) return;
        state = AsyncData(ModelNotifierResponse(model: model, runs: _runList!));
      });
      ref.read(modelProvider.notifier).fetchModel(modelId: modelId);
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

class ModelPage extends ConsumerStatefulWidget {
  final String modelId;

  const ModelPage({Key? key, required this.modelId}) : super(key: key);

  @override
  _ModelPageState createState() => _ModelPageState(modelId: modelId);
}

class _ModelPageState extends ConsumerState<ModelPage>
    with WidgetsBindingObserver {
  final String modelId;
  _ModelPageState({required this.modelId});

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(provider.notifier).fetchModel(modelId: modelId);
    });
  }

  Function()? buildPressed({required Model model}) {
    ref.read(navigationStackProvider).push(MaterialPage(
        name: "BuildStartPage",
        child: BuildStartPage(
          buildId: model.activeBuildId!,
        )));
  }

  Widget _buildLastRunInfo(
      {required BuildContext context, required Model model}) {
    if (model.activeBuild?.lastRun != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 16,
          ),
          Text(
            "LAST RUN: ",
            style: Theme.of(context)
                .textTheme
                .bodyText2!
                .copyWith(color: Colors.grey.shade600),
          ),
          SizedBox(
            height: 4,
          ),
          Text(formattedDate(model.activeBuild!.lastRun!),
              style: Theme.of(context).textTheme.bodyText2!),
          SizedBox(
            height: 20,
          ),
        ],
      );
    }
    return Container();
  }

  _buildPageInfo({required BuildContext context, required Model model}) {
    String? description = model.description;
    String? releaseNotes = model.activeBuild?.releaseNotes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text("INFO",
                  style: Theme.of(context)
                      .textTheme
                      .headline5!
                      .copyWith(color: Color.fromRGBO(26, 36, 54, 1))),
            ),
            SizedBox(
              height: 24,
            ),
            if (model.activeBuild?.releaseNotes != null)
              Text(
                "RELEASE NOTES: ",
                style: Theme.of(context)
                    .textTheme
                    .bodyText2!
                    .copyWith(color: Colors.grey.shade600),
              ),
            if (model.activeBuild?.releaseNotes != null)
              SizedBox(
                height: 4,
              ),
            if (model.activeBuild?.releaseNotes != null)
              Text(model.activeBuild!.releaseNotes!,
                  style: Theme.of(context).textTheme.bodyText2!),
            if (model.activeBuild?.releaseNotes != null)
              SizedBox(
                height: 20,
              ),
            if (description != null && description != '')
              Text(
                "DESCRIPTION: ",
                style: Theme.of(context)
                    .textTheme
                    .bodyText2!
                    .copyWith(color: Colors.grey.shade600),
              ),
            if (description != null)
              SizedBox(
                height: 4,
              ),
            if (description != null)
              SelectableText("$description",
                  style: Theme.of(context).textTheme.bodyText2!),
            if (description != null)
              SizedBox(
                height: 20,
              ),
            if (releaseNotes != null && releaseNotes != '')
              Text(
                "RELEASE NOTES: ",
                style: Theme.of(context)
                    .textTheme
                    .bodyText2!
                    .copyWith(color: Colors.grey.shade600),
              ),
            if (releaseNotes != null)
              SizedBox(
                height: 4,
              ),
            if (releaseNotes != null)
              SelectableText("$releaseNotes",
                  style: Theme.of(context).textTheme.bodyText2!),
            if (releaseNotes != null)
              SizedBox(
                height: 20,
              ),
            Text(
              "MODEL INPUTS: ",
              style: Theme.of(context)
                  .textTheme
                  .bodyText2!
                  .copyWith(color: Colors.grey.shade600),
            ),
            SizedBox(
              height: 4,
            ),
            SelectableText("${model.activeBuild!.inputJson}"),
            // ...model.activeBuild!.inputJson!.keys.toList().map((e) {
            //   return Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       SelectableText("Input Name: $e",
            //           style: Theme.of(context).textTheme.bodyText2!),
            //       SizedBox(
            //         height: 4,
            //       ),
            //       SelectableText(
            //           "Input Type: ${model.activeBuild!.inputJson![e]}",
            //           style: Theme.of(context).textTheme.bodyText2!),
            //     ],
            //   );
            // }),
            SizedBox(
              height: 20,
            ),
            SelectableText(
              "MODEL OUTPUTS: ",
              style: Theme.of(context)
                  .textTheme
                  .bodyText2!
                  .copyWith(color: Colors.grey.shade600),
            ),
            SizedBox(
              height: 4,
            ),
            SelectableText("${model.activeBuild!.outputJson}"),

            // ...model.activeBuild!.outputJson!.keys.toList().map((e) {
            //   return Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       SizedBox(
            //         height: 4,
            //       ),
            //       Text("Output Type: ${model.activeBuild!.outputJson![e]}",
            //           style: Theme.of(context).textTheme.bodyText2!),
            //     ],
            //   );
            // }),
            SizedBox(
              height: 16,
            ),
            Row(
              children: [
                SelectableText(
                  "BUILDS: ",
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2!
                      .copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
            SizedBox(
              height: 16,
            ),
            _buildLastRunInfo(context: context, model: model),
          ],
        )
      ],
    );
  }

  Widget _buildHeader(
      {required BuildContext context,
      required Model model,
      required bool isMine}) {
    var screenWidth = MediaQuery.of(context).size.width;
    double calculatedTitleFontSize =
        (32 * screenWidth / 800) > 32 ? 32 : (32 * screenWidth / 800);
    double calculatedButtonFontSize =
        (20 * screenWidth / 600) > 20 ? 20 : 20 * screenWidth / 600;

    Function()? _buildPressed = isMine
        ? () {
            buildPressed(model: model);
          }
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 2,
                  child: Text(
                    model.title != null && model.title != ""
                        ? model.title!
                        : model.prettyNotebookName,
                    style: Theme.of(context)
                        .textTheme
                        .headline3!
                        .copyWith(fontSize: calculatedTitleFontSize),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Consumer(builder: (context, ref, _) {
                    return ElevatedButton(
                        onPressed: () {
                          ref.read(navigationStackProvider).push(MaterialPage(
                              name: "ModelRunPage",
                              child: ModelRunPage(
                                modelId: model.id,
                              )));
                        },
                        style: Theme.of(context).elevatedButtonTheme.style,
                        child: SizedBox(
                          width: 160,
                          height: 40,
                          child: Center(
                            child: Text("Run Model",
                                style: Theme.of(context)
                                    .textTheme
                                    .headline5!
                                    .copyWith(
                                        color: Colors.white,
                                        fontSize: calculatedButtonFontSize)),
                          ),
                        ));
                  }),
                )
              ],
            ),
            SizedBox(
              height: 8,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "BUILD ID: ",
                        style: Theme.of(context)
                            .textTheme
                            .bodyText2!
                            .copyWith(color: Colors.grey.shade600),
                      ),
                      Consumer(builder: (context, ref, _) {
                        return TextButton(
                          onPressed: _buildPressed,
                          style: Theme.of(context)
                              .textButtonTheme
                              .style!
                              .copyWith(alignment: Alignment.centerLeft),
                          child: Text(
                            model.activeBuildId!.split("-")[0],
                            style: isMine
                                ? Theme.of(context)
                                    .textTheme
                                    .bodyText1!
                                    .copyWith(color: Colors.blue.shade700)
                                : Theme.of(context)
                                    .textTheme
                                    .bodyText1!
                                    .copyWith(color: Colors.grey.shade600),
                          ),
                        );
                      })
                    ],
                  ),
                ),
                if (isMine)
                  Flexible(
                    flex: 1,
                    child: Consumer(builder: (context, ref, _) {
                      return ElevatedButton(
                          onPressed: () async {
                            ref.read(navigationStackProvider).push(MaterialPage(
                                name: "ModelEditPage",
                                child: ModelEditPage(modelId: modelId)));
                          },
                          style: Theme.of(context)
                              .elevatedButtonTheme
                              .style!
                              .copyWith(
                                  backgroundColor:
                                      MaterialStateProperty.resolveWith(
                                          (states) => Colors.green)),
                          child: SizedBox(
                            width: 160,
                            height: 40,
                            child: Center(
                              child: Text("Edit Model",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline5!
                                      .copyWith(
                                          color: Colors.white,
                                          fontSize: calculatedButtonFontSize)),
                            ),
                          ));
                    }),
                  )
              ],
            ),
            SizedBox(
              height: 8,
            ),
            Row(
              children: [
                Text(
                  "CREATED BY: ",
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2!
                      .copyWith(color: Colors.grey.shade600),
                ),
                Consumer(builder: (context, ref, _) {
                  return TextButton(
                      onPressed: () {
                        ref.read(navigationStackProvider).push(MaterialPage(
                            name: "ProfilePage",
                            child: ProfilePage(
                              profileId: model.user!.id!,
                            )));
                      },
                      style: Theme.of(context).textButtonTheme.style,
                      child: Text(
                        model.user != null ? model.user!.githubUsername! : '',
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1!
                            .copyWith(color: Colors.blue.shade700),
                      ));
                })
              ],
            ),
            FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    "PREDICT SCRIPT: ",
                    style: Theme.of(context)
                        .textTheme
                        .bodyText2!
                        .copyWith(color: Colors.grey.shade600),
                  ),
                  TextButton(
                      onPressed: () async {
                        await launchURLBrowser(url: model.homepage);
                      },
                      style: Theme.of(context)
                          .textButtonTheme
                          .style!
                          .copyWith(alignment: Alignment.centerLeft),
                      child: Row(
                        children: [
                          Text(
                            model.user != null
                                ? model.user!.githubUsername!
                                : '',
                            // model.homepage,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1!
                                .copyWith(color: Colors.blue.shade700),
                          ),
                        ],
                      )),
                ],
              ),
            ),
            if (model.credits != null)
              FittedBox(
                fit: BoxFit.cover,
                child: Row(
                  children: [
                    Text(
                      "MODEL CREDITS: ",
                      style: Theme.of(context)
                          .textTheme
                          .bodyText2!
                          .copyWith(color: Colors.grey.shade600),
                    ),
                    TextButton(
                        onPressed: () async {
                          await launchURLBrowser(url: model.credits!);
                        },
                        style: Theme.of(context)
                            .textButtonTheme
                            .style!
                            .copyWith(alignment: Alignment.centerLeft),
                        child: Row(
                          children: [
                            Text(
                              model.prettyCreditUsername ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1!
                                  .copyWith(color: Colors.blue.shade700),
                            ),
                          ],
                        )),
                  ],
                ),
              ),
          ],
        )
      ],
    );
  }

  Widget _build(
      {required BuildContext context,
      required bool loading,
      required Model model,
      required List<Run> runs}) {
    final isMine = ref.read(meController).id == model.userId ? true : false;

    return CustomScrollView(slivers: [
      if (loading) SliverToBoxAdapter(child: LinearProgressIndicator()),
      SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
              child: _buildHeader(
            context: context,
            model: model,
            isMine: isMine,
          ))),
      SliverToBoxAdapter(child: Divider()),
      SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: _buildPageInfo(context: context, model: model),
          )),
      SliverToBoxAdapter(child: Divider()),
      SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: RunList(
              model: model,
              runs: runs,
              showAllRuns: runs.length > 0 ? true : false)),
    ]);
  }

  Widget build(BuildContext context) {
    AsyncValue<ModelNotifierResponse> _modelState = ref.watch(provider);

    return Scaffold(
        appBar: myAppBar(context: context, ref: ref),
        body: Container(
            width: double.infinity,
            child: _modelState.when(
              data: (data) {
                // final isMine = ref.read(meController).id == data.model.userId
                //     ? true
                //     : false;
                return _build(
                    context: context,
                    loading: false,
                    model: data.model,
                    runs: data.runs);
                // return ModelPageScrollWidget(
                //   model: data.model,
                //   runs: data.runs,
                //   isMine: isMine,
                //   loading: false,
                // );
              },
              loading: () {
                return CustomScrollView(slivers: [
                  SliverToBoxAdapter(child: LinearProgressIndicator()),
                ]);
              },
              error: (error, st) {
                debugger();
                return SnackBarWidget(
                  snackBarStatus: SnackBarStatus.Alert,
                  message: error.toString(),
                );
              },
            )));
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }
}
