import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_design.dart';
import 'motion.dart';

/// Lays out all 604 pages once in 30 rows, by the juz of each page's first verse.
/// Four pages contain two juz in the bundled data; details show both.
abstract final class PageGridLayout {
  /// First page whose first verse belongs to each juz (verified against data).
  static const juzStarts = <int>[
    1, 22, 42, 63, 82, 102, 122, 142, 162, 182, 202, 222, 242, 262, 282, //
    302, 322, 342, 362, 382, 402, 422, 442, 462, 482, 503, 522, 542, 562, 582,
  ];
  static const rows = 30, maxColumns = 23, labelColumns = 1.6;

  static int rowOf(int page) {
    var row = 0;
    while (row + 1 < rows && juzStarts[row + 1] <= page) {
      row++;
    }
    return row;
  }

  static int columnOf(int page) => page - juzStarts[rowOf(page)];

  static int rowLength(int row) =>
      (row + 1 < rows ? juzStarts[row + 1] : 605) - juzStarts[row];

  /// Width / height ratio of the full grid including the label column.
  static double get aspectRatio => (maxColumns + labelColumns) / rows;

  /// Square cell size and the top-left origin of the grid inside [size].
  static (double cell, Offset origin) geometry(Size size) {
    final cell =
        min(size.width / (maxColumns + labelColumns), size.height / rows);
    final width = cell * (maxColumns + labelColumns);
    return (cell, Offset((size.width - width) / 2, 0));
  }

  static Rect rectFor(int page, Size size) {
    final (cell, origin) = geometry(size);
    return Rect.fromLTWH(origin.dx + (labelColumns + columnOf(page)) * cell,
        origin.dy + rowOf(page) * cell, cell, cell);
  }

  static int? pageAt(Offset offset, Size size) {
    if (size.width <= 0 || size.height <= 0) return null;
    final (cell, origin) = geometry(size);
    final local = offset - origin;
    final row = (local.dy / cell).floor();
    final column = (local.dx / cell - labelColumns).floor();
    if (local.dx < 0 || local.dy < 0 || row < 0 || row >= rows) return null;
    if (column < 0 || column >= rowLength(row)) return null;
    return juzStarts[row] + column;
  }
}

/// Paints the page grid. Done cells "fill in" in reading order as [reveal]
/// goes from 0 to 1.
class PageGridPainter extends CustomPainter {
  PageGridPainter(
      {required this.done,
      required this.palette,
      this.partial = const {},
      this.selected,
      this.reveal = 1});
  final Set<int> done, partial;
  final int? selected;
  final double reveal;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final (cell, origin) = PageGridLayout.geometry(size);
    final gap = cell * 0.16;
    final radius = Radius.circular(cell * 0.22);
    final fill = Paint();
    final threshold = reveal * (604 + 60);
    final labelSize = (cell * 0.5).clamp(6.0, 11.0);
    final showLabels = cell >= 8;
    for (var row = 0; row < PageGridLayout.rows; row++) {
      if (showLabels && (cell >= 11 || row % 5 == 0 || row == 29)) {
        final painter = TextPainter(
            text: TextSpan(
                text: '${row + 1}',
                style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: palette.muted)),
            textDirection: TextDirection.ltr)
          ..layout();
        painter.paint(
            canvas,
            Offset(
                origin.dx +
                    PageGridLayout.labelColumns * cell -
                    gap * 2 -
                    painter.width,
                origin.dy + row * cell + (cell - painter.height) / 2));
      }
    }
    for (var page = 1; page <= 604; page++) {
      final rect = RRect.fromRectAndRadius(
          PageGridLayout.rectFor(page, size).deflate(gap / 2), radius);
      fill.color = partial.contains(page) ? palette.partial : palette.unread;
      canvas.drawRRect(rect, fill);
      if (done.contains(page)) {
        final alpha = ((threshold - page) / 60).clamp(0.0, 1.0);
        if (alpha > 0) {
          fill.color = palette.done.withOpacity(alpha);
          canvas.drawRRect(rect, fill);
        }
      }
      if (selected == page) {
        canvas.drawRRect(
            rect.inflate(gap * 0.6),
            Paint()
              ..color = palette.ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(1.4, cell * 0.08));
        canvas.drawCircle(rect.center, cell * 0.12,
            Paint()..color = done.contains(page) ? Colors.white : palette.ink);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PageGridPainter oldDelegate) =>
      !setEquals(oldDelegate.done, done) ||
      !setEquals(oldDelegate.partial, partial) ||
      oldDelegate.selected != selected ||
      oldDelegate.reveal != reveal ||
      oldDelegate.palette != palette;
}

/// Interactive page grid with a one-shot fill animation.
class PageGrid extends StatelessWidget {
  const PageGrid(
      {super.key,
      required this.done,
      required this.onSelect,
      required this.semanticsLabel,
      this.partial = const {},
      this.selected,
      this.paintKey});
  final Set<int> done, partial;
  final int? selected;
  final ValueChanged<int> onSelect;
  final String semanticsLabel;
  final Key? paintKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return Semantics(
          label: semanticsLabel,
          image: true,
          child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final page = PageGridLayout.pageAt(details.localPosition, size);
                if (page != null) onSelect(page);
              },
              child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Motion.of(context, Motion.reveal),
                  curve: Curves.easeInOutCubic,
                  builder: (context, reveal, _) => CustomPaint(
                      key: paintKey,
                      size: size,
                      painter: PageGridPainter(
                          done: done,
                          partial: partial,
                          selected: selected,
                          reveal: reveal,
                          palette: palette)))));
    });
  }
}
