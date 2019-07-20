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
  List<bool> listOfFilledStates =
      List.generate(1000, (index) => Random().nextBool());

  void _startGame() {
    print('_startGame');
    setState(() {
      listOfFilledStates.shuffle();
    });
  }

  @override
  Widget build(BuildContext context) {
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
          child: CustomPaint(
            painter: GameOfLifePainter(
                padding: 2 * screenPadding, filledStates: listOfFilledStates),
            child: Container(),
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
  final List<bool> filledStates;

  GameOfLifePainter({@required this.padding, @required this.filledStates});

  @override
  void paint(Canvas canvas, Size size) {
    print('width size is ${size.width}');

    final int numberOfBoxRows = 20;
    //TODO Account for top and bottom padding to calculate height
    final boxHeightDimension = size.height / numberOfBoxRows;
    final int numberOfBoxColumns = (size.width - padding) ~/ boxHeightDimension;

    print('number of box columns $numberOfBoxColumns');

    List<Offset> listOfPoints = [];

    Offset offset = Offset.zero;

    for (var i = 0; i < numberOfBoxRows; i++) {
      offset = Offset(0, boxHeightDimension * i);

      for (var i = 0; i < numberOfBoxColumns; i++) {
        print(i);
        listOfPoints.add(offset);

        var newOffsetDx = offset.dx + boxHeightDimension;
        var newOffsetDy = i.isEven
            ? offset.dy + boxHeightDimension
            : offset.dy - boxHeightDimension;
        offset = Offset(newOffsetDx, newOffsetDy);
        listOfPoints.add(offset);
      }
    }

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < listOfPoints.length; i++) {
      PaintingStyle currentPaintingStyle = filledStates.elementAt(i) == true
          ? PaintingStyle.fill
          : PaintingStyle.stroke;
      if (i + 1 >= listOfPoints.length) {
        break;
      } else {
        var firstBoxPoint = listOfPoints.elementAt(i);
        var secondBoxPoint = listOfPoints.elementAt(i + 1);

        if (firstBoxPoint == secondBoxPoint) continue;

        canvas.drawRect(Rect.fromPoints(firstBoxPoint, secondBoxPoint),
            paint..style = currentPaintingStyle);
      }
    }
  }

  @override
  bool shouldRepaint(GameOfLifePainter oldDelegate) => false;
}
