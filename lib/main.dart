import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:game_of_life_playground/data/app_strings.dart';
import 'package:game_of_life_playground/ui/screens/game_screen.dart';

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
