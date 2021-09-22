// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:inference_app/api/api.dart';
// import 'package:inference_app/controller/providers.dart';
// import 'package:inference_app/models/model.dart';
// import 'package:inference_app/models/model_version.dart';
// import 'package:inference_app/page/model_page.dart';

// import '../main.dart';

// final versionListController = StateNotifierProvider.autoDispose.family<
//     VersionListNotifier,
//     AsyncValue<List<ModelVersion>>,
//     VersionListParameter>((ref, param) {
//   return VersionListNotifier(read: ref.read, param: param);
// });

// class VersionListNotifier
//     extends StateNotifier<AsyncValue<List<ModelVersion>>> {
//   VersionListNotifier({required this.read, required this.param})
//       : super(AsyncLoading()) {
//     fetchList(param);
//   }

//   final Reader read;
//   final VersionListParameter param;
//   void fetchList(VersionListParameter param) async {
//     state = AsyncLoading();
//     try {
//       List<ModelVersion> versions =
//           await read(apiProvider).getVersionList(param: param);
//       if (!mounted) return;
//       state = AsyncData(versions);
//     } catch (e) {
//       state = AsyncError(e);
//     }
//   }
// }

// class VersionList extends ConsumerWidget {
//   final Model model;
//   final bool showHeader;
//   final int start;
//   final int offset;

//   const VersionList({
//     Key? key,
//     required this.model,
//     this.showHeader = true,
//     this.start = 0,
//     this.offset = 10,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     VersionListParameter param = VersionListParameter(
//         modelId: model.modelId, start: start, offset: offset);
//     final controller = ref.watch(versionListController(param));

//     return controller.when(
//         data: (versions) => SliverList(
//                 delegate: SliverChildBuilderDelegate((context, index) {
//               if (showHeader == true && index == 0) {
//                 return Column(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Center(
//                         child: Text(
//                             versions.length > 0
//                                 ? "VERSIONS"
//                                 : "NO VERSIONS YET",
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .headline5!
//                                 .copyWith(
//                                     color: Color.fromRGBO(26, 36, 54, 1))),
//                       ),
//                       SizedBox(
//                         height: 40,
//                       ),
//                       Row(
//                         children: [
//                           Expanded(
//                             flex: 1,
//                             child: Text("VERSION"),
//                           ),
//                           Expanded(flex: 1, child: Text("UPLOADED"))
//                         ],
//                       ),
//                       Divider(),
//                       SizedBox(
//                         height: 4,
//                       ),
//                     ]);
//               }

//               ModelVersion version = versions[index - (showHeader ? 1 : 0)];
//               return Column(
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                           flex: 1,
//                           child: TextButton(
//                             onPressed: () {
//                               ref.read(navigationStackProvider).push(
//                                   MaterialPage(
//                                       key: ValueKey(
//                                           "ModelPage_${model.modelId}${model.versionId}"),
//                                       child: ModelPage(
//                                         modelId: model.modelId,
//                                         versionId: version.id,
//                                       )));
//                             },
//                             style: Theme.of(context)
//                                 .textButtonTheme
//                                 .style!
//                                 .copyWith(alignment: Alignment.centerLeft),
//                             child: Text(
//                               version.name,
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .bodyText1!
//                                   .copyWith(color: Colors.blue.shade700),
//                             ),
//                           )),
//                       Expanded(
//                           flex: 1, child: Text(formattedDate(version.date)))
//                     ],
//                   ),
//                   SizedBox(
//                     height: 4,
//                   ),
//                 ],
//               );
//             }, childCount: versions.length + (showHeader ? 1 : 0))),
//         loading: () {
//           if (showHeader == true) {
//             return SliverToBoxAdapter(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   SizedBox(
//                     height: 12,
//                   ),
//                   Center(
//                     child: Text("VERSIONS",
//                         style: Theme.of(context)
//                             .textTheme
//                             .headline5!
//                             .copyWith(color: Color.fromRGBO(26, 36, 54, 1))),
//                   ),
//                   SizedBox(
//                     height: 40,
//                   ),
//                   LinearProgressIndicator(),
//                 ],
//               ),
//             );
//           }
//           return SliverToBoxAdapter(
//             child: LinearProgressIndicator(),
//           );
//         },
//         error: (error, std) {
//           return SliverToBoxAdapter(child: Text("$error"));
//         });
//   }
// }
