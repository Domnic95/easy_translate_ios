class Language {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const Language(this.code, this.name, this.nativeName, this.flag);

  bool get isAuto => code == 'auto';
}
