// ignore_for_file: avoid_dynamic_calls

class JsonReaderConfig {
  JsonReaderConfig({
    JsonReaderDefaults? defaults,
    this.permissive = true,
    this.trimStrings = true,
  }) : _defaults = defaults;

  final JsonReaderDefaults? _defaults;

  JsonReaderDefaults get defaults => _defaults ?? JsonReaderDefaults.global;

  final bool permissive;
  final bool trimStrings;

  static final JsonReaderConfig global = JsonReaderConfig();
}

class JsonReaderDefaults {
  JsonReaderDefaults();

  final Map<Type, Object> _defaults = {};

  int get defaultInt => (_defaults[int] as int?) ?? 0;
  set defaultInt(int value) {
    _defaults[int] = value;
  }

  double get defaultDouble => (_defaults[double] as double?) ?? 0.0;
  set defaultDouble(double value) {
    _defaults[double] = value;
  }

  bool get defaultBool => (_defaults[bool] as bool?) ?? false;
  set defaultBool(bool value) {
    _defaults[bool] = value;
  }

  String get defaultString => (_defaults[String] as String?) ?? '';
  set defaultString(String value) {
    _defaults[String] = value;
  }

  DateTime get defaultDateTime => (_defaults[DateTime] as DateTime?) ?? DateTime(1970);
  set defaultDateTime(DateTime value) {
    _defaults[DateTime] = value;
  }

  static final JsonReaderDefaults global = JsonReaderDefaults();
}
