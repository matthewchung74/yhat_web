import 'package:json_annotation/json_annotation.dart';

part 'repository.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Repository {
  final String fullName;
  final String name;
  final String defaultBranch;
  final String id;
  int? numBranches;
  final bool private;

  Repository(
      {required this.fullName,
      required this.name,
      required this.defaultBranch,
      required this.id,
      required this.private});

  factory Repository.fromJson(Map<String, dynamic> json) =>
      _$RepositoryFromJson(json);

  Map<String, dynamic> toJson() => _$RepositoryToJson(this);
}
