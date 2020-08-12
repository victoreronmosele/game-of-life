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
  final String title = 'Game of Life Playground';
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
  final String title;

  GameOfLifePlayground({Key key, this.title}) : super(key: key);

  @override
  _GameOfLifePlaygroundState createState() => _GameOfLifePlaygroundState();
}

class _GameOfLifePlaygroundState extends State<GameOfLifePlayground>
    with SingleTickerProviderStateMixin {
  GlobalKey _customPaintKey = GlobalKey();
  final double _screenPadding = 10.0;
  final int _numberOfBoxRows = 50;
  Size _customPaintSize;
  List<Cell> _listOfCells = [];
  double _boxHeightDimension;
  int generation = 0;
  Duration interval = Duration(milliseconds: 500);
  bool _isGameRunning;
  bool _minimizeGame;
  DragUpdateDetails _dragUpdateDetails;

  AnimationController _animationController;
  Animation<Color> _colorAnimation;
  final ColorTween _colorTween =
      ColorTween(begin: Colors.green, end: Colors.red);

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    _colorAnimation = _colorTween.animate(_animationController);

    _isGameRunning = false;
    _minimizeGame = true;
    WidgetsBinding.instance.addPostFrameCallback(_getCustomPaintSize);
    WidgetsBinding.instance.addPostFrameCallback(getListOfCells);
  }

  void _startGame() {
    if (_isGameRunning) {
      _animationController.reverse();
      setState(() {
        _isGameRunning = false;
      });
    } else {
      _animationController.forward();
      setState(() {
        _isGameRunning = true;
      });

      Timer.periodic(interval, (Timer t) => _runThroughGeneration());
    }
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
        body: GestureDetector(
          onVerticalDragUpdate: (DragUpdateDetails dragUpdateDetails) {
            _dragUpdateDetails = dragUpdateDetails;
          },
          onVerticalDragEnd: (DragEndDetails dragEndDetails) {
            if (_isVerticalDragDirectionNegative()) {
              _minimizeGame = true;
            } else {
              _minimizeGame = false;
            }

            setState(() {});
          },
          onVerticalDragStart: (DragStartDetails dragStartDetails) {},
          onVerticalDragCancel: () {},
          onVerticalDragDown: (_) {},
          child: Transform.scale(
            scale: _minimizeGame ? 0.8 : 1.0,
            child: Container(
              color: _colorAnimation.value.withOpacity(0.2),
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
          ),
        ),
        floatingActionButton: AnimatedOpacity(
          duration: Duration(seconds: 1),
          opacity: _minimizeGame ? 1.0 : 0.0,
          child: FloatingActionButton(
            backgroundColor: _colorAnimation.value,
            foregroundColor: Colors.white,
            mini: true,
            onPressed: _startGame,
            tooltip: 'Start Game',
            child: Icon(Icons.play_arrow),
          ),
        ),
      ),
    );
  }

  bool _isVerticalDragDirectionNegative() =>
      _dragUpdateDetails.delta.direction.isNegative;
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
        ..color = currentCell.cellState == CellState.alive
            ? AppColors.hackerGreen
            : Colors.red
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
