import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_of_life_playground/models/cell.dart';
import 'package:game_of_life_playground/models/cell_state.dart';
import 'package:game_of_life_playground/models/rule.dart';
import 'package:game_of_life_playground/ui/data/app_colors.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final double _screenPadding = 10.0;
  final int _numberOfBoxRows = 50;
  final Duration _interval = Duration(milliseconds: 500);

  GlobalKey _customPaintKey = GlobalKey();
  Size _customPaintSize;
  List<Cell> _listOfCells = [];
  double _boxHeightDimension;
  int _generation = 0;
  bool _isGameRunning;
  bool _minimizeGame;
  DragUpdateDetails _dragUpdateDetails;
  Timer _gameTimer;

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

  Future<void> _toggleGameState() async {
    if (_isGameRunning) {
      _gameTimer?.cancel();

      await _animationController.reverse();

      setState(() {
        _isGameRunning = false;
      });
    } else {
      if (_gameTimer == null || !_gameTimer.isActive) {
        _gameTimer =
            Timer.periodic(_interval, (Timer t) => _runThroughGeneration());
      }

      await _animationController.forward();

      setState(() {
        _isGameRunning = true;
      });
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
      _generation++;
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
      _generation++;
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
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          actions: <Widget>[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  _generation.toString(),
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
          child: Transform.scale(
            scale: _minimizeGame ? 0.8 : 1.0,
            child: Container(
              color: _colorAnimation.value.withOpacity(0.2),
              child: Container(
                color: Colors.black,
                child: RepaintBoundary(
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
        ),
        floatingActionButton: AnimatedOpacity(
          duration: Duration(seconds: 1),
          opacity: _minimizeGame ? 1.0 : 0.0,
          child: FloatingActionButton(
            backgroundColor: _colorAnimation.value,
            foregroundColor: Colors.white,
            mini: true,
            onPressed: _minimizeGame ? _toggleGameState : null,
            tooltip: 'Start Game',
            child: Icon(_buildPlayPauseButton()),
          ),
        ),
      ),
    );
  }

  IconData _buildPlayPauseButton() =>
      _isGameRunning ? Icons.pause : Icons.play_arrow;

  bool _isVerticalDragDirectionNegative() =>
      _dragUpdateDetails.delta.direction.isNegative;
}

class GameOfLifePainter extends CustomPainter {
  final double padding;
  final int numberOfBoxRows;
  final List<Cell> listOfCells;
  final boxHeightDimension;

  static final Paint _aliveCellPaint = Paint()
    ..color = AppColors.hackerGreen
    ..style = PaintingStyle.fill;
  static final Paint _deadCellPaint = Paint()
    ..color = AppColors.red
    ..style = PaintingStyle.stroke;

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
      final paint = currentCell.cellState == CellState.alive
          ? _aliveCellPaint
          : _deadCellPaint;

      Offset centerPoint = currentCell.point;
      Rect rect = Rect.fromCircle(
          center: centerPoint, radius: boxHeightDimension - padding);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(GameOfLifePainter oldDelegate) {
    return true;
  }
}
