import 'dart:math';

extension RandomChoice<T> on Iterable<T> {
  T randomChoice([int? till]) {
    assert(till == null || till >= 0);
    return this.elementAt(
      Random().nextInt(till != null && till >= 0 ? till : this.length),
    );
  }
}
