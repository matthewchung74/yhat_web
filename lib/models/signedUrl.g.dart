// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signedUrl.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignedUrl _$SignedUrlFromJson(Map<String, dynamic> json) {
  return SignedUrl(
    url: json['url'] as String,
    fields: Map<String, String>.from(json['fields'] as Map),
  );
}

Map<String, dynamic> _$SignedUrlToJson(SignedUrl instance) => <String, dynamic>{
      'url': instance.url,
      'fields': instance.fields,
    };
