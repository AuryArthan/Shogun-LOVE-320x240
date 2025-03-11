## Shogun ##

A simple, symmetric board game inspired by Shogi. 

![cover](https://github.com/AuryArthan/Shogun-LOVE-320x240/blob/master/assets/cover.png)

------------------------------

There are two types of pieces:

1. **Nobles**, move 1 square in any direction and can only be moved by their respective players 
   <br><img src="https://github.com/AuryArthan/Shogun-LOVE-320x240/blob/master/assets/illustrations/noble_moves.png" width="170" height="170">

2. **Pointers**, move 1 square in any direction except backward and can be moved by all players 
   <br><img src="https://github.com/AuryArthan/Shogun-LOVE-320x240/blob/master/assets/illustrations/pointer_moves.png" width="170" height="170">
   <br>When pointers move, their orientation changes 
   <br><img src="https://github.com/AuryArthan/Shogun-LOVE-320x240/blob/master/assets/illustrations/pointer_turn.png" width="170" height="122">

Pointers attack the square in front of them. Nobles cannot enter an attacked square, and when they are attacked they must move out. If they are attacked and cannot move, they are defeated. 

A player wins if their noble reaches the center of the board, or if all other players are defeated. 

Pointers cannot enter the center and can only be moved once per turn. 
