import 'package:json_annotation/json_annotation.dart';

part 'token.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Token {
  final String token;
  final String userId;

  Token({required this.token, required this.userId});

  factory Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);

  Map<String, dynamic> toJson() => _$TokenToJson(this);
}
