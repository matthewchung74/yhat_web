import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

import 'package:yhat_app/models/token.dart';

part 'user.g.dart';

enum UserType {
  Anonymous,
  NotEmailVerified,
  EmailVerified,
  GithubVerified,
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class User {
  String? avatarUrl;
  String? company;
  String? htmlUrl;
  String? fullname;
  String? email;
  String? githubId;
  String? githubUsername;
  String? id;
  Token? token;
  UserType type;
  bool? earlyAccess;
  User(
      {this.avatarUrl,
      this.company,
      this.htmlUrl,
      this.fullname,
      this.email,
      this.githubId,
      this.githubUsername,
      this.id,
      this.token,
      this.earlyAccess,
      this.type = UserType.Anonymous});

  User clone() {
    return User.fromJson(jsonDecode(jsonEncode(this)));
  }

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
