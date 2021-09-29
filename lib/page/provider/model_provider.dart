import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yhat_app/controller/providers.dart';
import 'package:yhat_app/models/model.dart';

final modelProvider =
    StateNotifierProvider.autoDispose<ModelNotifier, AsyncValue<Model>>((ref) {
  return ModelNotifier(read: ref.read);
});

class ModelNotifier extends StateNotifier<AsyncValue<Model>> {
  final Reader read;
  var mounted = true;

  ModelNotifier({required this.read}) : super(AsyncLoading());

  void fetchModel({required String modelId}) async {
    try {
      Model model = await read(apiProvider).fetchModel(modelId: modelId);
      state = AsyncData(model);
    } catch (e) {
      state = AsyncError(e);
    }
  }

  void update(
      {required String modelId,
      String? title,
      String? description,
      String? releaseNotes}) async {
    try {
      Model model = await read(apiProvider).updateModel(
          modelId: modelId,
          title: title,
          description: description,
          releaseNotes: releaseNotes);
      state = AsyncData(model);
    } catch (e) {
      state = AsyncError(e);
    }
  }

  void delete({required String modelId}) async {
    try {
      Model model = await read(apiProvider).deleteModel(modelId: modelId);
      state = AsyncData(model);
    } catch (e) {
      state = AsyncError(e);
    }
  }
}
