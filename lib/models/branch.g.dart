// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Branch _$BranchFromJson(Map<String, dynamic> json) {
  return Branch(
    name: json['name'] as String,
    commit: json['commit'] as String?,
    numberNotebooks: json['number_notebooks'] as int?,
  );
}

Map<String, dynamic> _$BranchToJson(Branch instance) => <String, dynamic>{
      'name': instance.name,
      'commit': instance.commit,
      'number_notebooks': instance.numberNotebooks,
    };
