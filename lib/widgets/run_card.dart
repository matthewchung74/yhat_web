import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:inference_app/api/api.dart';
import 'package:inference_app/helpers/ui.dart';
import 'package:inference_app/models/model.dart';
import 'package:inference_app/models/run.dart';

class RunCard extends StatelessWidget {
  final Model model;
  final Run run;

  const RunCard({Key? key, required this.model, required this.run})
      : super(key: key);

  List<Widget> _buildCards(
      {required BuildContext context,
      required Map<String, dynamic> jsonType,
      required Map<String, dynamic> runJson,
      required Map<String, dynamic>? thumbJson,
      required bool left}) {
    double margin = MediaQuery.of(context).size.width / 4.0;

    return runJson.keys.toList().map((runJsonKey) {
      return Container(
        decoration: BoxDecoration(
            border: Border.all(width: 2, color: Colors.grey.shade100)),
        alignment: left ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
            margin:
                EdgeInsets.fromLTRB(left ? 0 : margin, 0, left ? margin : 0, 0),
            child: _buildCard(
                context: context,
                runJson: runJson,
                thumbJson: thumbJson,
                runJsonKey: runJsonKey,
                jsonType: jsonType)),
      );
    }).toList();
  }

  Widget _buildCard(
      {required BuildContext context,
      required Map<String, dynamic> runJson,
      required Map<String, dynamic>? thumbJson,
      required String runJsonKey,
      required Map<String, dynamic> jsonType}) {
    double imageWidth = MediaQuery.of(context).size.width / 3.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(runJsonKey,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText2!
                        .copyWith(color: Colors.grey.shade600, fontSize: 12)),
                SizedBox(
                  height: 2,
                ),
                if (jsonType[runJsonKey] == 'Text')
                  InkWell(
                    onTap: () {
                      Codec<String, String> stringToBase64 = utf8.fuse(base64);
                      String urlData =
                          "data:application/octet-stream;base64,${stringToBase64.encode(runJson[runJsonKey])}";
                      launchURLBrowser(url: urlData, target: "_blank");
                    },
                    child: Text(runJson[runJsonKey],
                        style: Theme.of(context).textTheme.bodyText2!),
                  ),
                if ((jsonType[runJsonKey] == 'PIL' ||
                        jsonType[runJsonKey] == 'OpenCV') &&
                    runJson[runJsonKey] is String)
                  InkWell(
                      onTap: () {
                        launchURLBrowser(
                            url: runJson[runJsonKey], target: "_blank");
                      },
                      child: FadeInImage.assetNetwork(
                        fadeInDuration: Duration(milliseconds: 300),
                        placeholder: 'image/placeholder.jpg',
                        image: thumbJson != null &&
                                thumbJson.containsKey(runJson[runJsonKey])
                            ? thumbJson[runJson[runJsonKey]]
                            : runJson[runJsonKey],
                        width: imageWidth,
                        height: imageWidth,
                        imageErrorBuilder: (context, error, stackTrace) {
                          return Text("Error loading image");
                        },
                      )),
                if ((jsonType[runJsonKey] == 'PIL' ||
                        jsonType[runJsonKey] == 'OpenCV') &&
                    runJson[runJsonKey] is PlatformFile)
                  Image.memory(
                    runJson[runJsonKey].bytes,
                    fit: BoxFit.contain,
                    width: imageWidth,
                    height: imageWidth,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Column(
            children: [
              Text(
                "${formattedDate(run.createdAt)} (${model.githubUsername})",
                style: Theme.of(context)
                    .textTheme
                    .bodyText2!
                    .copyWith(color: Colors.grey.shade600, fontSize: 12),
              ),
              SizedBox(
                height: 8,
              ),
              ..._buildCards(
                  context: context,
                  jsonType: model.activeBuild!.inputJson!,
                  thumbJson: run.thumbJson,
                  runJson: run.inputJson,
                  left: true),
              if (run.outputJson.length > 0)
                SizedBox(
                  height: 8,
                ),
              if (run.outputJson.length > 0)
                ..._buildCards(
                    context: context,
                    jsonType: model.activeBuild!.outputJson!,
                    thumbJson: run.thumbJson,
                    runJson: run.outputJson,
                    left: false),
              SizedBox(
                height: 20,
              ),
              Divider(),
              SizedBox(
                height: 20,
              ),
            ],
          )
        ],
      ),
    );
  }
}
