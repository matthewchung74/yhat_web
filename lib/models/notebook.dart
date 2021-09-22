import 'package:json_annotation/json_annotation.dart';

part 'notebook.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Notebook {
  final String name;
  final String? contents;
  final int? size;

  Notebook({
    required this.name,
    this.contents,
    this.size,
  });

  factory Notebook.fromJson(Map<String, dynamic> json) =>
      _$NotebookFromJson(json);

  Map<String, dynamic> toJson() => _$NotebookToJson(this);
}
