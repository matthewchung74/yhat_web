import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yhat_app/main.dart';
import 'package:yhat_app/models/model.dart';
import 'package:yhat_app/page/provider/model_provider.dart';
import 'package:yhat_app/widgets/my_app_bar.dart';
import 'package:yhat_app/widgets/snack_bar.dart';

enum ModelEditState { NotStarted, Editing, Finished, Deleted }

class ModelEditResponse extends Equatable {
  final Model model;
  final ModelEditState modelEditState;
  ModelEditResponse({
    required this.model,
    required this.modelEditState,
  });

  @override
  List<Object> get props {
    return [];
  }
}

class ModelEditNotifier extends StateNotifier<AsyncValue<ModelEditResponse>> {
  ModelEditNotifier({required this.ref}) : super(AsyncLoading());

  final AutoDisposeProviderRefBase ref;
  late Model _model;
  var mounted = true;

  DateTime? _updatedAt;
  Future<void> fetchModel({required String modelId}) async {
    state = AsyncLoading();

    try {
      ref.listen<AsyncValue<Model>>(modelProvider, (wrapped) async {
        Model? model = wrapped.data?.value;
        if (!mounted) return;

        if (model != null) {
          _model = model;
          ModelEditState modelEditState = ModelEditState.NotStarted;
          if (_model.status == ModelStatus.Deleted) {
            modelEditState = ModelEditState.Deleted;
          } else if (_model.updatedAt != null && _updatedAt != null) {
            if (_model.updatedAt!.isAfter(_updatedAt!)) {
              modelEditState = ModelEditState.Finished;
            }
          }
          _updatedAt = _model.updatedAt;

          state = AsyncData(
              ModelEditResponse(model: _model, modelEditState: modelEditState));
        }
      });
      ref.read(modelProvider.notifier).fetchModel(modelId: modelId);
    } catch (e) {
      state = AsyncError(e);
    }
  }

  void update(
      {String? title,
      String? description,
      String? credits,
      String? releaseNotes}) async {
    state = AsyncLoading();
    try {
      ref.read(modelProvider.notifier).update(
          modelId: _model.id,
          title: title,
          credits: credits,
          description: description,
          releaseNotes: releaseNotes);

      ref.read(navigationStackProvider).pop();
    } catch (e) {
      state = AsyncError(e);
    }
  }

  void delete(
      {String? title, String? description, String? releaseNotes}) async {
    state = AsyncLoading();
    try {
      ref.read(modelProvider.notifier).delete(
            modelId: _model.id,
          );
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

final provider = StateNotifierProvider.autoDispose<ModelEditNotifier,
    AsyncValue<ModelEditResponse>>((ref) {
  return ModelEditNotifier(ref: ref);
});

bool _isUrlValid(String url) {
  return Uri.parse(url).host == '' ? false : true;
}

class ModelEditPage extends ConsumerStatefulWidget {
  final String modelId;
  const ModelEditPage({required this.modelId});
  @override
  _ModelEditPage createState() => _ModelEditPage(modelId: modelId);
}

class _ModelEditPage extends ConsumerState<ModelEditPage> {
  final String modelId;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _creditsController;
  late TextEditingController _releaseNotesController;
  bool _startedEditing = false;

  _ModelEditPage({required this.modelId});

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _creditsController = TextEditingController();
    _releaseNotesController = TextEditingController();
    Future.microtask(() {
      ref.read(provider.notifier).fetchModel(modelId: modelId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(provider.notifier);

    final _modelProvider = ref.watch(provider);
    var screenWidth = MediaQuery.of(context).size.width;
    double calculatedButtonFontSize =
        (20 * screenWidth / 600) > 20 ? 20 : 20 * screenWidth / 800;

    return Scaffold(
        appBar: myAppBar(context: context, ref: ref),
        body: Container(
            width: double.infinity,
            child: _modelProvider.when(data: (data) {
              if (data.modelEditState == ModelEditState.Finished) {
                Future.microtask(() {
                  ref.read(navigationStackProvider).pop();
                });
              } else if (data.modelEditState == ModelEditState.Deleted) {
                Future.microtask(() {
                  ref.read(navigationStackProvider).popToRoot();
                });
              }

              if (_startedEditing == false &&
                  _titleController.text == "" &&
                  _descriptionController.text == "" &&
                  _creditsController.text == "" &&
                  _releaseNotesController.text == "") {
                _titleController.text = data.model.title ?? '';
                _descriptionController.text = data.model.description ?? '';
                _creditsController.text = data.model.credits ?? '';
                _releaseNotesController.text =
                    data.model.activeBuild?.releaseNotes ?? '';
              }

              _startedEditing = true;
              bool _enabled = false;
              if (_titleController.text != (data.model.title ?? '') ||
                  _descriptionController.text !=
                      (data.model.description ?? '') ||
                  _releaseNotesController.text !=
                      (data.model.activeBuild?.releaseNotes ?? '')) {
                _enabled = true;
              }

              if ((_creditsController.text != '' &&
                      _creditsController.text != (data.model.credits ?? '')) &&
                  _isUrlValid(_creditsController.text)) {
                _enabled = true;
              }

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 26,
                          ),
                          Text(
                            "Model Title",
                            style: Theme.of(context).textTheme.bodyText2,
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          TextField(
                            controller: _titleController,
                            onChanged: (text) {
                              setState(() {
                                _titleController.value = TextEditingValue(
                                    text: text,
                                    selection: TextSelection(
                                        baseOffset: text.length,
                                        extentOffset: text.length));
                              });
                            },
                            decoration: new InputDecoration(
                              hintText:
                                  'Default is be notebook file name (optional)',
                            ),
                            keyboardType: TextInputType.multiline,
                            minLines: 1,
                            maxLines: 1,
                          ),
                          SizedBox(
                            height: 26,
                          ),
                          Text(
                            "Description",
                            style: Theme.of(context).textTheme.bodyText2,
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          TextField(
                            enableInteractiveSelection: true,
                            controller: _descriptionController,
                            onChanged: (text) {
                              setState(() {
                                _descriptionController.value = TextEditingValue(
                                    text: text,
                                    selection: TextSelection(
                                        baseOffset: text.length,
                                        extentOffset: text.length));
                              });
                            },
                            decoration: new InputDecoration(
                              hintText: 'What does your model do (optional)?',
                            ),
                            keyboardType: TextInputType.multiline,
                            minLines: 3,
                            maxLines: 3,
                          ),
                          SizedBox(
                            height: 26,
                          ),
                          Text(
                            "Release Notes",
                            style: Theme.of(context).textTheme.bodyText2,
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          TextField(
                            controller: _releaseNotesController,
                            onChanged: (text) {
                              setState(() {
                                _releaseNotesController.value =
                                    TextEditingValue(
                                        text: text,
                                        selection: TextSelection(
                                            baseOffset: text.length,
                                            extentOffset: text.length));
                              });
                            },
                            decoration: new InputDecoration(
                              hintText:
                                  'What is different about this build (optional)?',
                            ),
                            keyboardType: TextInputType.multiline,
                            minLines: 3,
                            maxLines: 3,
                          ),
                          SizedBox(
                            height: 26,
                          ),
                          Text(
                            "Model Credits (URL of model author)",
                            style: Theme.of(context).textTheme.bodyText2,
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          TextField(
                            controller: _creditsController,
                            onChanged: (text) {
                              setState(() {
                                _creditsController.value = TextEditingValue(
                                    text: text,
                                    selection: TextSelection(
                                        baseOffset: text.length,
                                        extentOffset: text.length));
                              });
                            },
                            decoration: new InputDecoration(
                              errorText: _creditsController.text != ''
                                  ? (_isUrlValid(_creditsController.text)
                                      ? null
                                      : 'Enter valid url')
                                  : null,
                              hintText:
                                  'Github Url for original model code (optional)',
                            ),
                            keyboardType: TextInputType.url,
                            minLines: 1,
                            maxLines: 1,
                          ),
                          SizedBox(height: 26),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                    onPressed: _enabled
                                        ? () {
                                            notifier.update(
                                                title: _titleController.text,
                                                description:
                                                    _descriptionController.text,
                                                credits:
                                                    _creditsController.text,
                                                releaseNotes:
                                                    _releaseNotesController
                                                        .text);
                                          }
                                        : null,
                                    style: _enabled
                                        ? Theme.of(context)
                                            .elevatedButtonTheme
                                            .style
                                        : ElevatedButton.styleFrom(
                                            primary: Colors.grey.shade400),
                                    child: SizedBox(
                                      width: 220,
                                      height: 40,
                                      child: Center(
                                        child: Text("Save Changes",
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline5!
                                                .copyWith(
                                                    color: Colors.white,
                                                    fontSize:
                                                        calculatedButtonFontSize)),
                                      ),
                                    )),
                                ElevatedButton(
                                    onPressed: notifier.delete,
                                    style: ElevatedButton.styleFrom(
                                        primary: Colors.red.shade400),
                                    child: SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: Icon(Icons.delete_forever))),
                              ]),
                        ],
                      ),
                    ),
                  )
                ],
              );
            }, loading: () {
              return Stack(
                children: [LinearProgressIndicator(), Container()],
              );
            }, error: (error, st) {
              return SnackBarWidget(
                snackBarStatus: SnackBarStatus.Alert,
                message: error.toString(),
              );
            })));
  }
}
