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
  void _startGame() {
    print('_startGame');
    // setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    print('main build');

    double screenPadding = 10.0;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
        ),
        body: Padding(
          padding: EdgeInsets.all(screenPadding),
          child: Container(
            color: Colors.black,
            child: CustomPaint(
              painter: GameOfLifePainter(
                padding: 2 * screenPadding,
              ),
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

  GameOfLifePainter({
    @required this.padding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    print('width size is ${size.width}');

    final int numberOfBoxRows = 50;
    //TODO Account for top and bottom padding to calculate height
    final boxHeightDimension = size.height / numberOfBoxRows;
    final radius = boxHeightDimension / 2;
    final int numberOfBoxColumns = (size.width - padding) ~/ boxHeightDimension;

    print('number of box columns $numberOfBoxColumns');

    List<Cell> listOfCells = [];

    Offset offset = Offset(radius, radius);

    for (var i = 1; i < numberOfBoxRows; i++) {
      offset = Offset(radius, i * boxHeightDimension);

      for (var i = 0; i < numberOfBoxColumns; i++) {
        print(offset);
        var newOffsetDx = offset.dx + boxHeightDimension;
        var newOffsetDy = offset.dy;
        offset = Offset(newOffsetDx, newOffsetDy);
        listOfCells.add(Cell(
            Random().nextInt(3).isEven ? CellState.alive : CellState.dead,
            offset));
      }
    }

    for (var i = 0; i < listOfCells.length; i++) {
      final paint = Paint()
        ..color = Colors.blue
        ..style = listOfCells.elementAt(i).cellState == CellState.alive
            ? PaintingStyle.fill
            : PaintingStyle.stroke;

      if (i + 1 >= listOfCells.length) {
        break;
      } else {
        Offset firstBoxPoint = listOfCells.elementAt(i).point;
        Offset secondBoxPoint = listOfCells.elementAt(i + 1).point;

        if (firstBoxPoint == secondBoxPoint) continue;

// canvas.
        canvas.drawRect(
            Rect.fromCircle(
              center: firstBoxPoint,
              radius: boxHeightDimension - padding,
            ),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(GameOfLifePainter oldDelegate) => false;
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
