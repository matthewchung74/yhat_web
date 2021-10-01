import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yhat_app/controller/providers.dart';
import 'package:yhat_app/models/model.dart';
import 'package:yhat_app/models/run.dart';
import 'package:yhat_app/widgets/my_app_bar.dart';
import 'package:yhat_app/widgets/run_list.dart';

import 'package:yhat_app/widgets/snack_bar.dart';

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

final provider = StateNotifierProvider.autoDispose<RunModelNotifier,
    AsyncValue<ModelNotifierResponse>>((ref) {
  return RunModelNotifier(read: ref.read);
});

class RunModelNotifier
    extends StateNotifier<AsyncValue<ModelNotifierResponse>> {
  RunModelNotifier({required this.read}) : super(AsyncLoading());

  final Reader read;
  Model? _model;
  List<Run> _runs = [];
  var mounted = true;

  void fetchModelAndRuns(
      {required String modelId, int offet = 0, int length = 0}) async {
    state = AsyncLoading();
    try {
      _model = await read(apiProvider).fetchModel(modelId: modelId);
      _runs = await read(apiProvider).fetchRunList(modelId: modelId);

      if (!mounted) return;
      state = AsyncData(ModelNotifierResponse(
        model: _model!,
        runs: _runs,
      ));
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

class RunListPage extends ConsumerStatefulWidget {
  final String modelId;
  const RunListPage({
    Key? key,
    required this.modelId,
  }) : super(key: key);

  @override
  _ModelRunState createState() => _ModelRunState(modelId: modelId);
}

class _ModelRunState extends ConsumerState<RunListPage> {
  late TextEditingController _textEditingController;
  final String modelId;
  final ScrollController _scrollController = ScrollController();

  _ModelRunState({required this.modelId});

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    ref.read(provider.notifier).fetchModelAndRuns(modelId: modelId);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToEnd() async {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
  }

  Widget _build({required bool loading}) {
    Model? model = ref.read(provider.notifier)._model;
    List<Run> runs = ref.read(provider.notifier)._runs;

    return Column(
      children: [
        if (loading) LinearProgressIndicator(),
        Expanded(
          child: Container(
            child: CustomScrollView(controller: _scrollController, slivers: [
              SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: RunList(
                    model: model,
                    runs: runs,
                    showAllRuns: false,
                  ))
            ]),
          ),
        ),
      ],
    );
  }

  Widget build(BuildContext context) {
    RunModelNotifier _modelNotifier = ref.read(provider.notifier);
    AsyncValue<ModelNotifierResponse> _modelState = ref.watch(provider);

    if (WidgetsBinding.instance != null) {
      WidgetsBinding.instance!.addPostFrameCallback((_) => _scrollToEnd());
    }

    return Scaffold(
        appBar: myAppBar(
            context: context,
            ref: ref,
            title: _modelNotifier._model?.prettyNotebookName),
        body: Container(
            width: double.infinity,
            child: _modelState.when(
              data: (data) {
                return _build(loading: false);
              },
              loading: () {
                return _build(loading: true);
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
