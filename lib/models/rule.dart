import 'package:game_of_life_playground/models/cell_state.dart';
import 'package:meta/meta.dart';

class Rule {
  CellState getNewCellState(
      {@required CellState initialCellState,
      @required int numberOfLivingNeighbors}) {


        
    CellState newCellState;

    if (numberOfLivingNeighbors == 3) {
      newCellState = CellState.alive;
    } else if (numberOfLivingNeighbors != 2) {
      newCellState = CellState.dead;
    } else {
      newCellState = initialCellState;
    }

    return newCellState;
  }
}
