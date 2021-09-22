import 'package:flutter/material.dart';
import 'package:inference_app/models/model.dart';

class ModelCard extends StatelessWidget {
  final Model model;
  final VoidCallback onModelPressed;
  final VoidCallback onProfilePressed;
  final VoidCallback onGithubPressed;

  const ModelCard(
      {Key? key,
      required this.model,
      required this.onModelPressed,
      required this.onProfilePressed,
      required this.onGithubPressed})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(width: 2, color: Colors.grey.shade100)),
      child: Card(
        color: model.id == '' ? Colors.grey[200] : Colors.white,
        child: InkWell(
          onTap: onModelPressed,
          onHover: (value) {},
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.title != null && model.title != ""
                      ? model.title!
                      : model.prettyNotebookName,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1!
                      .copyWith(color: Colors.blue[700]),
                  overflow: TextOverflow.ellipsis,
                ),
                if (model.prettyTags != null)
                  SizedBox(
                    height: 4,
                  ),
                if (model.prettyTags != null)
                  Text(
                    model.prettyTags!,
                    style: Theme.of(context).textTheme.bodyText2,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(
                  height: 4,
                ),
                new Expanded(child: new LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                  final text =
                      model.description != null ? model.description! : "";
                  final style = Theme.of(context).textTheme.bodyText2;
                  // final span = TextSpan(text: text, style: style);
                  // final tp = TextPainter(text: span);
                  // tp.layout(maxWidth: constraints.maxWidth);
                  // int numberOfLines = tp.computeLineMetrics().length;
                  int maxLines =
                      (constraints.maxHeight / style!.fontSize!).floor() - 1;
                  maxLines = maxLines <= 0 ? 1 : maxLines;
                  return Text(text,
                      style: style,
                      overflow: TextOverflow.ellipsis,
                      // maxLines: 1);
                      maxLines: maxLines);
                })),
                SizedBox(
                  height: 1,
                ),
                if (model.id != '')
                  Row(
                    children: [
                      TextButton(
                          onPressed: () {
                            onProfilePressed();
                          },
                          style: Theme.of(context).textButtonTheme.style,
                          child: Row(
                            children: [
                              Text(
                                model.githubUsername,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1!
                                    .copyWith(color: Colors.blue.shade700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )),
                      SizedBox(
                        width: 4,
                      ),
                      TextButton(
                          onPressed: () {
                            onGithubPressed();
                          },
                          style: Theme.of(context).textButtonTheme.style,
                          child: Row(
                            children: [
                              Image(
                                image: AssetImage('image/github.png'),
                                width: 30,
                                height: 30,
                              ),
                            ],
                          )),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModelCardPlaceHolder extends StatelessWidget {
  const ModelCardPlaceHolder({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[200],
    );
  }
}
