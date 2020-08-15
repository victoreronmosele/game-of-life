import 'dart:ui';

import 'package:game_of_life_playground/models/cell_state.dart';

class Cell {
  CellState cellState;
  Offset point;

  Cell(this.cellState, this.point);

  Offset getNewPoint(double x, double y) {
    double neighbourHorizontalPoint = point.dx + x;
    double neighbourVerticalPoint = point.dy + y;

    return Offset(neighbourHorizontalPoint, neighbourVerticalPoint);
  }

  List<Offset> getNeighborPoints(double boxHeightDimension) {
    List<Offset> neighborPoints = [
      getNewPoint(-(boxHeightDimension), -(boxHeightDimension)),
      getNewPoint(-(boxHeightDimension), 0),
      getNewPoint(-(boxHeightDimension), boxHeightDimension),
      getNewPoint(0, -(boxHeightDimension)),
      getNewPoint(0, boxHeightDimension),
      getNewPoint(boxHeightDimension, -(boxHeightDimension)),
      getNewPoint(boxHeightDimension, 0),
      getNewPoint(boxHeightDimension, boxHeightDimension),
    ];

    return neighborPoints;
  }
}
