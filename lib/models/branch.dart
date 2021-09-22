import 'package:json_annotation/json_annotation.dart';

part 'branch.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Branch {
  final String name;
  final String? commit;
  int? numberNotebooks;

  Branch({required this.name, this.commit, this.numberNotebooks});

  factory Branch.fromJson(Map<String, dynamic> json) => _$BranchFromJson(json);

  Map<String, dynamic> toJson() => _$BranchToJson(this);
}
