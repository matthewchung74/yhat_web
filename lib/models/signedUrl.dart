import 'package:json_annotation/json_annotation.dart';

part 'signedUrl.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SignedUrl {
  final String url;
  final Map<String, String> fields;

  SignedUrl({required this.url, required this.fields});

  factory SignedUrl.fromJson(Map<String, dynamic> json) =>
      _$SignedUrlFromJson(json);

  Map<String, dynamic> toJson() => _$SignedUrlToJson(this);
}
