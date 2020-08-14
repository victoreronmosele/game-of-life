import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_of_life_playground/data/app_strings.dart';
import 'package:game_of_life_playground/ui/data/app_colors.dart';

GlobalKey _textKey;

class LoadingScreen extends StatefulWidget {
  LoadingScreen({
    Key key,
  }) : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  AnimationController _slideController, _loadController;
  Duration _slideDuration, _loadDuration;

  Color _boxBackgroundColor, _waveColor;

  TextStyle _textStyle;

  @override
  void initState() {
    super.initState();

    _textKey = GlobalKey();

    _slideDuration = const Duration(milliseconds: 4000);

    _slideController =
        AnimationController(vsync: this, duration: _slideDuration);

    _loadController = AnimationController(vsync: this, duration: _loadDuration);

    _boxBackgroundColor = Colors.black;
    _waveColor = AppColors.green;

    _textStyle = TextStyle(fontSize: 48, fontWeight: FontWeight.bold);

    _slideController.forward();
    _slideController.addListener(() {
      if (_slideController.isCompleted) {
        _slideController.reverse();
      } else if (_slideController.isDismissed) {
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController?.stop();
    _slideController?.dispose();
    _loadController?.stop();
    _loadController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: AnimatedBuilder(
              animation: _slideController,
              builder: (BuildContext context, Widget child) {
                return CustomPaint(
                  painter: WavePainter(
                      slideController: _slideController, waveColor: _waveColor),
                );
              },
            ),
          ),
          ShaderMask(
            blendMode: BlendMode.srcOut,
            shaderCallback: (bounds) => LinearGradient(colors: [
              _boxBackgroundColor,
            ], stops: [
              0.0
            ]).createShader(bounds),
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Text(
                  AppStrings.loadingMessage.toUpperCase(),
                  key: _textKey,
                  style: _textStyle,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              AppStrings.loadingMessage.toUpperCase(),
              style: _textStyle.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1
                  ..color = AppColors.green,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  Animation<double> slideController;

  Color waveColor;

  WavePainter({@required this.slideController, @required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    double width = (size.width != null) ? size.width : 200;
    double height = (size.height != null) ? size.height : 200;

    Paint wavePaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    RenderBox textBox = _textKey.currentContext.findRenderObject();

    double _textHeight = textBox.size.height;
    double _textWidth = textBox.size.width;

    Rect rect = Offset((width - _textWidth) / 2, (height - _textHeight) / 2) &
        Size(_textWidth * slideController.value, _textHeight);
    canvas.drawRect(rect, wavePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
