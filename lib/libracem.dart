import "dart:convert";

/*
import "package:foundation_castle/refbinarydata.dart";
class RacemBinUnit{
  final WordList base = WordList(4);
}
typedef RacemBin = List<RacemBinUnit>;
*/
class RangeShiftRule {
  final String name;
  final int begin;
  final int end;
  final int diff;
  final int mult;
  final int offset;

  RangeShiftRule(this.begin, this.end,
      [this.diff = 0, this.mult = 1, this.offset = 0, this.name = ""]);
  int shift(int from) => (this.begin <= from && from <= this.end)
      ? (from + this.diff) * this.mult + this.offset
      : from;
  /*
  NRange<int> get asNRange => NRange<int>(x: this.begin, y: this.end);
*/
}

class RiceManipulater {
  final List<RangeShiftRule> shiftRules = <RangeShiftRule>[
    RangeShiftRule(0x41, 0x41 + 25, -0x41, 2, 0, "UpperAlpha"),
    RangeShiftRule(0x61, 0x61 + 25, -0x61, 2, 1, "LowerAlpha"),
    RangeShiftRule(0x30, 0x30 + 9, 0x34 - 0x30, 1, 0, "Numeric")
  ];
  final Map<int, int> shiftMap = <int, int>{}.mergeId<String>({
    "Delimiter": <int, int>{
      0x20: 0x40,
      0x5f: 0x42,
      0x2d: 0x43,
      0x2e: 0x41,
      0x3a: 0x45,
      0x23: 0x46,
      0x7c: 0x44,
      0x40: 0x47,
    },
    "Additional": <int, int>{
      0x2a: 0x54,
      0x2b: 0x53,
      0x26: 0x55,
    },
    "Parenthes": <int, int>{}
  });
  int shift(int target) {
    List<RangeShiftRule> shiftRulesMatches = this
        .shiftRules
        .where((RangeShiftRule sr) => sr.begin <= target && target <= sr.end)
        .toList();
    int? shiftMapMatches = this.shiftMap[target];
    if (shiftRulesMatches.isNotEmpty) {
      return shiftRulesMatches.first.shift(target);
    } else if (shiftMapMatches != null) {
      return shiftMapMatches;
    } else {
      throw AssertionError(
          "Any rules what maches (xd: $target, xh: ${target.toRadixString(16)}) are NOT Exist.");
    }
  }
}
int cnt = 0;
class Rice {
  static bool isAlphaNum(int rice) => rice < 0x40;
  static bool isAlpha(int rice) => rice < 0x34;
  static bool isExtSyms(int rice) => rice >= 0x40;
  static RiceRange rangeOf(int rice) {
    if (rice.isNegative) {
      throw AssertionError("Invalid Range in Rice");
    } else if (Rice.isAlphaNum(rice)) {
      if (Rice.isAlpha(rice)) {
        if (rice % 2 == 0) {
          return RiceRange.UpperAlpha;
        } else {
          return RiceRange.LowerAlpha;
        }
      } else {
        return RiceRange.Numeric;
      }
    } else {
      if (rice < 0x50) {
        return RiceRange.Delimiter;
      } else if (rice < 0x60) {
        return RiceRange.Additional;
      } else if (rice < 0x70) {
        return RiceRange.Parenthes;
      } else {
        throw AssertionError("Invalid Range in Rice");
      }
    }
  }

  static bool isValid(int rice) {
    try {
      Rice.rangeOf(rice);
    } on AssertionError catch (_) {
      return false;
    }
    return true;
  }

  static final Map<RiceRange, List<RiceRange>> subCls = {
    RiceRange.All: [RiceRange.AlphaNum, RiceRange.ExtSyms],
    RiceRange.AlphaNum: [RiceRange.Alpha, RiceRange.Numeric],
    RiceRange.Alpha: [RiceRange.UpperAlpha, RiceRange.LowerAlpha],
    RiceRange.ExtSyms: [
      RiceRange.SymExtA,
      RiceRange.Delimiter,
      RiceRange.SymExtB,
      RiceRange.Additional,
      RiceRange.SymExtC,
      RiceRange.Parenthes,
    ],
    RiceRange.SymExtA: [RiceRange.Delimiter],
    RiceRange.SymExtB: [RiceRange.Additional],
    RiceRange.SymExtC: [RiceRange.Parenthes],
    RiceRange.Delimiter: [RiceRange.SymExtA],
    RiceRange.Additional: [RiceRange.SymExtB],
    RiceRange.Parenthes: [RiceRange.SymExtC],
  };
  //ToDo: otherがtargetの真部分集合の場合無限再帰になる件修正する
  static bool isIncludes(RiceRange target, RiceRange other, [int? cntx]) {
    cntx ??= Rice.subCls.length * Rice.subCls.length;
    if(cntx < 0) return false;
    if (target == other) {
      return true;
    } else {
      List<RiceRange>? tr = Rice.subCls[other];
      if (tr == null) {
        return false;
      }
      if (tr.length == 0) {
        return false;
      }
      for(int i = 0; i < tr.length; i++){
        RiceRange t = tr[i];
        bool e = Rice.isIncludes(target, t, cntx - 1);
        if(e){
          return e;
        }
      }
      return false;
    }
  }
}

enum RiceRange {
  All,
  AlphaNum,
  Alpha,
  UpperAlpha,
  LowerAlpha,
  Numeric,
  ExtSyms,
  SymExtA,
  Delimiter,
  SymExtB,
  Additional,
  SymExtC,
  Parenthes,
}

class RiceValidator extends Converter<String, String> {
  @override
  String convert(String input) {
    RegExp re = RegExp("");
    if (re.hasMatch(input)) {
      return input;
    } else {
      throw Error();
    }
  }
}

class RiceAsciiAssembler extends Converter<int, int> {
  @override
  int convert(int input) => RiceManipulater().shift(input);
}

class RiceAsciiDisassembler extends Converter<int, int> {
  @override
  int convert(int input) {
    return input;
  }
}

typedef EConv<E> = Converter<E, E>;

class ListElementConverter<E> extends Converter<List<E>, List<E>> {
  final EConv<E> elementConverter;
  ListElementConverter(this.elementConverter);
  @override
  List<E> convert(List<E> input) =>
      input.map<E>((E el) => elementConverter.convert(el)).toList();
}

class RiceCodec extends Codec<String, List<int>> {
  @override
  final Converter<String, List<int>> encoder = RiceValidator()
      .fuse(AsciiEncoder())
      .fuse(ListElementConverter<int>(RiceAsciiAssembler()));
  @override
  final Converter<List<int>, String> decoder =
      ListElementConverter<int>(RiceAsciiDisassembler()).fuse(AsciiDecoder());
}

class ConditionSwitcher<C, R> {
  final Map<C, R> conditions;
  final R Function(List<R>) singleSelector;
  final Object? throws;
  ConditionSwitcher(this.conditions,
      {R Function(List<R>)? singleSelector, this.throws})
      : this.singleSelector = singleSelector == null
            ? ((List<R> maches) => maches.first)
            : singleSelector;
  List<R> _emptyChecker(List<R> target) {
    if (target.isEmpty && this.throws != null) {
      throw this.throws!;
    }
    return target;
  }

  R decide(C target) =>
      this.singleSelector(this._emptyChecker(Map<C, R>.fromEntries(this
          .conditions
          .entries
          .where((MapEntry<C, R> el) => el.key == target)).values.toList()));
}

extension<K, V> on Map<K, V> {
  Map<K, V> merge(List<Map<K, V>> entries) {
    Map<K, V> t = Map<K, V>.of(this);
    for (Map<K, V> entry in entries) {
      t.addAll(entry);
    }
    return t;
  }

  Map<K, V> mergeId<KI>(Map<KI, Map<K, V>> entries) =>
      this.merge(entries.values.toList());
}
/*
class NRange<N extends num>{
  final N max;
  final N min;
  final bool maxIncludes;
  final bool minIncludes;
  NRange({required N x, required N y, bool xIncludes = true, bool yIncludes = false}):
      this.max = x > y ? x : y,
      this.min = x > y ? y : x,
      this.maxIncludes = x > y ? xIncludes : yIncludes,
      this.minIncludes = x > y ? yIncludes : xIncludes;
  N get wide => this.max - this.min as N;
  bool isInclude(N target) =>  (this.minIncludes ? this.min <= target : this.min < target) && (this.maxIncludes ? target <= this.max : target < this.max);
  bool isOverlap(NRange<N> other) =>;
  bool operator <(NRange<N> other){
    if(this.isOverlap(other)){}else{
      
    }
    return false;
  }
  NRange<N> expand({N? x, N? y, bool xIncludes = true, bool yIncludes = false})=>this;
  NRange<N> merge(NRange<N> other)=> this ;
  NRange<N> clone() => NRange<N>(x: this.max, y: this.min, xIncludes: maxIncludes, yIncludes: minIncludes);
}*/