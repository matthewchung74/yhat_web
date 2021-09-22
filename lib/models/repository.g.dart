// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Repository _$RepositoryFromJson(Map<String, dynamic> json) {
  return Repository(
    fullName: json['full_name'] as String,
    name: json['name'] as String,
    defaultBranch: json['default_branch'] as String,
    id: json['id'] as String,
    private: json['private'] as bool,
  )..numBranches = json['num_branches'] as int?;
}

Map<String, dynamic> _$RepositoryToJson(Repository instance) =>
    <String, dynamic>{
      'full_name': instance.fullName,
      'name': instance.name,
      'default_branch': instance.defaultBranch,
      'id': instance.id,
      'num_branches': instance.numBranches,
      'private': instance.private,
    };
