// ignore: implementation_imports
import 'package:lua_dardo/src/compiler/ast/block.dart';
// ignore: implementation_imports
import 'package:lua_dardo/src/compiler/ast/exp.dart';
// ignore: implementation_imports
import 'package:lua_dardo/src/compiler/parser/parser.dart' as lua_dardo;

export 'package:lua_dardo/src/compiler/ast/exp.dart';
export 'package:lua_dardo/src/compiler/ast/stat.dart';
export 'package:lua_dardo/src/compiler/parser/parser.dart';

extension CaseTools on String {
  String toLoweredCamel() {
    return this[0].toLowerCase() + substring(1);
  }
}

class Parser {
  Never fail(Exp exp, String message) {
    throw 'Failed to parse $exp on ${exp.lastLine}: $message';
  }

  Block parseLua(String content) {
    return lua_dardo.Parser.parse(content, "main");
  }
}
