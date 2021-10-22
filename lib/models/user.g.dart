// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  return User(
    avatarUrl: json['avatar_url'] as String?,
    company: json['company'] as String?,
    htmlUrl: json['html_url'] as String?,
    fullname: json['fullname'] as String?,
    email: json['email'] as String?,
    githubId: json['github_id'] as String?,
    githubUsername: json['github_username'] as String?,
    id: json['id'] as String?,
    token: json['token'] == null
        ? null
        : Token.fromJson(json['token'] as Map<String, dynamic>),
    earlyAccess: json['early_access'] as bool?,
    type: _$enumDecode(_$UserTypeEnumMap, json['type']),
  );
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'avatar_url': instance.avatarUrl,
      'company': instance.company,
      'html_url': instance.htmlUrl,
      'fullname': instance.fullname,
      'email': instance.email,
      'github_id': instance.githubId,
      'github_username': instance.githubUsername,
      'id': instance.id,
      'token': instance.token?.toJson(),
      'type': _$UserTypeEnumMap[instance.type],
      'early_access': instance.earlyAccess,
    };

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

const _$UserTypeEnumMap = {
  UserType.Anonymous: 'Anonymous',
  UserType.NotEmailVerified: 'NotEmailVerified',
  UserType.EmailVerified: 'EmailVerified',
  UserType.GithubVerified: 'GithubVerified',
};
