import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/walker.dart';

class _Placement {
  final int offset;
  final int depth;
  _Placement(this.offset, this.depth);

  _Placement addDepth(int amount) => _Placement(offset, depth + amount);
  _Placement withOffset(int offset) => _Placement(offset, depth);
}

class DecisionTreePrinter<T> extends DecisionTreeWalker<T, int, _Placement> {
  final int horizontalSpacing;
  final int verticalSpacing;
  DecisionTreePrinter([this.horizontalSpacing = 2, this.verticalSpacing = 4]);
  final lines = <String>[];
  String print(DecisionTree tree) {
    walk(tree, _Placement(0, 0));
    return lines.join('\n');
  }

  int visitBranch(Branch branch, _Placement placement) {
    final depth = placement.depth;
    final offset = placement.offset;
    final fourLinesDown = placement.addDepth(verticalSpacing);
    int leftOffset = walk(branch.left, fourLinesDown);
    int rightStartOffset = leftOffset + horizontalSpacing;
    int rightOffset =
        walk(branch.right, fourLinesDown.withOffset(rightStartOffset));
    int middleOffset = offset + ((rightOffset - offset) / 2).round();
    int leftMiddleOffset = leftOffset + ((offset - leftOffset) / 2).round();
    int rightMiddleOffset =
        rightStartOffset + ((rightOffset - rightStartOffset) / 2).round();
    for (int d = depth + verticalSpacing - 1, i = leftMiddleOffset + 1;
        i < middleOffset;
        ++i, --d) {
      if (d > depth) {
        printAt(d, i, '/');
      } else {
        printAt(depth, i, '-');
      }
    }
    printAt(depth, middleOffset, '*');
    for (var i = middleOffset + 1; i < rightMiddleOffset; ++i) {
      final d = i - rightMiddleOffset + depth + verticalSpacing;
      if (d > depth) {
        printAt(d, i, r'\');
      } else {
        printAt(depth, i, '-');
      }
    }
    return rightOffset;
  }

  int visitDecision(Decision decision, _Placement placement) {
    final str = decision.outcome.toString() +
        " " +
        (decision.probability * 100).toStringAsPrecision(4) +
        "%";
    printAt(placement.depth, placement.offset, str);
    return placement.offset + str.length;
  }

  void printAt(int line, int offset, String value) {
    while (lines.length <= line) {
      lines.add('');
    }
    final lineLength = lines[line].length;
    assert(lineLength <= offset);
    final difference = offset - lineLength;
    lines[line] += ' ' * difference + value;
  }
}
