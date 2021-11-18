import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:yhat_app/controller/providers.dart';
import 'package:yhat_app/models/model.dart';
import 'package:yhat_app/models/run.dart';
import 'package:yhat_app/models/signedUrl.dart';
import 'package:yhat_app/widgets/my_app_bar.dart';
import 'package:yhat_app/widgets/run_list.dart';
import 'package:uuid/uuid.dart';

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
  bool _hasNewResult = false;
  var mounted = true;

  void fetchModelAndRuns(
      {required String modelId, int offet = 0, int length = 0}) async {
    state = AsyncLoading();
    try {
      List responses = await Future.wait([
        read(apiProvider).fetchModel(modelId: modelId),
        read(apiProvider).fetchRunList(modelId: modelId)
      ]);

      _model = responses[0];
      _runs = responses[1];
      if (!mounted) return;
      state = AsyncData(ModelNotifierResponse(
        model: _model!,
        runs: _runs,
      ));
    } catch (e) {
      state = AsyncError(e);
    }
  }

  bool needSignedUrl() {
    bool found = false;

    Map<String, String>? inputJson = _model?.activeBuild?.inputJson;
    if (inputJson == null) {
      return false;
    }
    for (var value in inputJson.values) {
      if (value == "PIL" || value == "OpenCV") {
        found = true;
      }
    }

    return found;
  }

  void submitPredition(
      {required String modelId, required Map<String, dynamic> inputs}) async {
    state = AsyncLoading();
    try {
      String runId = Uuid().v1();
      if (needSignedUrl()) {
        List<SignedUrl> signedUrls = await read(apiProvider)
            .createSignedUrl(modelId: modelId, runId: runId);
        Map<String, String> inputJson = _model!.activeBuild!.inputJson!;

        for (var key in inputJson.keys) {
          String value = inputJson[key]!;
          if (value == "PIL" || value == "OpenCV") {
            SignedUrl signedUrl = signedUrls.removeAt(0);
            PlatformFile file = inputs[key];
            String s3Url = await read(apiProvider).createS3Asset(
                signedUrl: signedUrl, fileName: "uploaded", file: file);
            inputs[key] = s3Url;
          }
        }
      }

      Run run = await read(apiProvider)
          .submitPredition(modelId: modelId, inputs: inputs, runId: runId);
      _runs.add(run);
      if (!mounted) return;
      _hasNewResult = true;
      _model!.activeBuild!.lastRun = new DateTime.now();
      state = AsyncData(ModelNotifierResponse(model: _model!, runs: _runs));
    } catch (e, st) {
      state = AsyncError(e);
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
    }
  }

  bool hasNewResult() {
    if (_hasNewResult) {
      _hasNewResult = false;
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    mounted = false;
    super.dispose();
  }
}

class ModelRunPage extends ConsumerStatefulWidget {
  final String modelId;
  const ModelRunPage({
    Key? key,
    required this.modelId,
  }) : super(key: key);

  @override
  _ModelRunState createState() => _ModelRunState(modelId: modelId);
}

class _ModelRunState extends ConsumerState<ModelRunPage> {
  late TextEditingController _textEditingController;
  final String modelId;
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic> _inputs = {};
  bool _nextEnabled = false;
  bool _coldStart = false;

  _ModelRunState({required this.modelId});

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    Future.microtask(() {
      ref.read(provider.notifier).fetchModelAndRuns(modelId: modelId);
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToEnd() async {
    // if (ref.read(provider).data == null) {
    //   return;
    // }
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
  }

  void _reset() {
    _nextEnabled = false;
    _textEditingController.text = '';
    _inputs = {};
  }

  void _submitInputs(String key) async {
    Model? model = ref.read(provider.notifier)._model;
    if (model != null) {
      bool updateOk = await _updateInputs(key: key);
      if (updateOk == false) return;

      var earlier = DateTime.now().subtract(const Duration(minutes: 5));
      if (model.activeBuild?.lastRun == null ||
          model.activeBuild!.lastRun!.isBefore(earlier)) {
        setState(() {
          _coldStart = true;
        });
      }
      ref
          .read(provider.notifier)
          .submitPredition(modelId: modelId, inputs: _inputs);
    }
  }

  Future<bool> _updateInputs({required String key}) async {
    Model? model = ref.read(provider.notifier)._model;
    if (model != null) {
      final inputJson = model.activeBuild!.inputJson!;
      if (inputJson[key] == "Text") {
        _inputs[key] = _textEditingController.text;
      } else if (inputJson[key] == "PIL" || inputJson[key] == "OpenCV") {
        PlatformFile? platformFile = await _openFileExplorer();
        if (platformFile != null) {
          _inputs[key] = platformFile;
        } else {
          return false;
        }
      }
      setState(() {
        _textEditingController.text = '';
        _nextEnabled = false;
      });
    }
    return true;
  }

  Future<PlatformFile?> _openFileExplorer() async {
    List<PlatformFile>? _paths;
    try {
      _paths = (await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      ))
          ?.files;
    } catch (ex) {
      throw ex.toString();
    }
    return _paths?.first;
  }

  Widget _build(
      {required bool loading, required double calculatedButtonFontSize}) {
    Model? model = ref.read(provider.notifier)._model;
    List<Run> runs = ref.read(provider.notifier)._runs;
    List<Run> runsCopy = List.from(runs);

    if (ref.read(provider.notifier).hasNewResult()) {
      _reset();
    } else if (_inputs.length > 0) {
      runsCopy.add(Run(
          buildId: model!.activeBuildId!,
          outputJson: {},
          inputJson: _inputs,
          githubUsername: ref.read(meController).githubUsername ?? "anonymous",
          id: '',
          modelId: modelId,
          createdAt: DateTime.now()));
    }

    return Column(
      children: [
        if (loading) LinearProgressIndicator(),
        if (loading) _buildColdStart(),
        Expanded(
          child: Container(
            child: CustomScrollView(controller: _scrollController, slivers: [
              SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: RunList(
                    model: model,
                    runs: runsCopy,
                    showAllRuns: false,
                  ))
            ]),
          ),
        ),
        Container(
            margin: EdgeInsets.all(8),
            height: 50,
            color: Colors.white,
            child: _buildInput(
                context: context,
                calculatedButtonFontSize: calculatedButtonFontSize))
      ],
    );
  }

  Widget _buildInput(
      {required BuildContext context,
      required double calculatedButtonFontSize}) {
    Model? model = ref.read(provider.notifier)._model;
    var screenWidth = MediaQuery.of(context).size.width;

    if (model?.activeBuild?.inputJson == null) {
      return Container();
    }
    final inputJson = model!.activeBuild!.inputJson!;
    int stepCt = 0;
    for (var key in inputJson.keys) {
      stepCt += 1;
      if (!_inputs.containsKey(key)) {
        bool isLast = inputJson.keys.toList().lastIndexOf(key) ==
            (inputJson.keys.length - 1);

        if (inputJson[key] == "Text") {
          Function()? nextButtonSubmit = _nextEnabled
              ? isLast
                  ? () => _submitInputs(key)
                  : () => _updateInputs(key: key)
              : null;

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onSubmitted: nextButtonSubmit != null
                          ? (_) {
                              nextButtonSubmit();
                            }
                          : null,
                      decoration: InputDecoration(
                        hintText: 'Step $stepCt: Enter ($key)',
                        contentPadding: EdgeInsets.fromLTRB(6, 0, 0, 0),
                      ),
                      controller: _textEditingController,
                      onChanged: (value) {
                        if (value.length > 0) {
                          setState(() {
                            _nextEnabled = true;
                          });
                        } else {
                          setState(() {
                            _nextEnabled = false;
                          });
                        }
                      },
                    ),
                  ),
                  ElevatedButton(
                      onPressed: nextButtonSubmit,
                      style: _nextEnabled
                          ? Theme.of(context).elevatedButtonTheme.style
                          : ElevatedButton.styleFrom(
                              primary: Colors.grey.shade400),
                      child: SizedBox(
                        width: 160,
                        height: 50,
                        child: Center(
                          child: Text(isLast ? "Submit" : "Next",
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5!
                                  .copyWith(
                                      color: Colors.white,
                                      fontSize: calculatedButtonFontSize)),
                        ),
                      ))
                ],
              ),
            ],
          );
        } else if (inputJson[key] == "PIL" || inputJson[key] == "OpenCV") {
          Function()? nextButtonSubmit =
              isLast ? () => _submitInputs(key) : () => _updateInputs(key: key);

          return Center(
            child: ElevatedButton(
                onPressed: nextButtonSubmit,
                style: Theme.of(context).elevatedButtonTheme.style,
                child: SizedBox(
                  width: screenWidth * 0.5 > 240 ? screenWidth * 0.5 : 240,
                  height: 40,
                  child: Center(
                    child: Text("Step $stepCt: Select Image",
                        style: Theme.of(context).textTheme.headline5!.copyWith(
                            color: Colors.white,
                            fontSize: calculatedButtonFontSize)),
                  ),
                )),
          );
        }
      }
    }
    return Container();
  }

  Widget _buildColdStart() {
    if (_coldStart == true) {
      _coldStart = false;

      return Container(
          height: 40,
          color: Colors.blue.shade800,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                    "COLD START DETECTED, PLEASE WAIT 60 SECONDS FOR WARMUP",
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1!
                        .copyWith(color: Colors.white)),
              )
            ],
          ));
    }

    return Container();
  }

  Widget build(BuildContext context) {
    RunModelNotifier _modelNotifier = ref.read(provider.notifier);
    AsyncValue<ModelNotifierResponse> _modelState = ref.watch(provider);

    var screenWidth = MediaQuery.of(context).size.width;
    double calculatedButtonFontSize =
        (20 * screenWidth / 600) > 20 ? 20 : 20 * screenWidth / 800;

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
                return _build(
                    loading: false,
                    calculatedButtonFontSize: calculatedButtonFontSize);
              },
              loading: () {
                return _build(
                    loading: true,
                    calculatedButtonFontSize: calculatedButtonFontSize);
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
