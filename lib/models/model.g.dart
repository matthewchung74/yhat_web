// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Model _$ModelFromJson(Map<String, dynamic> json) {
  return Model(
    id: json['id'] as String,
    githubUsername: json['github_username'] as String,
    repository: json['repository'] as String,
    notebook: json['notebook'] as String,
    branch: json['branch'] as String?,
    commit: json['commit'] as String?,
    userId: json['user_id'] as String,
    title: json['title'] as String?,
    user: json['user'] == null
        ? null
        : User.fromJson(json['user'] as Map<String, dynamic>),
    activeBuildId: json['active_build_id'] as String?,
    activeBuild: json['active_build'] == null
        ? null
        : Build.fromJson(json['active_build'] as Map<String, dynamic>),
    description: json['description'] as String?,
    tags: json['tags'] as List<dynamic>?,
    status: _$enumDecode(_$ModelStatusEnumMap, json['status']),
    updatedAt: json['updated_at'] == null
        ? null
        : DateTime.parse(json['updated_at'] as String),
    createdAt: json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
  );
}

Map<String, dynamic> _$ModelToJson(Model instance) => <String, dynamic>{
      'id': instance.id,
      'github_username': instance.githubUsername,
      'repository': instance.repository,
      'notebook': instance.notebook,
      'branch': instance.branch,
      'commit': instance.commit,
      'user_id': instance.userId,
      'title': instance.title,
      'description': instance.description,
      'user': instance.user?.toJson(),
      'active_build_id': instance.activeBuildId,
      'active_build': instance.activeBuild?.toJson(),
      'tags': instance.tags,
      'status': _$ModelStatusEnumMap[instance.status],
      'updated_at': instance.updatedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
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

const _$ModelStatusEnumMap = {
  ModelStatus.Draft: 'Draft',
  ModelStatus.Public: 'Public',
  ModelStatus.Private: 'Private',
  ModelStatus.Deleted: 'Deleted',
};
