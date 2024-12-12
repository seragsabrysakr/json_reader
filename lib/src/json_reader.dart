// ignore_for_file: parameter_assignments, avoid_dynamic_calls

import 'dart:convert';

import 'json_reader_config.dart';

typedef ListItemMapper<T, R> = R Function(T item);

class InvalidJsonValueException implements Exception {
  InvalidJsonValueException(this.value);

  final Object? value;

  @override
  String toString() {
    return 'InvalidJsonValueException{value: $value}';
  }
}

class JsonReader {
  JsonReader(
    Object? json, {
    JsonReaderConfig? config,
  })  : _json = json,
        _config = config ?? JsonReaderConfig.global {
    final isValidJson = _json == null ||
        _json is Map<String, dynamic> ||
        _json is List<dynamic> ||
        _json is String ||
        _json is bool ||
        _json is num;

    if (!isValidJson) {
      throw InvalidJsonValueException(_json);
    }
  }

  factory JsonReader.decode(
    String jsonString, {
    JsonReaderConfig? config,
  }) {
    dynamic decodedJson;
    try {
      decodedJson = jsonDecode(jsonString);
    } catch (_) {
      // Ignore decode errors and return null json
    }
    return JsonReader(decodedJson, config: config);
  }

  final Object? _json;
  final JsonReaderConfig _config;

  JsonReader operator [](String key) {
    if (_json is Map<String, dynamic>) {
      final map = _json as Map<String, dynamic>;
      return JsonReader(map[key], config: _config);
    }
    return JsonReader(null, config: _config);
  }

  int asInt({
    bool? permissive,
    int? defaultValue,
  }) {
    permissive ??= _config.permissive;
    defaultValue ??= _config.defaults.defaultInt;

    final v = _json;
    if (v == null) {
      if (permissive) {
        return defaultValue;
      }
      throw ArgumentError.notNull();
    }

    if (v is int) {
      return v;
    }

    if (permissive) {
      if (v is num) {
        return v.toInt();
      }
      if (v is String) {
        return int.tryParse(v) ?? defaultValue;
      }
    }

    throw ArgumentError('Illegal type: ${v.runtimeType}');
  }

  double asDouble({
    bool? permissive,
    double? defaultValue,
  }) {
    permissive ??= _config.permissive;
    defaultValue ??= _config.defaults.defaultDouble;

    final v = _json;
    if (v == null) {
      if (permissive) {
        return defaultValue;
      }
      throw ArgumentError.notNull();
    }

    if (v is double) {
      return v;
    }

    if (permissive) {
      if (v is num) {
        return v.toDouble();
      }
      if (v is String) {
        return double.tryParse(v) ?? defaultValue;
      }
    }

    throw ArgumentError('Illegal type: ${v.runtimeType}');
  }

  String asString({
    bool? permissive,
    String? defaultValue,
    bool? trim,
  }) {
    permissive ??= _config.permissive;
    defaultValue ??= _config.defaults.defaultString;
    trim ??= _config.trimStrings;

    final v = _json;
    if (v == null) {
      if (permissive) {
        return defaultValue;
      }
      throw ArgumentError.notNull();
    }

    if (v is String) {
      if (trim) {
        return v.trim();
      }
      return v;
    }

    if (permissive) {
      final result = v.toString();
      if (trim) {
        return result.trim();
      }
      return result;
    }

    throw ArgumentError('Illegal type: ${v.runtimeType}');
  }

  bool asBool({
    bool? permissive,
    bool? defaultValue,
  }) {
    permissive ??= _config.permissive;
    defaultValue ??= _config.defaults.defaultBool;

    final v = _json;
    if (v == null) {
      if (permissive) {
        return defaultValue;
      }
      throw ArgumentError.notNull();
    }

    if (v is bool) {
      return v;
    }

    if (permissive) {
      if (v is String) {
        final lower = v.toLowerCase();
        if (lower == 'true') {
          return true;
        }
        if (lower == 'false') {
          return false;
        }
        return defaultValue;
      }
      if (v is num) {
        if (v == 1) {
          return true;
        }
        if (v == 0) {
          return false;
        }
        return defaultValue;
      }
    }

    throw ArgumentError('Illegal type: ${v.runtimeType}');
  }

  Map<K, V> asMap<K, V>({
    bool? permissive,
    Map<K, V>? defaultValue,
  }) {
    permissive ??= _config.permissive;
    defaultValue ??= <K, V>{};

    final v = _json;
    if (v == null) {
      if (permissive) {
        return defaultValue;
      }
      throw ArgumentError.notNull();
    }

    if (v is Map) {
      try {
        return Map<K, V>.from(v);
      } catch (_) {
        if (permissive) {
          return defaultValue;
        }
      }
    }

    throw ArgumentError.value(_json, 'json', 'must be a Map<$K, $V>');
  }

  List<JsonReader> asList({bool? permissive}) {
    permissive ??= _config.permissive;

    final v = _json;
    return _getList(v);
  }

  List<T> asListOf<T>({
    bool? permissive,
    List<T>? defaultValue,
  }) {
    permissive ??= _config.permissive;
    defaultValue ??= <T>[];

    final v = _json;
    if (v == null) {
      if (permissive) {
        return defaultValue;
      }
      throw ArgumentError.notNull();
    }

    if (v is! List) {
      if (permissive) {
        return defaultValue;
      }
      throw ArgumentError.value(v, 'json', 'must be a List');
    }

    try {
      return List<T>.from(v);
    } catch (_) {
      if (permissive) {
        return defaultValue;
      }
      rethrow;
    }
  }

  List<R> asListOfMapped<T, R>({
    required ListItemMapper<T, R> mapper,
    bool? permissive,
    List<R>? defaultValue,
  }) {
    permissive ??= _config.permissive;
    defaultValue ??= <R>[];

    final v = _json;
    if (v == null) {
      if (permissive) {
        return defaultValue;
      }
      throw ArgumentError.notNull();
    }

    if (v is! List) {
      if (permissive) {
        return defaultValue;
      }
      throw ArgumentError.value(v, 'json', 'must be a List');
    }

    try {
      return v.map((item) => mapper(item as T)).toList();
    } catch (_) {
      if (permissive) {
        return defaultValue;
      }
      rethrow;
    }
  }

  int? asIntOrNull({
    bool? permissive,
    int? defaultValue,
  }) {
    permissive ??= _config.permissive;
    defaultValue ??= _config.defaults.defaultInt;

    final v = _json;
    if (v == null) {
      return null;
    }

    if (v is int) {
      return v;
    }

    if (permissive) {
      if (v is num) {
        return v.toInt();
      }
      if (v is String) {
        return int.tryParse(v);
      }
    }

    return null;
  }

  double? asDoubleOrNull({
    bool? permissive,
    double? defaultValue,
  }) {
    permissive ??= _config.permissive;
    defaultValue ??= _config.defaults.defaultDouble;

    final v = _json;
    if (v == null) {
      return null;
    }

    if (v is double) {
      return v;
    }

    if (permissive) {
      if (v is num) {
        return v.toDouble();
      }
      if (v is String) {
        return double.tryParse(v);
      }
    }

    return null;
  }

  String? asStringOrNull({
    bool? permissive,
    String? defaultValue,
    bool? trim,
  }) {
    permissive ??= _config.permissive;
    defaultValue ??= _config.defaults.defaultString;
    trim ??= _config.trimStrings;

    final v = _json;
    if (v == null) {
      return null;
    }

    if (v is String) {
      if (trim) {
        return v.trim();
      }
      return v;
    }

    if (permissive) {
      final result = v.toString();
      if (trim) {
        return result.trim();
      }
      return result;
    }

    return null;
  }

  bool? asBoolOrNull({
    bool? permissive,
    bool? defaultValue,
  }) {
    permissive ??= _config.permissive;
    defaultValue ??= _config.defaults.defaultBool;

    final v = _json;
    if (v == null) {
      return null;
    }

    if (v is bool) {
      return v;
    }

    if (permissive) {
      if (v is String) {
        final lower = v.toLowerCase();
        if (lower == 'true') {
          return true;
        }
        if (lower == 'false') {
          return false;
        }
        return null;
      }
      if (v is num) {
        if (v == 1) {
          return true;
        }
        if (v == 0) {
          return false;
        }
        return null;
      }
    }

    return null;
  }
}

List<JsonReader> _getList(Object? value) {
  final v = value ?? const <dynamic>[];
  if (v is Iterable) {
    return v.map((dynamic item) => JsonReader(item)).toList();
  }

  throw ArgumentError('Illegal type: ${v.runtimeType}');
}
