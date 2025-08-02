// Tool to import auto_forge data from the game.
// AutoForge uses lua (transpiled from typescript).

import 'package:data/data.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:yaml_edit/yaml_edit.dart';

void writeYamlFiles(Data data, Directory outDir) {
  // Generate the yaml files with the data.
  if (!outDir.existsSync()) {
    outDir.createSync();
  }

  void writeAsYaml(String path, dynamic json) {
    final file = outDir.childFile(path);
    final yamlEditor = YamlEditor('')..update([], json);
    file.writeAsStringSync(yamlEditor.toString());
  }

  writeAsYaml(
      'recipes.yaml', data.recipes.map((recipe) => recipe.toJson()).toList());
  writeAsYaml('loot.yaml', data.loot.toJson());
  writeAsYaml('technologies.yaml', data.technologies.toJson());
}

void main(List<String> args) {
  if (args.length != 1) {
    print('Usage: auto_forge <scriptsPath>');
    return;
  }
  final fs = LocalFileSystem();
  final scriptsDir = fs.directory(args[0]);
  final data = Data.fromScriptsDir(scriptsDir);

  print('Parsed ${data.recipes.length} recipes.');
  print('Parsed ${data.loot.groups.length} loot groups '
      'and ${data.loot.batches.length} loot batches.');
  print('Parsed ${data.technologies.technologies.length} technologies.');

  writeYamlFiles(data, fs.directory('out'));
}
