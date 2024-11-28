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

  String tableAccessToString(TableAccessExp exp) {
    final prefix = (exp.prefixExp as NameExp?)?.name;
    final key = (exp.keyExp as StringExp).str;
    return "$prefix.$key";
  }

  void expect(Exp exp, bool condition, String message) {
    if (!condition) {
      fail(exp, message);
    }
  }

  Block parseLua(String content) {
    return lua_dardo.Parser.parse(content, "main");
  }

  Duration parseDuration(Exp exp) {
    if (exp is! FuncCallExp) {
      fail(exp, 'Invalid duration');
    }
    final name = (exp.prefixExp as NameExp).name;
    if (name != 'seconds') {
      fail(exp, 'Invalid duration');
    }
    final arg = exp.args.first;
    final int milliseconds;
    if (arg is IntegerExp) {
      milliseconds = arg.val * 1000;
    } else if (arg is FloatExp) {
      milliseconds = (arg.val * 1000).toInt();
    } else {
      fail(exp, 'Invalid duration');
    }
    return Duration(milliseconds: milliseconds);
  }
}
