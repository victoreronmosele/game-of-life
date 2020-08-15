import 'package:flutter/material.dart';
import 'package:game_of_life_playground/data/app_strings.dart';
import 'package:game_of_life_playground/ui/data/app_colors.dart';

class LoadingScreen extends StatefulWidget {
  LoadingScreen({
    Key key,
  }) : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  GlobalKey _textKey;

  AnimationController _slideController;

  Duration _slideDuration;

  Color _boxBackgroundColor;

  TextStyle _baseTextStyle;
  TextStyle _strokeTextStyle;

  String _loadingText;

  @override
  void initState() {
    super.initState();

    _textKey = GlobalKey();
    _slideDuration = const Duration(milliseconds: 4000);
    _slideController =
        AnimationController(vsync: this, duration: _slideDuration);
    _boxBackgroundColor = Colors.black;
    _baseTextStyle = TextStyle(fontSize: 48, fontWeight: FontWeight.bold);
    _strokeTextStyle = _baseTextStyle.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.green,
    );
    _loadingText = AppStrings.loadingMessage.toUpperCase();

    _slideController.addListener(() {
      if (_slideController.isCompleted) {
        _slideController.reverse();
      } else if (_slideController.isDismissed) {
        _slideController.forward();
      }
    });

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController?.stop();
    _slideController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SizedBox(
        height: screenHeight,
        width: screenWidth,
        child: Stack(
          children: <Widget>[
            SizedBox(
              height: screenHeight,
              width: screenWidth,
              child: AnimatedBuilder(
                animation: _slideController,
                builder: (BuildContext context, Widget child) {
                  return CustomPaint(
                    painter: SlidePainter(
                        slideAnimation: _slideController, textKey: _textKey),
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
              child: Center(
                child: Text(
                  _loadingText,
                  key: _textKey,
                  style: _baseTextStyle,
                ),
              ),
            ),
            Center(
              child: Text(
                _loadingText,
                style: _strokeTextStyle,
              ),
            )
          ],
        ),
      ),),
    );
  }
}

class SlidePainter extends CustomPainter {
  final Animation<double> slideAnimation;
  final GlobalKey textKey;

  SlidePainter({@required this.slideAnimation, @required this.textKey});

  @override
  void paint(Canvas canvas, Size size) {
    final double canvasWidth = size.width;
    final double canvasHeight = size.height;

    final Paint wavePaint = Paint()
      ..color = AppColors.green
      ..style = PaintingStyle.fill;

    final RenderBox _widgetRenderBox = textKey.currentContext.findRenderObject();
    final double _renderedWidgetHeight = _widgetRenderBox.size.height;
    final double _renderedWidgetWidth = _widgetRenderBox.size.width;

    final double widgetLeftMargin = (canvasWidth - _renderedWidgetWidth) / 2;
    final double widgetTopMargin = (canvasHeight - _renderedWidgetHeight) / 2;

    final Offset widgetOffset = Offset(widgetLeftMargin, widgetTopMargin);
    final Size widgetSize = Size(
        _renderedWidgetWidth * slideAnimation.value, _renderedWidgetHeight);

    final Rect rect = widgetOffset & widgetSize;

    canvas.drawRect(rect, wavePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
