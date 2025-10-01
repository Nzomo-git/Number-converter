import 'dart:math';

const String DIGITS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

int _charToVal(String ch) => DIGITS.indexOf(ch);
String _valToChar(int v) => DIGITS[v];

class DecimalParts {
  final BigInt intPart;
  final double fracPart;
  final bool negative;
  DecimalParts(this.intPart, this.fracPart, this.negative);
}

class Converter {
  static bool validate(String s, int base) {
    s = s.trim().toUpperCase();
    if (s.isEmpty) return false;
    if (s.startsWith('-')) s = s.substring(1);
    if (s.contains('.')) {
      var parts = s.split('.');
      if (parts.length > 2) return false;
    }
    for (var ch in s.replaceAll('.', '').split('')) {
      if (!DIGITS.contains(ch) || _charToVal(ch) >= base) return false;
    }
    return true;
  }

  static DecimalParts toDecimalParts(String s, int base) {
    s = s.trim().toUpperCase();
    var negative = s.startsWith('-');
    if (negative) s = s.substring(1);
    var intStr = s;
    var fracStr = '';
    if (s.contains('.')) {
      var p = s.split('.');
      intStr = p[0];
      fracStr = p.length > 1 ? p[1] : '';
    }
    BigInt intPart = BigInt.zero;
    for (var ch in intStr.split('')) {
      if (ch == '') continue;
      intPart = intPart * BigInt.from(base) + BigInt.from(_charToVal(ch));
    }
    double fracPart = 0.0;
    double denom = base.toDouble();
    for (var ch in fracStr.split('')) {
      if (ch == '') continue;
      fracPart += _charToVal(ch) / denom;
      denom *= base;
    }
    return DecimalParts(intPart, fracPart, negative);
  }

  static String fromDecimalParts(BigInt intPart, double fracPart, int base, {int precision = 12}) {
    var intStr = '';
    var absInt = intPart >= BigInt.zero ? intPart : -intPart;
    if (absInt == BigInt.zero) {
      intStr = '0';
    } else {
      var buf = <String>[];
      while (absInt > BigInt.zero) {
        var rem = (absInt % BigInt.from(base)).toInt();
        buf.add(_valToChar(rem));
        absInt = absInt ~/ BigInt.from(base);
      }
      intStr = buf.reversed.join();
    }

    var fracStr = '';
    if (fracPart > 0) {
      var buf = <String>[];
      var f = fracPart;
      for (var i = 0; i < precision; i++) {
        f *= base;
        int digit = f.floor();
        buf.add(_valToChar(digit));
        f -= digit;
        if (f.abs() < 1e-15) break;
      }
      fracStr = '.' + buf.join();
    }

    return intStr + fracStr;
  }

  static String convert(String s, int fromBase, int toBase, {int precision = 12}) {
    if (!validate(s, fromBase)) throw Exception('Invalid input for base $fromBase');
    var parts = toDecimalParts(s, fromBase);
    var out = fromDecimalParts(parts.intPart, parts.fracPart, toBase, precision: precision);
    return parts.negative ? '-' + out : out;
  }
}
