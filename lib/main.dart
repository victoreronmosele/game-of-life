import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:game_of_life_playground/cell.dart';
import 'package:game_of_life_playground/cell_state.dart';
import 'package:game_of_life_playground/data/app_colors.dart';
import 'package:game_of_life_playground/rule.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  String title = 'Game of Life Playground';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameOfLifePlayground(title: title),
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
  int generation = 0;
  Duration interval;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_getCustomPaintSize);
    WidgetsBinding.instance.addPostFrameCallback(getListOfCells);
  }

  void _startGame() {
    interval = Duration(milliseconds: 500);
    Timer.periodic(interval, (Timer t) => _runThroughGeneration());
  }

  _runThroughGeneration() {
    _listOfCells.forEach((cell) {
      List<Offset> listOfNeighboringPoints =
          cell.getNeighborPoints(_boxHeightDimension);

      List<Cell> listOfNeigboringCells = _listOfCells.where((cell) {
        return listOfNeighboringPoints.contains(cell.point);
      }).toList();

      _reactToNeighbors(cell, listOfNeigboringCells);
    });

    setState(() {
      generation++;
    });
  }

  _reactToNeighbors(Cell cell, List<Cell> listOfNeighboringCells) {
    int numberOfLivingNeighbors = listOfNeighboringCells
        .where((_) => _.cellState == CellState.alive)
        .length;

    CellState newCellState = Rule().getNewCellState(
        initialCellState: cell.cellState,
        numberOfLivingNeighbors: numberOfLivingNeighbors);

    cell.cellState = newCellState;
  }

  void getListOfCells(_) {
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
            Random().nextBool() ? CellState.alive : CellState.dead, offset));
      }
    }

    setState(() {
      generation++;
    });
  }

  _getCustomPaintSize(_) {
    final RenderBox containerRenderBox =
        _customPaintKey.currentContext.findRenderObject();
    _customPaintSize = containerRenderBox.size;
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
          actions: <Widget>[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  generation.toString(),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
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
          mini: true,
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
        ..color = AppColors.hackerGreen
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
