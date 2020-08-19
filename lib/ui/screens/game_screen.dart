import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:game_of_life_playground/models/cell.dart';
import 'package:game_of_life_playground/models/cell_state.dart';
import 'package:game_of_life_playground/models/rule.dart';
import 'package:game_of_life_playground/ui/data/app_colors.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final double _screenPadding = 8.0;
  final double _boxHeightDimension = 20.0;
  final Duration _interval = Duration(milliseconds: 500);

  ///Defaults to true
  final ValueNotifier<bool> _minimizeGame = ValueNotifier(true);

  ///Defaults to false
  final ValueNotifier<bool> _isGameRunning = ValueNotifier(false);

  ///Defaults to 0
  final ValueNotifier<int> _generation = ValueNotifier(0);

  ///Defaults to []
  final ValueNotifier<List<Cell>> _listOfCells = ValueNotifier([]);

  DragUpdateDetails _dragUpdateDetails;
  Timer _gameTimer;

  final ColorTween _colorTween =
      ColorTween(begin: AppColors.hackerGreen, end: AppColors.red);
  AnimationController _colorAnimationController;
  Animation<Color> _colorAnimation;

  final Tween<double> _scaleTween = Tween<double>(begin: 0.8, end: 1.0);
  AnimationController _scaleAnimationController;
  Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _colorAnimationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    _colorAnimation = _colorTween.animate(_colorAnimationController);

    _scaleAnimationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    _scaleAnimation = _scaleTween.animate(_scaleAnimationController);
    _scaleAnimation.addStatusListener((AnimationStatus animationStatus) {
      if (animationStatus == AnimationStatus.completed) {
        _minimizeGame.value = false;
      }

      if (animationStatus == AnimationStatus.dismissed) {
        _minimizeGame.value = true;
      }
    });

    _scaleAnimationController.reverse();

    WidgetsBinding.instance.addPostFrameCallback(getListOfCells);
  }

  Future<void> _toggleGameState() async {
    if (_isGameRunning.value) {
      _gameTimer?.cancel();
      await _colorAnimationController.reverse();
      _isGameRunning.value = false;
    } else {
      if (_gameTimer == null || !_gameTimer.isActive) {
        _gameTimer =
            Timer.periodic(_interval, (Timer t) => _runThroughGeneration());
      }

      await _colorAnimationController.forward();
      _isGameRunning.value = true;
    }
  }

  _runThroughGeneration() {
    _listOfCells.value = _listOfCells.value.map((cell) {
      final List<Offset> listOfNeighboringPoints =
          cell.getNeighborPoints(_boxHeightDimension);

      final List<Cell> listOfNeigboringCells = _listOfCells.value.where((cell) {
        return listOfNeighboringPoints.contains(cell.point);
      }).toList();

      cell.cellState = _getNewCellState(
          cell: cell, listOfNeighboringCells: listOfNeigboringCells);

      return cell;
    }).toList();

    _generation.value++;
  }

  CellState _getNewCellState(
      {@required Cell cell, @required List<Cell> listOfNeighboringCells}) {
    final int numberOfLivingNeighbors = listOfNeighboringCells
        .where((_) => _.cellState == CellState.alive)
        .length;

    final CellState newCellState = Rule().getNewCellState(
        initialCellState: cell.cellState,
        numberOfLivingNeighbors: numberOfLivingNeighbors);

    return newCellState;
  }

  void getListOfCells(_) {
    final int numberOfBoxRows =
        MediaQuery.of(context).size.height ~/ _boxHeightDimension;
    final int numberOfBoxColumns =
        MediaQuery.of(context).size.width ~/ _boxHeightDimension;

    for (var rowIndex = 1; rowIndex < numberOfBoxRows; rowIndex++) {
      num dy = rowIndex * _boxHeightDimension;
      for (var columnIndex = 0;
          columnIndex < numberOfBoxColumns;
          columnIndex++) {
        num dx = columnIndex * _boxHeightDimension;
        Offset offset = Offset(dx, dy);

        _listOfCells.value = [
          ..._listOfCells.value,
          Cell(Random().nextBool() ? CellState.alive : CellState.dead, offset)
        ];
      }
    }

    _generation.value++;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.transparent,
          elevation: 0.0,
          title: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.hackerGreen),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(
                  color: AppColors.hackerGreen,
                )),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: ValueListenableBuilder(
                      valueListenable: _generation,
                      builder: (BuildContext context, int generationListenable,
                          Widget child) {
                        return Text(
                          generationListenable.toString(),
                          style: TextStyle(color: AppColors.white),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(0.0),
          child: GestureDetector(
            onVerticalDragUpdate: (DragUpdateDetails dragUpdateDetails) {
              _dragUpdateDetails = dragUpdateDetails;
            },
            onVerticalDragEnd: (DragEndDetails dragEndDetails) {
              if (_isVerticalDragDirectionNegative()) {
                _scaleAnimationController.reverse();
              } else {
                _scaleAnimationController.forward();
              }
            },
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (BuildContext context, child) =>
                  Transform.scale(scale: _scaleAnimation.value, child: child),
              child: Container(
                color: _colorAnimation.value.withOpacity(0.2),
                child: Container(
                  color: AppColors.black,
                  child: RepaintBoundary(
                    child: Center(
                      child: ValueListenableBuilder(
                          valueListenable: _listOfCells,
                          builder: (BuildContext buildContext,
                              List<Cell> listOfCellsListenable, Widget child) {
                            return _buildGridCells(
                                listOfCells: listOfCellsListenable);
                          }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: ValueListenableBuilder(
          builder: (BuildContext context, bool gameMinimizedStateListenable,
              Widget child) {
            return AnimatedOpacity(
              duration: Duration(seconds: 1),
              opacity: gameMinimizedStateListenable ? 1.0 : 0.0,
              child: FloatingActionButton(
                backgroundColor: _colorAnimation.value,
                foregroundColor: AppColors.white,
                mini: true,
                onPressed:
                    gameMinimizedStateListenable ? _toggleGameState : null,
                tooltip: 'Start Game',
                child: ValueListenableBuilder(
                    valueListenable: _isGameRunning,
                    builder: (_, gameRunningStateListenable, ___) => Icon(
                        _buildPlayPauseButton(
                            isGameRunning: gameRunningStateListenable))),
              ),
            );
          },
          valueListenable: _minimizeGame,
        ),
      ),
    );
  }

  Widget _buildGridCells({@required List<Cell> listOfCells}) {
    List<Widget> widgetList = [];

    for (var i = 0; i < listOfCells.length; i++) {
      Cell cell = listOfCells.elementAt(i);

      widgetList.add(
        CustomPaint(
          key: ValueKey(i),
          painter: GameOfLifePainter(
              key: ValueKey('00'), cell: cell, boxHeight: _boxHeightDimension),
          child: Container(),
        ),
      );
    }

    return Stack(
      children: widgetList,
    );
  }

  IconData _buildPlayPauseButton({@required bool isGameRunning}) =>
      isGameRunning ? Icons.pause : Icons.play_arrow;

  bool _isVerticalDragDirectionNegative() =>
      _dragUpdateDetails.delta.direction.isNegative;
}

int i = 0;

@immutable
class GameOfLifePainter extends CustomPainter {
  final Cell cell;
  final double boxHeight;

  static final Paint _aliveCellPaint = Paint()
    ..color = AppColors.hackerGreen
    ..style = PaintingStyle.fill;
  static final Paint _deadCellPaint = Paint()
    ..color = AppColors.red
    ..style = PaintingStyle.stroke;

  const GameOfLifePainter(
      {@required Key key, @required this.cell, @required this.boxHeight});

  @override
  void paint(Canvas canvas, Size size) {
    i++;
    _drawBox(canvas: canvas, size: size, cell: cell);
  }

  void _drawBox(
      {@required Canvas canvas, @required Size size, @required Cell cell}) {
    final CellState currentCellState = cell.cellState;
    final paint =
        currentCellState == CellState.alive ? _aliveCellPaint : _deadCellPaint;

    final Offset cellPoint = cell.point;
    final Offset centerPoint = Offset(cellPoint.dx, cellPoint.dy);

    Rect rect = Rect.fromCircle(center: centerPoint, radius: boxHeight / 2);
    canvas.drawRect(rect, paint);

    if (currentCellState == CellState.dead) {
      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: 8,
      );
      final textSpan = TextSpan(
        text: '💀',
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

      Offset textOffset = Offset(
          centerPoint.dx - boxHeight / 4, centerPoint.dy - boxHeight / 4);

      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(GameOfLifePainter oldDelegate) {
    print(oldDelegate.cell.point == cell.point);

    return true;
  }
}
