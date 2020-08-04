// ignore_for_file: parameter_assignments

import 'dart:convert';

import 'json_reader_config.dart';

typedef ListItemMapper<T, R> = R Function(T item);

class InvalidJsonValueException implements Exception {
  InvalidJsonValueException(this.value);

  final dynamic value;

  @override
  String toString() {
    return 'InvalidJsonValueException{value: $value}';
  }
}

/// Provides safe access to JSON values.
/// Any null field values are automatically replaced with default ones.
///
/// Examples:
/// Get top field value:
/// ```
/// final json = '''
/// {
///   "topField": "Hello",
///   "object1": {
///      "object2": {
///         "int": 0
///      }
///   }
/// }
/// ''';
/// final value = JsonReader(json)['topField'].asString();
/// ```
///
/// Get nested field value:
/// ```
/// final json = '''
/// {
///   "object1": {
///      "object2": {
///         "int": 0
///      }
///   }
/// }
/// ''';
/// final value = JsonReader(json)['object1']['object2']['int'].asInt()
/// ```
///
/// Get nested list of ints:
/// ```
/// final json = '''
/// {
///   "object1": {
///      "object2": {
///         "int": 0,
///         "list": [0, 1, 2, 3]
///      }
///   }
/// }
/// ''';
/// final value = JsonReader(json)['object1']['list'].asListOf<int>();
/// ```
class JsonReader {
  JsonReader(
    Object json, {
    JsonReaderConfig config,
  })  : _json = json,
        _config = config ?? JsonReaderConfig() {
    final isValidJson = _json == null ||
        _json is Map ||
        _json is List ||
        _json is String ||
        _json is bool ||
        _json is num;

    if (!isValidJson) {
      throw InvalidJsonValueException(_json);
    }
  }

  factory JsonReader.decode(
    String jsonString, {
    JsonReaderConfig config,
  }) {
    dynamic decodedJson;
    try {
      decodedJson = jsonDecode(jsonString);
    } catch (_) {}
    return JsonReader(decodedJson, config: config);
  }

  final Object _json;
  final JsonReaderConfig _config;

  int asInt({
    bool permissive,
    int defaultValue,
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
    bool permissive,
    double defaultValue,
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
    bool permissive,
    String defaultValue,
    bool trim,
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
      final result = v.toString() ?? defaultValue;
      if (trim) {
        return result.trim();
      }
      return result;
    }

    throw ArgumentError('Illegal type: ${v.runtimeType}');
  }

  bool asBool({
    bool permissive,
    bool defaultValue,
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
      if (v is num) {
        return v > 0;
      }
      if (v is String) {
        final lowerCaseValue = v.toLowerCase();
        if (lowerCaseValue == 'true' || lowerCaseValue == '1') {
          return true;
        }

        final parsedNumValue = num.tryParse(lowerCaseValue);
        if (parsedNumValue != null && parsedNumValue > 0) {
          return true;
        }

        return false;
      }
    }
    throw ArgumentError('Illegal type: ${v.runtimeType}');
  }

  Map<K, V> asMap<K, V>({
    bool permissive,
    Map<K, V> defaultValue,
  }) {
    permissive ??= _config.permissive;
    defaultValue ??= const {};

    final v = _json;
    if (v == null) {
      if (permissive) {
        return defaultValue;
      }
      throw ArgumentError.notNull();
    }

    if (v is Map && v.entries.every((e) => e.key is K && e.value is V)) {
      return v.cast<K, V>();
    }

    if (v is String) {
      return JsonReader.decode(v).asMap<K, V>();
    }

    throw ArgumentError.value(_json, 'json', 'must be a Map<$K, $V>');
  }

  List<JsonReader> asList({bool permissive}) {
    permissive ??= _config.permissive;

    final v = _json;
    if (v == null && permissive) {
      return const [];
    }
    return _getList(v);
  }

  List<T> asListOf<T>({
    bool permissive,
    List<T> defaultValue,
  }) {
    permissive ??= _config.permissive;
    defaultValue ??= const [];

    final v = _json;
    if (v == null) {
      if (permissive) {
        return defaultValue;
      }
      throw ArgumentError.notNull();
    }

    if (v is List && v.every((item) => item is T)) {
      return v.cast<T>();
    }

    if (v is String) {
      return JsonReader.decode(v).asListOf<T>(
        permissive: permissive,
        defaultValue: defaultValue,
      );
    }

    throw ArgumentError.value(_json, 'json', 'must be a List<$T>');
  }

  bool containsKey(Object key) {
    final v = _json;
    if (v == null) {
      return false;
    }
    if (v is Map) {
      return v.containsKey(key);
    }
    return false;
  }

  JsonReader operator [](Object key) {
    assert(key is int || key is String);

    if (key is int && _json is List) {
      final list = _getList(_json);
      final listItemReader = list[key];
      return listItemReader ?? JsonReader(null);
    }
    if (key is String && _json is Map) {
      final map = _getObject(_json);
      final mapItemReader = map[key];
      return mapItemReader ?? JsonReader(null);
    }
    return JsonReader(null);
  }

  @override
  String toString() {
    try {
      return jsonEncode(_json);
    } catch (_) {
      return '';
    }
  }
}

Map<String, JsonReader> _getObject(Object value) {
  final v = value ?? const <String, JsonReader>{};

  if (v is Map && v.keys.every((k) => k is String)) {
    return v.map(
      (k, v) => MapEntry(k, JsonReader(v)),
    );
  }

  throw ArgumentError('Illegal type: ${v.runtimeType}');
}

List<JsonReader> _getList(Object value) {
  final v = value ?? const <JsonReader>[];
  if (v is Iterable) {
    return v.map((item) => JsonReader(item)).toList();
  }

  throw ArgumentError('Illegal type: ${v.runtimeType}');
}
