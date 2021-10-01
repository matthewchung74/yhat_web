// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:yhat_app/api/api.dart';
// import 'package:yhat_app/controller/providers.dart';
// import 'package:yhat_app/models/model.dart';
// import 'package:yhat_app/widgets/my_app_bar.dart';

// final versionPageController = StateNotifierProvider.autoDispose
//     .family<VersionNotifier, AsyncValue<Model>, ModelParameter>((ref, param) {
//   return VersionNotifier(read: ref.read, param: param);
// });

// class VersionNotifier extends StateNotifier<AsyncValue<Model>> {
//   VersionNotifier({required this.read, required this.param})
//       : super(AsyncLoading()) {
//     fetchModel(param);
//   }

//   final Reader read;
//   final ModelParameter param;
//   void fetchModel(ModelParameter param) async {
//     state = AsyncLoading();
//     try {
//       Model model = await read(apiProvider).fetchModel(param: param);
//       state = AsyncData(model);
//     } catch (e) {
//       state = AsyncError(e);
//     }
//   }
// }

// class VersionListPage extends ConsumerWidget {
//   final String modelId;

//   const VersionListPage({Key? key, required this.modelId}) : super(key: key);

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     ModelParameter param = ModelParameter(modelId: modelId);
//     final controller = ref.watch(versionPageController(param));

//     return Scaffold(
//         appBar: myAppBar(context: context, ref: ref),
//         body: Container(
//             width: double.infinity,
//             child: controller.when(
//               data: (data) {
//                 return VersionPageWidget(model: data);
//               },
//               loading: () {
//                 return CustomScrollView(slivers: [
//                   SliverToBoxAdapter(child: LinearProgressIndicator()),
//                 ]);
//               },
//               error: (err, st) => Text('error $err $st'),
//             )));
//   }
// }

// class VersionPageWidget extends StatelessWidget {
//   final Model model;

//   const VersionPageWidget({Key? key, required this.model}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     var screenWidth = MediaQuery.of(context).size.width;
//     double calculatedTitleFontSize = 32 * screenWidth / 800;

//     return CustomScrollView(slivers: [
//       SliverPadding(
//         padding: const EdgeInsets.all(20),
//         sliver: SliverToBoxAdapter(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Flexible(
//                         flex: 2,
//                         child: Text(
//                           model.formattedFileName(),
//                           style: Theme.of(context)
//                               .textTheme
//                               .headline3!
//                               .copyWith(fontSize: calculatedTitleFontSize),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       Flexible(flex: 1, child: Container()),
//                     ],
//                   ),
//                   SizedBox(
//                     height: 20,
//                   ),
//                 ],
//               )
//             ],
//           ),
//         ),
//       ),
//       SliverPadding(
//           padding: const EdgeInsets.all(20),
//           sliver: VersionList(
//             model: model,
//             start: 0,
//             offset: 5,
//           )),
//     ]);
//   }
// }
