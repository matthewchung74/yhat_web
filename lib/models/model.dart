import 'dart:io';
import 'package:yhat_app/models/build.dart';
import 'package:yhat_app/models/user.dart';
import 'package:path/path.dart';

import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

enum ModelStatus { Draft, Public, Private, Deleted }

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Model {
  final String id;
  final String githubUsername;
  final String repository;
  final String notebook;
  final String? branch;
  final String? commit;
  final String userId;
  final String? title;
  final String? description;
  final String? credits;
  final User? user;
  final String? activeBuildId;
  final Build? activeBuild;
  final List? tags;
  final ModelStatus status;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  Model({
    required this.id,
    required this.githubUsername,
    required this.repository,
    required this.notebook,
    this.branch,
    this.commit,
    required this.userId,
    this.title,
    this.user,
    this.activeBuildId,
    this.activeBuild,
    this.description,
    this.credits,
    this.tags,
    required this.status,
    this.updatedAt,
    this.createdAt,
  });

  String get prettyNotebookName {
    File file = new File(notebook);
    String basename = basenameWithoutExtension(file.path);
    return basename.toUpperCase();
  }

  String? get prettyCreditUsername {
    if (this.credits == null) return null;

    Uri uri = Uri.parse(this.credits!);
    if (uri.isAbsolute) {
      if (uri.host.contains("github.com") && (uri.pathSegments.length >= 5)) {
        return uri.pathSegments[0];
      }
    }
    return this.credits;
  }

  String get homepage {
    return "https://github.com/$githubUsername/$repository/blob/$branch/$notebook";
  }

  String get userHomepage {
    return "https://github.com/$githubUsername";
  }

  String? get prettyTags {
    if (tags != null) {
      return '';
    } else {
      return null;
    }
  }

  factory Model.fromJson(Map<String, dynamic> json) => _$ModelFromJson(json);

  Map<String, dynamic> toJson() => _$ModelToJson(this);
}
