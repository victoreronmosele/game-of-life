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
  final double _screenPadding = 8.0;
  final double _boxHeightDimension = 20;
  final Duration _interval = Duration(milliseconds: 500);

  List<Cell> _listOfCells = [];
  int _generation = 0;
  bool _isGameRunning;
  bool _minimizeGame;
  DragUpdateDetails _dragUpdateDetails;
  Timer _gameTimer;

  AnimationController _animationController;
  Animation<Color> _colorAnimation;
  final ColorTween _colorTween =
      ColorTween(begin: AppColors.hackerGreen, end: AppColors.red);

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    _colorAnimation = _colorTween.animate(_animationController);

    _isGameRunning = false;
    _minimizeGame = true;
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
    final int numberOfBoxRows =
        MediaQuery.of(context).size.height ~/ _boxHeightDimension;
    final int numberOfBoxColumns =
        MediaQuery.of(context).size.width ~/ _boxHeightDimension;

    final double halfBoxHeightDimension = _boxHeightDimension / 2;

    for (var rowIndex = 1; rowIndex < numberOfBoxRows; rowIndex++) {
      num dy = rowIndex * _boxHeightDimension;
      for (var columnIndex = 0;
          columnIndex < numberOfBoxColumns;
          columnIndex++) {
        num dx = columnIndex * _boxHeightDimension;
        Offset offset = Offset(dx, dy);

        _listOfCells.add(Cell(
            // Random().nextBool()
            // ? CellState.alive :

            CellState.dead,
            offset));
      }
    }

    setState(() {
      _generation++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.black,
        // appBar: AppBar(
        //   automaticallyImplyLeading: false,
        //   backgroundColor: AppColors.transparent,
        //   elevation: 0.0,
        //   title: Container(
        //     decoration: BoxDecoration(
        //       border: Border.all(color: AppColors.hackerGreen),
        //     ),
        //     child: Padding(
        //       padding: const EdgeInsets.all(4.0),
        //       child: Container(
        //         decoration: BoxDecoration(
        //             border: Border.all(
        //           color: AppColors.hackerGreen,
        //         )),
        //         child: Padding(
        //           padding: const EdgeInsets.all(8.0),
        //           child: Center(
        //             child: Text(
        //               _generation.toString(),
        //               style: TextStyle(color: AppColors.white),
        //             ),
        //           ),
        //         ),
        //       ),
        //     ),
        //   ),
        // ),
        body: Padding(
          padding: const EdgeInsets.all(0.0),
          child: GestureDetector(
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
                  color: AppColors.black,
                  child: RepaintBoundary(
                    child: Center(
                      child: _buildGridCells(),
                    ),
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
            foregroundColor: AppColors.white,
            mini: true,
            onPressed: _minimizeGame ? _toggleGameState : null,
            tooltip: 'Start Game',
            child: Icon(_buildPlayPauseButton()),
          ),
        ),
      ),
    );
  }

  Widget _buildGridCells() {
    List<Widget> widgetList = [];

    for (var i = 0; i < _listOfCells.length; i++) {
      Cell cell = _listOfCells.elementAt(i);

      widgetList.add(CustomPaint(
        painter: GameOfLifePainter(cell: cell, boxHeight: _boxHeightDimension),
        child: Container(),
      ));
    }

    return Stack(
      children: widgetList,
    );
  }

  IconData _buildPlayPauseButton() =>
      _isGameRunning ? Icons.pause : Icons.play_arrow;

  bool _isVerticalDragDirectionNegative() =>
      _dragUpdateDetails.delta.direction.isNegative;
}

int i = 0;

class GameOfLifePainter extends CustomPainter {
  final Cell cell;
  final double boxHeight;

  static final Paint _aliveCellPaint = Paint()
    ..color = AppColors.hackerGreen
    ..style = PaintingStyle.fill;
  static final Paint _deadCellPaint = Paint()
    ..color = AppColors.red
    ..style = PaintingStyle.stroke;

  GameOfLifePainter({@required this.cell, @required this.boxHeight});

  @override
  void paint(Canvas canvas, Size size) {
    i++;
    print(i);
    drawGrid(
      canvas: canvas,
      size: size,
    );
  }

  void drawGrid({
    @required Canvas canvas,
    @required Size size,
  }) {
    CellState currentCellState = cell.cellState;
    final paint =
        currentCellState == CellState.alive ? _aliveCellPaint : _deadCellPaint;

    Offset centerPoint = cell.point;
    Rect rect = Rect.fromCircle(center: centerPoint, radius: boxHeight);
    canvas.drawRect(rect, paint);

    if (currentCellState == CellState.dead) {
      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: 8,
      );
      final textSpan = TextSpan(
        text: i.toString(),
        style: textStyle,
      );
      final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center);

      textPainter.layout(
        minWidth: 0,
        maxWidth: size.width,
      );

      textPainter.paint(canvas, centerPoint);
    }
  }

  @override
  bool shouldRepaint(GameOfLifePainter oldDelegate) {
    return true;
  }
}
