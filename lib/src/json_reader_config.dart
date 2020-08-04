class JsonReaderConfig {
  JsonReaderConfig({
    JsonReaderDefaults defaults,
    this.permissive = true,
    this.trimStrings = true,
  }) : _defaults = defaults;

  final JsonReaderDefaults _defaults;

  JsonReaderDefaults get defaults => _defaults ?? JsonReaderDefaults.global;

  final bool permissive;
  final bool trimStrings;

  static JsonReaderConfig global = JsonReaderConfig();
}

class JsonReaderDefaults {
  JsonReaderDefaults();

  final Map<dynamic, dynamic> _defaults = {};

  int get defaultInt => _defaults[int] ?? 0;
  set defaultInt(int value) {
    _defaults[int] = value;
  }

  double get defaultDouble => _defaults[double] ?? 0.0;
  set defaultDouble(double value) {
    _defaults[double] = value;
  }

  bool get defaultBool => _defaults[bool] ?? false;
  set defaultBool(bool value) {
    _defaults[bool] = value;
  }

  String get defaultString => _defaults[String] ?? '';
  set defaultString(String value) {
    _defaults[String] = value;
  }

  static JsonReaderDefaults global = JsonReaderDefaults();
}
