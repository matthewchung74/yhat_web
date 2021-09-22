import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';

import 'package:json_annotation/json_annotation.dart';

part 'build.g.dart';

enum BuildStatus { NotStarted, Queued, Cancelled, Started, Error, Finished }

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Build {
  String modelId;
  String id;
  String githubUsername;
  String repository;
  String branch;
  String notebook;
  String? commit;
  DateTime? lastRun;
  String? buildLog;

  BuildStatus? status;
  String? releaseNotes;
  Map<String, String>? inputJson;
  Map<String, String>? outputJson;
  Build({
    required this.id,
    required this.modelId,
    required this.githubUsername,
    required this.repository,
    required this.branch,
    required this.notebook,
    required this.commit,
    this.lastRun,
    this.buildLog,
    required this.status,
    this.releaseNotes,
    this.inputJson,
    this.outputJson,
  });

  Build clone() {
    return Build.fromJson(jsonDecode(jsonEncode(this)));
  }

  String get prettyNotebookName {
    File file = new File(notebook);
    String basename = basenameWithoutExtension(file.path);
    return basename.toUpperCase();
  }

  factory Build.fromJson(Map<String, dynamic> json) => _$BuildFromJson(json);

  Map<String, dynamic> toJson() => _$BuildToJson(this);
}
