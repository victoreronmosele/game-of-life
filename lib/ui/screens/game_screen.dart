import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:game_of_life_playground/models/cell.dart';
import 'package:game_of_life_playground/models/cell_state.dart';
import 'package:game_of_life_playground/models/rule.dart';
import 'package:game_of_life_playground/ui/data/app_colors.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
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
        _gameTimer = Timer.periodic(_interval, (Timer t) async {
          return await _runThroughGeneration();
        });
      }

      await _colorAnimationController.forward();
      _isGameRunning.value = true;
    }
  }

  List<Cell> getUpdatedListOfCells(List<Cell> previousListOfCells) {
    List<Cell> updatedListOfCells = previousListOfCells.map((cell) {
      final List<Offset> listOfNeighboringPoints =
          cell.getNeighborPoints(_boxHeightDimension);

      final List<Cell> listOfNeigboringCells =
          previousListOfCells.where((cell) {
        return listOfNeighboringPoints.contains(cell.point);
      }).toList();

      cell.cellState = _getNewCellState(
          cell: cell, listOfNeighboringCells: listOfNeigboringCells);

      return cell;
    }).toList();

    return updatedListOfCells;
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

  _runThroughGeneration() async {
    _listOfCells.value = await SchedulerBinding.instance.scheduleTask(
        (() => getUpdatedListOfCells(_listOfCells.value)), Priority.touch);
    _generation.value++;
  }

  void getListOfCells(_) {
    final int numberOfBoxRows = _gridHeight ~/ _boxHeightDimension;
    final int numberOfBoxColumns = _gridWidth ~/ _boxHeightDimension;

    final double extraHorizontalSpace = _gridWidth % _boxHeightDimension;
    final double extraHorizontalSpacePerBox = extraHorizontalSpace / numberOfBoxColumns;
    final double halfBoxHeight = _boxHeightDimension / 2;

    for (var rowIndex = 1; rowIndex < numberOfBoxRows; rowIndex++) {
      num dy = rowIndex * _boxHeightDimension;
      for (var columnIndex = 0;
          columnIndex < numberOfBoxColumns;
          columnIndex++) {
        num dx = (columnIndex * _boxHeightDimension);
        Offset offset = Offset(dx + halfBoxHeight + extraHorizontalSpacePerBox, dy - halfBoxHeight);

        _listOfCells.value = [
          ..._listOfCells.value,
          Cell(Random().nextBool() ? CellState.alive : CellState.dead, offset)
        ];
      }
    }

    _generation.value++;
  }

  double get _screenHeight =>
      MediaQuery.of(context).removePadding(removeTop: true).size.height;
  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _optionBarHeight => _screenHeight * 0.10;
  double get _gridHeight => _screenHeight - (_optionBarHeight * 2);
  double get _gridWidth => _screenWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Column(
          children: [
            _buildGenerationCountStatusBar(),
            Expanded(
              child: _buildGrid(),
            ),
            _buildStartStopButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStartStopButton() {
    return SizedBox(
      height: _optionBarHeight,
      child: Container(
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
            child: InkWell(
              onTap: _toggleGameState,
              child: Center(
                child: ValueListenableBuilder(
                  valueListenable: _isGameRunning,
                  builder: (_, gameRunningStateListenable, ___) => Text(
                    gameRunningStateListenable ? 'Run' : 'Start',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Center(
      child: RepaintBoundary(
        child: Center(
          child: ValueListenableBuilder(
              valueListenable: _listOfCells,
              builder: (BuildContext buildContext,
                  List<Cell> listOfCellsListenable, Widget child) {
                if (listOfCellsListenable.isEmpty) {
                  return CircularProgressIndicator();
                }
                return _buildGridCells(
                    listOfCells: listOfCellsListenable,
                    gridHeight: _gridHeight);
              }),
        ),
      ),
    );
  }

  Widget _buildGenerationCountStatusBar() {
    return SizedBox(
      height: _optionBarHeight,
      child: Container(
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
    );
  }

  List<Widget> _getCellWidgetList({@required List<Cell> listOfCells}) {
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

    return widgetList;
  }

  Widget _buildGridCells(
      {@required List<Cell> listOfCells, @required double gridHeight}) {
    List<Widget> widgetList = _getCellWidgetList(listOfCells: listOfCells);

    return Stack(
      children: widgetList,
    );
  }
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
    final Offset centerPoint =
        Offset(cellPoint.dx, cellPoint.dy );
    final double halfBoxHeight = boxHeight / 2;

    Rect rect = Rect.fromCircle(center: centerPoint, radius: halfBoxHeight);
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
    return true;
  }
}
