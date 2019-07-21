import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameOfLifePlayground(title: 'Game of Life Playground'),
    );
  }
}

class GameOfLifePlayground extends StatefulWidget {
  GameOfLifePlayground({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _GameOfLifePlaygroundState createState() => _GameOfLifePlaygroundState();
}

class _GameOfLifePlaygroundState extends State<GameOfLifePlayground> {
  GlobalKey _customPaintKey = GlobalKey();
  final double _screenPadding = 10.0;
  final int _numberOfBoxRows = 50;
  Size _customPaintSize;
  List<Cell> _listOfCells = [];
  double _boxHeightDimension;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_getCustomPaintSize);
    WidgetsBinding.instance.addPostFrameCallback(getListOfCells);
  }

  void _startGame() {
    print('_startGame');
    // _checkForCellStates();
    _checkForNeighboringCellStates();
  }

  _checkForNeighboringCellStates() {
    _listOfCells.forEach((cell) {
      int index = _listOfCells.indexOf(cell);

      List<Offset> listOfNeighboringPoints =
          cell.getNeighborPoints(_boxHeightDimension);

      List<Cell> listOfNeigboringCells = _listOfCells.where((cell) {
        return listOfNeighboringPoints.contains(cell.point);
      }).toList();

      _reactToNeighbors(cell, listOfNeigboringCells);
    });
  }

  _reactToNeighbors(Cell cell, List<Cell> listOfNeighboringCells) {
    int numberOfLivingNeighbors = listOfNeighboringCells
        .where((_) => _.cellState == CellState.alive)
        .length;
    print(
        'Cell initial Status ====> ${(cell.cellState).toString().toUpperCase()}');

    print('Living neighbors are ====> $numberOfLivingNeighbors');

    CellState newCellState = Rule().getNewCellState(
        initialCellState: cell.cellState,
        numberOfLivingNeighbors: numberOfLivingNeighbors);

    cell.cellState = newCellState;
    print('cellState = ${cell.cellState} ');

    print('');
  }

  _checkForCellStates() {
    _listOfCells.forEach((cell) {
      int index = _listOfCells.indexOf(cell);
      print(index.toString() + cell.cellState.toString());
    });
  }

  void getListOfCells(_) {
    //TODO Account for top and bottom padding to calculate height
    setState(() {
      _boxHeightDimension = _customPaintSize.height / _numberOfBoxRows;
    });

    final radius = _boxHeightDimension / 2;
    final int numberOfBoxColumns =
        (_customPaintSize.width - _screenPadding) ~/ _boxHeightDimension;

    Offset offset = Offset(radius, radius);

    for (var i = 1; i < _numberOfBoxRows; i++) {
      offset = Offset(radius, i * _boxHeightDimension);

      for (var i = 0; i < numberOfBoxColumns; i++) {
        var newOffsetDx = offset.dx + _boxHeightDimension;
        var newOffsetDy = offset.dy;
        offset = Offset(newOffsetDx, newOffsetDy);
        _listOfCells.add(Cell(
            Random().nextInt(3).isEven ? CellState.alive : CellState.dead,
            offset));
      }
    }

    print(_listOfCells.length.toString() + 'cells');
  }

  _getCustomPaintSize(_) {
    final RenderBox containerRenderBox =
        _customPaintKey.currentContext.findRenderObject();
    _customPaintSize = containerRenderBox.size;
    print('_customPaintSize => $_customPaintSize');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            widget.title,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
        ),
        body: Padding(
          padding: EdgeInsets.all(_screenPadding),
          child: Container(
            color: Colors.black,
            child: CustomPaint(
              key: _customPaintKey,
              painter: GameOfLifePainter(
                  padding: 2 * _screenPadding,
                  numberOfBoxRows: _numberOfBoxRows,
                  listOfCells: _listOfCells,
                  boxHeightDimension: _boxHeightDimension),
              child: Container(),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          onPressed: _startGame,
          tooltip: 'Start Game',
          child: Icon(Icons.play_arrow),
        ),
      ),
    );
  }
}

class GameOfLifePainter extends CustomPainter {
  final double padding;
  final int numberOfBoxRows;
  final List<Cell> listOfCells;
  final boxHeightDimension;

  GameOfLifePainter(
      {@required this.padding,
      @required this.numberOfBoxRows,
      @required this.listOfCells,
      @required this.boxHeightDimension});

  @override
  void paint(Canvas canvas, Size size) {
    drawGrid(listOfCells, boxHeightDimension, canvas);
  }

  void drawGrid(
      List<Cell> listOfCells, double boxHeightDimension, Canvas canvas) {
    for (var i = 0; i < listOfCells.length; i++) {
      Cell currentCell = listOfCells.elementAt(i);
      final paint = Paint()
        ..color = Colors.blue
        ..style = currentCell.cellState == CellState.alive
            ? PaintingStyle.fill
            : PaintingStyle.stroke;

      Offset centerPoint = currentCell.point;
      Rect rect = Rect.fromCircle(
          center: centerPoint, radius: boxHeightDimension - padding);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(GameOfLifePainter oldDelegate) => true;
}

enum CellState { alive, dead }

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

class Rule {
  CellState getNewCellState(
      {@required CellState initialCellState,
      @required int numberOfLivingNeighbors}) {
    CellState newCellState;

    if (numberOfLivingNeighbors == 3) {
      newCellState = CellState.alive;
    } else if (numberOfLivingNeighbors != 2) {
      newCellState = CellState.dead;
    } else {
      newCellState = initialCellState;
    }

    return newCellState;
  }
}
