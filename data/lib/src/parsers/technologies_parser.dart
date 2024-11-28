import 'parser.dart';

class Technology {
  final String id;
  final String name;
  final String icon;
  final String location;
  final Duration time;
  final Map<String, int> inputs;
  final List<String> recipes;
  final List<String> hiddenRecipes;
  final List<String> dependencies;

  Technology({
    required this.id,
    required this.name,
    required this.icon,
    required this.location,
    required this.time,
    required this.inputs,
    required this.recipes,
    required this.hiddenRecipes,
    required this.dependencies,
  });
}

class TechnologyManager {
  final List<Technology> technologies = [];
}

class TechnologiesParser extends Parser {
  final system = TechnologyManager();

  Technology _parseTechnologyManagerAdd(Exp exp) {
    // example:
    // TechnologyManager:add(
    //     TechnologyID.ConduitTapping,
    //     "ConduitTapping",
    //     "tech_icons_conduit_tapping",
    //     TechnologyLocation.Main,
    //     seconds(20),
    //     50,
    //     {"material.mechanical_essence"},
    //     {"ConduitTapping"},
    //     {},
    //     __TS__New(Set, {TechnologyID.RefinementProcess})
    // )
    if (exp is! FuncCallExp) {
      fail(exp, '$exp is not FuncCallExp');
    }
    final args = exp.args;
    if (args.length != 10) {
      fail(exp, 'Invalid technology add call');
    }

    final id = tableAccessToString(args[0] as TableAccessExp);
    final name = (args[1] as StringExp).str;
    final icon = (args[2] as StringExp).str;
    final location = tableAccessToString(args[3] as TableAccessExp);
    final time = parseDuration(args[4]);
    // All inputs use the same number of units.
    final units = (args[5] as IntegerExp).val;
    // Materials is an array of strings.
    final materials = (args[6] as TableConstructorExp)
        .valExps
        .map((exp) => (exp as StringExp).str)
        .toList();
    final recipes = (args[7] as TableConstructorExp)
        .valExps
        .map((exp) => (exp as StringExp).str)
        .toList();
    final hiddenRecipes = (args[8] as TableConstructorExp)
        .valExps
        .map((exp) => (exp as StringExp).str)
        .toList();
    // example:
    // __TS__New(Set, {TechnologyID.Farming, TechnologyID.Obsidian})
    final dependencies =
        ((args[9] as FuncCallExp).args[1] as TableConstructorExp)
            .valExps
            .map((exp) => tableAccessToString(exp as TableAccessExp))
            .toList();

    return Technology(
      id: id,
      name: name,
      icon: icon,
      location: location,
      time: time,
      inputs: {for (final material in materials) material: units},
      recipes: recipes,
      hiddenRecipes: hiddenRecipes,
      dependencies: dependencies,
    );
  }

  TechnologyManager parse(String content) {
    final block = parseLua(content);
    final addLoot = block.stats.firstWhere((stat) {
      if (stat is LocalFuncDefStat && stat.name == 'addTechnologies') {
        return true;
      }
      return false;
    }) as LocalFuncDefStat;
    for (final stat in addLoot.exp.block.stats) {
      if (stat is FuncCallStat) {
        final prefix = (stat.exp.prefixExp as NameExp).name;
        final name = stat.exp.nameExp?.str;
        final fullName = '$prefix:$name';
        if (fullName == "TechnologyManager:add") {
          final technology = _parseTechnologyManagerAdd(stat.exp);
          system.technologies.add(technology);
        }
      }
    }

    return system;
  }
}
