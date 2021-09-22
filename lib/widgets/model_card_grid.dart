import 'package:flutter/material.dart';
import 'package:inference_app/models/model.dart';

import 'model_card.dart';

class ModelCardGrid extends StatelessWidget {
  final int columns;
  final List<Model> models;
  final Function({required Model model}) onModelPressed;
  final Function({required Model model}) onProfilePressed;
  final Function({required Model model}) onGithubPressed;

  const ModelCardGrid(
      {Key? key,
      required this.columns,
      required this.models,
      required this.onModelPressed,
      required this.onProfilePressed,
      required this.onGithubPressed})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;

    if (models.length == 0) {
      return SliverToBoxAdapter(
        child: Container(
          height: screenHeight * 0.4,
          child: Center(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "NO MODELS YET",
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
    return SliverGrid.count(
        childAspectRatio: (columns == 1) ? 2 : 1.5,
        crossAxisCount: columns,
        mainAxisSpacing: 6,
        children: models
            .map(
              (model) => ModelCard(
                model: model,
                onModelPressed: () {
                  onModelPressed(model: model);
                },
                onProfilePressed: () {
                  onProfilePressed(model: model);
                },
                onGithubPressed: () async {
                  onGithubPressed(model: model);
                },
              ),
            )
            .toList());
  }
}
