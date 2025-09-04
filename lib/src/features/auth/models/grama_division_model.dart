import 'package:flutter/foundation.dart';

@immutable
class GramaDivision {
  final String id;
  final String code;
  final String name;

  const GramaDivision({
    required this.id,
    required this.code,
    required this.name,
  });

  factory GramaDivision.fromJson(Map<String, dynamic> json) {
    return GramaDivision(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }

  @override
  String toString() => 'GramaDivision(id: $id, code: $code, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is GramaDivision &&
      other.id == id &&
      other.code == code &&
      other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ code.hashCode ^ name.hashCode;
}
