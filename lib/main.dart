import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:game_of_life_playground/ui/screens/loading_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final String title = 'Game of Life Playground';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: LoadingScreen(),
        ),
      ),
      // LoadingScreen(),
      // GameScreen(title: title),
    );
  }
}
