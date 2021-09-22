// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notebook.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notebook _$NotebookFromJson(Map<String, dynamic> json) {
  return Notebook(
    name: json['name'] as String,
    contents: json['contents'] as String?,
    size: json['size'] as int?,
  );
}

Map<String, dynamic> _$NotebookToJson(Notebook instance) => <String, dynamic>{
      'name': instance.name,
      'contents': instance.contents,
      'size': instance.size,
    };
