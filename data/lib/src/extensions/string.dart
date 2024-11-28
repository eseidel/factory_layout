extension CaseTools on String {
  String toLoweredCamel() {
    return this[0].toLowerCase() + substring(1);
  }
}
