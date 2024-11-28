class Material {
  String name;

  Material(this.name);

  factory Material.fromString(String fullname) {
    final parts = fullname.split('.');
    if (parts.length != 2) {
      throw ArgumentError('Invalid material: $fullname');
    }
    if (parts[0] != 'material') {
      throw ArgumentError('Invalid material: $fullname');
    }
    return Material(parts[1]);
  }

  @override
  String toString() {
    return 'material.$name';
  }

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) {
    return other is Material && other.name == name;
  }
}
