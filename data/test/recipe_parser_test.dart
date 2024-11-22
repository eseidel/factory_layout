import 'package:data/recipe_parser.dart';
import 'package:test/test.dart';

void main() {
  test('calculate', () {
    final lua = '''
local function addRecipes(self, CraftManager)
    CraftManager:add(__TS__New(
        CraftRecipe,
        "Ceramic",
        {
            Item.create("material.mineral", 5),
            __TS__New(FluidItem, FluidType.Water, 10)
        },
        {Item.create("material.ceramic", 1)},
        seconds(3),
        CraftSite.Infuser,
        CraftTab.Materials,
        17,
        false
    ))
end
    ''';
    final parser = RecipeParser();
    final recipes = parser.parse(lua);
    expect(recipes.length, 1);
    final recipe = recipes.first;
    expect(recipe.name, 'Ceramic');
    expect(recipe.inputs.length, 2);
    expect(recipe.outputs.length, 1);
    expect(recipe.duration.inSeconds, 3);
    expect(recipe.sites.length, 1);
    expect(recipe.sites.first, CraftSite.infuser);
    expect(recipe.tab, CraftTab.materials);
    expect(recipe.id, 17);
    expect(recipe.unlocked, false);
  });
}
