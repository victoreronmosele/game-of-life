import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:game_of_life_playground/data/app_strings.dart';
import 'package:game_of_life_playground/ui/screens/game_screen.dart';
import 'package:game_of_life_playground/ui/screens/loading_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameScreen(),
    );
  }
}

class BaseScreen extends StatefulWidget {
  const BaseScreen({
    Key key,
  }) : super(key: key);

  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed((Duration(milliseconds: 4250)), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GameScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoadingScreen();
  }
}
