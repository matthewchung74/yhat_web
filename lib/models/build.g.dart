// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Build _$BuildFromJson(Map<String, dynamic> json) {
  return Build(
    id: json['id'] as String,
    modelId: json['model_id'] as String,
    githubUsername: json['github_username'] as String,
    repository: json['repository'] as String,
    branch: json['branch'] as String,
    notebook: json['notebook'] as String,
    commit: json['commit'] as String?,
    lastRun: json['last_run'] == null
        ? null
        : DateTime.parse(json['last_run'] as String),
    buildLog: json['build_log'] as String?,
    status: _$enumDecodeNullable(_$BuildStatusEnumMap, json['status']),
    releaseNotes: json['release_notes'] as String?,
    inputJson: (json['input_json'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, e as String),
    ),
    outputJson: (json['output_json'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, e as String),
    ),
  );
}

Map<String, dynamic> _$BuildToJson(Build instance) => <String, dynamic>{
      'model_id': instance.modelId,
      'id': instance.id,
      'github_username': instance.githubUsername,
      'repository': instance.repository,
      'branch': instance.branch,
      'notebook': instance.notebook,
      'commit': instance.commit,
      'last_run': instance.lastRun?.toIso8601String(),
      'build_log': instance.buildLog,
      'status': _$BuildStatusEnumMap[instance.status],
      'release_notes': instance.releaseNotes,
      'input_json': instance.inputJson,
      'output_json': instance.outputJson,
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

K? _$enumDecodeNullable<K, V>(
  Map<K, V> enumValues,
  dynamic source, {
  K? unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<K, V>(enumValues, source, unknownValue: unknownValue);
}

const _$BuildStatusEnumMap = {
  BuildStatus.NotStarted: 'NotStarted',
  BuildStatus.Queued: 'Queued',
  BuildStatus.Cancelled: 'Cancelled',
  BuildStatus.Started: 'Started',
  BuildStatus.Error: 'Error',
  BuildStatus.Finished: 'Finished',
};
