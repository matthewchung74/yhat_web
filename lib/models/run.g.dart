// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Run _$RunFromJson(Map<String, dynamic> json) {
  return Run(
    id: json['id'] as String,
    modelId: json['model_id'] as String,
    buildId: json['build_id'] as String,
    inputJson: json['input_json'] as Map<String, dynamic>,
    outputJson: json['output_json'] as Map<String, dynamic>,
    thumbJson: json['thumb_json'] as Map<String, dynamic>?,
    githubUsername: json['github_username'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

Map<String, dynamic> _$RunToJson(Run instance) => <String, dynamic>{
      'id': instance.id,
      'model_id': instance.modelId,
      'build_id': instance.buildId,
      'github_username': instance.githubUsername,
      'input_json': instance.inputJson,
      'output_json': instance.outputJson,
      'thumb_json': instance.thumbJson,
      'created_at': instance.createdAt.toIso8601String(),
    };
