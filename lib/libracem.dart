import "dart:convert";
import "package:foundation_castle/refbinarydata.dart";
class RacemBinUnit{
  final WordList base = WordList(4);
}
typedef RacemBin = List<RacemBinUnit>;

class RangeShiftRule{
  final int begin;
  final int end;
  final int diff;
  RangeShiftRule(this.begin, this.end, [this.diff = 0]);
  int shift(int from) => (this.begin <= from && from <= this.end) ? from + this.diff : from;
  NRange<int> get asNRange => NRange<int>(x: this.begin, y: this.end);
}



class RiceManipulater{
  final List<RangeShiftRule> shiftRules = <RangeShiftRule>[];
  final Map<int, int> shiftMap = {};
  int shift(int target){
    List<RangeShiftRule> shiftRulesMatches = this.shiftRules.where((RangeShiftRule sr)=>sr.begin <= target && target <= sr.end).toList();
    int? shiftMapMatches = this.shiftMap[target];
    if(shiftRulesMatches.isNotEmpty){
      return shiftRulesMatches.first.shift(target);
    }else if(shiftMapMatches != null){
    return shiftMapMatches;
    }else{
      throw Error();
    }
  }
}
class RiceValidator extends Converter<String, String>{
  @override
  String convert(String input){
    RegExp re = RegExp("");
    if(re.hasMatch(input)){
      return input;
    }else{
      throw Error();
    }
  }
}
class RiceAsciiAssembler extends Converter<int, int>{
  @override
  int convert(int input) => RiceManipulater().shift(input);
}
class RiceAsciiDisassembler extends Converter<int, int>{
  @override
  int convert(int input){
    return input;
  }
}
class ListElementConverter<E> extends Converter<List<E>, List<E>>{
  final Converter<E, E> elementConverter;
ListElementConverter(this.elementConverter);
  @override
  List<E> convert(List<E> input) => input.map<E>((E el) => elementConverter.convert(el)).toList();
}
class RiceCodec extends Codec<String, List<int>>{
  @override
  final Converter<String, List<int>> encoder = RiceValidator().fuse(AsciiEncoder()).fuse(ListElementConverter<int>(RiceAsciiAssembler()));
  @override
  final Converter<List<int>, String> decoder = ListElementConverter<int>(RiceAsciiDisassembler()).fuse(AsciiDecoder());
}

class ConditionSwitcher<C, R>{
  final Map<C, R> conditions;
  final R Function(List<R>) singleSelector;
  final Object? throws;
  ConditionSwitcher(this.conditions, {R Function(List<R>)? singleSelector, this.throws}): this.singleSelector = singleSelector == null ? ((List<R> maches) => maches.first) : singleSelector;
  List<R> _emptyChecker(List<R> target){
    if(target.isEmpty && this.throws != null){
      throw this.throws!;
    }
    return target;
  }
  R decide(C target) => this.singleSelector(this._emptyChecker(Map<C, R>.fromEntries(this.conditions.entries.where((MapEntry<C, R> el) => el.key == target)).values.toList()));
}
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
}