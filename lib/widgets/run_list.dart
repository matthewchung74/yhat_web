import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yhat_app/models/model.dart';
import 'package:yhat_app/models/run.dart';
import 'package:yhat_app/page/run_list_page.dart';
import 'package:yhat_app/widgets/run_card.dart';

import '../main.dart';

class RunList extends StatelessWidget {
  final Model? model;
  final bool showHeader;
  final List<Run>? runs;
  final bool showAllRuns;

  const RunList({
    Key? key,
    required this.model,
    required this.runs,
    required this.showAllRuns,
    this.showHeader = true,
  }) : super(key: key);

  Widget _noRunsYet(
      {required double screenHeight, required BuildContext context}) {
    return SliverToBoxAdapter(
      child: Container(
        height: screenHeight * 0.4,
        child: Center(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "NO RUNS YET",
              style: Theme.of(context).textTheme.bodyText2,
            ),
            SizedBox(
              width: 4,
            ),
            Icon(
              Icons.sentiment_neutral,
              color: Theme.of(context).textTheme.bodyText2!.color,
            ),
          ],
        )),
      ),
    );
  }

  Widget _header({required BuildContext context}) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 1,
                child: Text(""),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(runs!.length > 0 ? "RUNS" : "",
                      style: Theme.of(context)
                          .textTheme
                          .headline5!
                          .copyWith(color: Color.fromRGBO(26, 36, 54, 1))),
                ),
              ),
              Expanded(
                flex: 1,
                child: Opacity(
                    opacity: showAllRuns ? 1 : 0,
                    child: Consumer(builder: (context, ref, _) {
                      return TextButton(
                          onPressed: () {
                            ref.read(navigationStackProvider).push(MaterialPage(
                                name: "RunListPage",
                                child: RunListPage(
                                  modelId: model!.id,
                                )));
                          },
                          style: Theme.of(context)
                              .textButtonTheme
                              .style!
                              .copyWith(
                                  padding:
                                      MaterialStateProperty.all<EdgeInsets>(
                                          EdgeInsets.fromLTRB(0, 0, 0, 0))),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'ALL RUNS',
                              textAlign: TextAlign.right,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5!
                                  .copyWith(color: Colors.blue.shade700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ));
                    })),
              ),
            ],
          ),
          SizedBox(
            height: 24,
          ),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;

    if (runs == null || runs!.length == 0 || model == null) {
      return _noRunsYet(screenHeight: screenHeight, context: context);
    }

    return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
      if (showHeader == true && index == 0) {
        return _header(context: context);
      }

      Run run = runs![index - (showHeader ? 1 : 0)];
      if (index == runs!.length - 1) {
        return RunCard(model: model!, run: run);
      } else {
        return RunCard(model: model!, run: run);
      }
    }, childCount: runs!.length + (showHeader ? 1 : 0)));
  }
}
