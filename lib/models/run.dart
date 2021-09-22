import 'package:json_annotation/json_annotation.dart';

part 'run.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Run {
  final String id;
  final String modelId;
  final String buildId;
  final Map<String, dynamic> inputJson;
  final Map<String, dynamic> outputJson;
  final Map<String, dynamic>? thumbJson;
  final DateTime createdAt;
  const Run(
      {required this.id,
      required this.modelId,
      required this.buildId,
      required this.inputJson,
      required this.outputJson,
      this.thumbJson,
      required this.createdAt});

  factory Run.fromJson(Map<String, dynamic> json) => _$RunFromJson(json);

  Map<String, dynamic> toJson() => _$RunToJson(this);
}
