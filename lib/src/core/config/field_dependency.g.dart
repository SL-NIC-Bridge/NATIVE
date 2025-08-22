// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field_dependency.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FieldDependencyCondition _$FieldDependencyConditionFromJson(
  Map<String, dynamic> json,
) => FieldDependencyCondition(
  field: json['field'] as String,
  condition: json['condition'] as String,
  value: json['value'],
  behavior:
      $enumDecodeNullable(_$DependencyBehaviorEnumMap, json['behavior']) ??
      DependencyBehavior.hide,
);

Map<String, dynamic> _$FieldDependencyConditionToJson(
  FieldDependencyCondition instance,
) => <String, dynamic>{
  'field': instance.field,
  'condition': instance.condition,
  'value': ?instance.value,
  'behavior': _$DependencyBehaviorEnumMap[instance.behavior]!,
};

const _$DependencyBehaviorEnumMap = {
  DependencyBehavior.hide: 'hide',
  DependencyBehavior.disable: 'disable',
};
