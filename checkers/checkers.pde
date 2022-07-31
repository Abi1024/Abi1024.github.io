//CHECKERS, by Abiyaz Chowdhury, Version 1.01, 9/22/2015
//global game variables
//return flight go to next to: 26DE, 49DE
import java.util.*;
int[] board = new int[64];
int turn = 1; //white's turn
int edit_mode = 0;  //0 = game mode, 1 = edit board
int[] user_move = {-1, -1};
ArrayList<ArrayList<Integer>> current_legal_moves = new ArrayList();
ArrayList<Integer> current_legal_moves2 = new ArrayList();
int global_winner = 0;
int must_capture = -1;
PFont myFont;
ArrayList<Integer> AI_move = new ArrayList();

void setup() {
  size(1200, 1200);
  myFont = createFont("Verdana", 12);
  textFont(myFont, 12);
  reset_board(board);
}

void draw() {
  background(0);
  display_board();
  display_text();
  if ((edit_mode == 0)&&(global_winner == 0)&&(user_move[1] != -1)) {
    if  ((must_capture == -1)||(must_capture == user_move[0])) {
      println("Move submitted: " + user_move[0] + " " + user_move[1]);
      int is_capture_move = 0;
      int destination = 0;
      if (((user_move[1]-user_move[0]==18)||(user_move[1]-user_move[0]==-18)||(user_move[1]-user_move[0]==-14)||(user_move[1]-user_move[0]==14))&&(board[user_move[0]+(user_move[1]-user_move[0])/2] != 0)) {
        is_capture_move = 1;
        println("it is a capture");
        destination = user_move[0]+(user_move[1]-user_move[0])/2;
      } else if (((user_move[1]-user_move[0]==9)||(user_move[1]-user_move[0]==-9)||(user_move[1]-user_move[0]==-7)||(user_move[1]-user_move[0]==7))&&(board[user_move[1]] != 0)) {
        is_capture_move = 1;
        println("it is a capture");
        destination = user_move[1];
      } else {
        destination = user_move[1];
        println("it is not a capture");
      }
      println("Is it a capture move: " + is_capture_move);
      if (((is_capture_move == 1)||(must_capture == -1))&&(is_legal_move(board, user_move[0], destination, turn))) {
        println("Legal move submitted");
        ArrayList<Integer> move = new ArrayList();
        move.add(user_move[0]);
        move.add(destination);
        int new_position = process_move(board, move);
        user_move[0] = user_move[1] = -1;
        if ((is_capture_move == 0) || can_capture(board, new_position).size() <= 0) { //the turn is over only if the piece moved or if it captured, but cannot capture anymore.
          turn*= -1;
          must_capture = -1;
          current_legal_moves = legal_moves(board,turn);
          global_winner = winner(board);
        } else {
          must_capture = new_position;
          current_legal_moves2 = can_capture(board,new_position);
        }
      } else {
        user_move[0] = user_move[1] = -1;
      }
    } else {
      user_move[0] = user_move[1] = -1;
    }
  }
}

ArrayList<ArrayList<Integer>> legal_moves(int[] board, int player_color) {
  //This function generates the set of legal moves for a given combination of a board and player color. It first generates a capture tree to indicate the possible sequence of captures, and then if no captures are possible, it generates the set of possible movements
  //promotions of the pieces. player_color = 1 if white, -1 if black
  println("Calling legal moves");
  ArrayList<ArrayList<Integer>> legal = new ArrayList();
  //CAPTURE TREE
  List<ArrayList> stack = new Stack();
  stack.add(new ArrayList());
  int[] tempboard = new int[64];
  int current_position = 0;
  while (stack.size() > 0) {
    System.arraycopy( board, 0, tempboard, 0, 64 );
    ArrayList<Integer> move = stack.remove(stack.size()-1);
    //print("Processing move: ");
    //print_move(move);
    if (move.size() > 0) {
      //println("Interal or leaf node, processing a possibly multi-capture move");
      current_position = process_move(tempboard, move);
      //println("Processed the above move");
    }
    if ((move.size() != 0) && (can_capture(tempboard, current_position).size() == 0)) { //if we are at a leaf node
      //println("Leaf node");
      legal.add(move);
    } else {
      if (move.size() == 0) { //if we are at the root node
        //println("Legal moves: Root node of capture tree");
        for (int i = 0; i < 64; i ++) {//for each friendly piece, we determine what captures it can make
          int piece_color = 0;
          if (tempboard[i] != 0) {
            piece_color = abs(tempboard[i])/tempboard[i];
          }
          //println("piece_color: " + piece_color + " player_color: " + player_color);
          if (piece_color == player_color) { //if the piece is friendly
            ArrayList<Integer> captures = can_capture(tempboard, i); //what captures can it make?
            if (captures.size() > 0) { //if it can make a capture
              for (int j = 0; j < captures.size(); j++) {
                ArrayList<Integer> captures2 = new ArrayList(); 
                captures2.add(i);
                captures2.add(captures.get(j));
                //println("Currently at root node. Adding move to stack: ");
                print_move(captures2);
                stack.add(captures2);
              }
            }
          }
        }
      } else {  //if we are at an internal node
        ArrayList<Integer> captures = can_capture(tempboard, current_position);
        if (captures.size() > 0) {
          for (int j = 0; j < captures.size(); j++) {
            ArrayList<Integer> captures2 = move;
            captures2.add(captures.get(j));
            //println("Currently at internal node. Adding move to stack: ");
            print_move(captures2);
            stack.add(move);
          }
        }
      }
    }
  }
  //if, at this point, no captures are possible, then we see if movement/promotion is possible. If not, no move is possible.
  if (legal.size() > 0) {
    print_legal_moves(legal);
    //println("End of legal moves function. Captures are possible, so movement is not considered.");
    return legal;
  }
  //println("Legal move function: empty capture tree, checking for movement/promotion");
  for (int i = 0; i < 64; i++) {
    int piece_color = 0;
    if (board[i] != 0) {
      piece_color = abs(board[i])/board[i];
    }
    if (piece_color == player_color) {
      if ((abs(board[i]) == 10)||(piece_color == 1)) { //if the piece is a king or if the piece is white, test for upward capture
        if ( (i+9<64) && (i%8 < 7) && (board[i+9] == 0)) { //move up-right
          ArrayList move = new ArrayList();
          move.add(i);
          move.add(i+9);
          legal.add(move);
        }
        if ( (i+7<64) && (i%8 > 0) && (board[i+7] == 0)) { //move up-left
          ArrayList move = new ArrayList();
          move.add(i);
          move.add(i+7);
          legal.add(move);
        }
      }
      if ((abs(board[i]) == 10)||(piece_color == -1)) { //if the piece is a king or if the piece is black, test for upward capture
        if ( (i-7>-1) && (i%8 < 7) && (board[i-7] == 0)) { //move down-right
          ArrayList move = new ArrayList();
          move.add(i);
          move.add(i-7);
          legal.add(move);
        }
        if ( (i-9>-1) && (i%8 > 0) && (board[i-9] == 0)) { //move down-left
          ArrayList move = new ArrayList();
          move.add(i);
          move.add(i-9);
          legal.add(move);
        }
      }
    }
  }
  print_legal_moves(legal);
  //println("End of legal moves function. No captures are possible.");
  return legal;
}

int winner(int[] board) {
  //-1 is black win, 1 is white win, 0 is game in progress
  int no_white = 1;
  int no_black = 1;
  for (int i = 0; i < 64; i++) {
    if (board[i] > 0) {
      no_white = 0;
    } else if (board[i] < 0) {
      no_black = 0;
    }
  }
  if (no_white == 1) {
    return -1;
  } else if (no_black == 1) {
    return 1;
  }
  println("Winner function: checking if white has any legal moves");
  ArrayList<ArrayList<Integer>> legal = legal_moves(board, 1);
  if ((legal.size() == 0)&&(turn == 1)) {
    return -1;
  }
  println("Winner function: checking if black has any legal moves");
  legal = legal_moves(board, -1);
  if ((legal.size() == 0)&&(turn == -1)) {
    return 1;
  }
  return 0;
}

void display_board() {
  for (int i = 0; i < 64; i++) {
    stroke(255);
    int c = ((i%8)+(int)(i/8))%2;
    fill(c*255);
    int x = 200+(i%8)*50;
    int y = 550-(int)(i/8)*50;
    rect(x, y, 50, 50);
    if (board[i] != 0) {
      display_piece(x, y, c, board[i]);
    }
    fill(255-c*255);
    text(i, x+20, y+20);
  }
  fill(255);
  text("A", 220, 620);
  text("B", 270, 620);
  text("C", 320, 620);
  text("D", 370, 620);
  text("E", 420, 620);
  text("F", 470, 620);
  text("G", 520, 620);
  text("H", 570, 620);
  text("8", 180, 220);
  text("7", 180, 270);
  text("6", 180, 320);
  text("5", 180, 370);
  text("4", 180, 420);
  text("3", 180, 470);
  text("2", 180, 520);
  text("1", 180, 570);
}

void display_piece(int x, int y, int square, int piece) {
  int c = (abs(piece)/piece+1)/2;
  fill(c*255);
  stroke((1-square)*255);
  switch (piece = abs(piece)) {
  case 1:
    ellipse(x+25, y+25, 30, 30);
    break;
  case 10:
    beginShape();
    vertex(x+25, y+5);
    vertex(x+5, y+25);
    vertex(x+25, y+45);
    vertex(x+45, y+25);
    vertex(x+25, y+5);
    endShape();
    break;
  }
}

void display_text() {
  fill(255);
  if (edit_mode == 0) {
    if (turn == 1) {
      text("White to move.", 100, 100);
    } else {
      text("Black to move.", 100, 100);
    }
  } else {
    if (turn == 1) {
      text("EDIT MODE (with white to move).", 100, 100);
    } else {
      text("EDIT MODE (with black to move).", 100, 100);
    }
  }
  text(user_move[0] + " " + user_move[1], 100, 150);
  /*
  if (turn == 1) {
   time[0] = (int)(time2[0]*1000-(millis()-checkpoint))/1000;
   } else {
   time[1] = (int)(time2[1]*1000-(millis()-checkpoint))/1000;
   }
   if ((time[0])%60 < 10) {
   text("White's time left: " + (int)(time[0])/60 + ":0" + (time[0])%60, 400, 100);
   } else {
   text("White's time left: " + (int)(time[0])/60 + ":" + (time[0])%60, 400, 100);
   }
   if ((time[1])%60 < 10) {
   text("Black's time left: " + (int)(time[1])/60 + ":0" + (time[1])%60, 400, 115);
   } else {
   text("Black's time left: " + (int)(time[1])/60 + ":" + (time[1])%60, 400, 115);
   } */
  if (global_winner == 1) {
    textFont(myFont, 20);
    text("WHITE WINS!", 400, 150); 
    textFont(myFont, 12);
  } else if (global_winner == -1) {
    textFont(myFont, 20);
    text("BLACK WINS!", 400, 150); 
    textFont(myFont, 12);
  }
  fill(0);
  stroke(255);
  rect(100, 200, 75, 50);
  rect(100, 260, 75, 50);
  fill(255);
  if (edit_mode == 0) {
    text("EDIT", 125, 225);
    text("AI", 125, 285);
    if (AI_move.size() > 0) {
      text(AI_move.get(0), 125, 345);
    }
  } else {
    text("BACK TO", 105, 225);
    text("GAME", 105, 240);
    fill(0);
    stroke(255);
    rect(100, 320, 75, 50);
    rect(100, 380, 75, 50);
    fill(255);
    text("CLEAR", 105, 285);
    text("BOARD", 105, 300);
    text("RESET", 105, 345);
    text("BOARD", 105, 360);
    text("SWITCH", 105, 405);
    text("TURN", 105, 420);
  }
  if (edit_mode == 0){
   if (turn == 1){
   text("Legal moves (for white):", 625,225);
   }else if (turn == -1){
   text("Legal moves (for black):", 625,225);
   }
   if (must_capture == -1){
   for (int i = 0; i < current_legal_moves.size(); i++){
   text(current_legal_moves.get(i).get(0),625,240+i*15);
   for (int j = 1; j < current_legal_moves.get(i).size(); j++){
   text("to " + current_legal_moves.get(i).get(j),625+35*(j-1)+20,240+i*15);
   }
   }
   }else{
   current_legal_moves2 = can_capture(board,must_capture);
   for (int i = 0; i < current_legal_moves2.size(); i++){
   text(must_capture,625,240+i*15);
   text("to " + current_legal_moves2.get(i),645,240+i*15);
   }
   }
   }
}

int process_move(int[] board, ArrayList<Integer> move) {
  //given a board, this function processes the move on the board, updating it to reflect the move being played. The entries of move correspond to {piece, destination}. A destination that is occupied implies a capture, and must be dealt with accordingly.
  print("Process_move function: ");
  print_move(move);
  int piece = board[move.get(0)];
  int piece_color = abs(piece)/piece;
  if (board[move.get(1)] != 0) {  //if the move is a capture
    int next_move = move.get(0);
    for (int i = 1; i < move.size(); i++) {
      //potential optimization below
      if (move.get(i)-next_move==9) {    //capture up-right
        println("capturing up-left");
        if ((abs(piece)==1)&&(next_move+18>55)) {
          board[next_move+18] = 10*board[next_move];
          piece *= 10;
        } else {
          board[next_move+18] = board[next_move];
        }
        board[move.get(i)] = 0;
        board[next_move] = 0;
        next_move = next_move+18;
      } else if (move.get(i)-next_move==7) {    //capture up-left
        println("capturing up-left");
        if ((abs(piece)==1)&&(next_move+14>55)) {
          board[next_move+14] = 10*board[next_move];
          piece *= 10;
        } else {
          board[next_move+14] = board[next_move];
        }
        board[move.get(i)] = 0;
        board[next_move] = 0;
        next_move = next_move+14;
      } else if (move.get(i)-next_move==-7) {    //capture down-right
        println("capturing down-right");
        if ((abs(piece)==1)&&(next_move-14<8)) {
          board[next_move-14] = 10*board[next_move];
          piece *= 10;
        } else {
          board[next_move-14] = board[next_move];
        }
        board[move.get(i)] = 0;
        board[next_move] = 0;
        next_move = next_move-14;
      } else if (move.get(i)-next_move==-9) {    //capture down-left
        println("capturing down-left");
        if ((abs(piece)==1)&&(next_move-18<8)) {
          board[next_move-18] = 10*board[next_move];
          piece *= 10;
        } else {
          board[next_move-18] = board[next_move];
        }
        board[move.get(i)] = 0;
        board[next_move] = 0;
        next_move = next_move-18;
      }
    }
    return next_move;
  } else if ((abs(piece)== 1)&&((move.get(1)/8) == (7*(piece_color+1)/2)) ) { //if the move is a promotion
    board[move.get(1)] = 10*board[move.get(0)];
    board[move.get(0)] = 0;
    return move.get(1);
  } else { //if the move is just a regular move
    board[move.get(1)] = board[move.get(0)];
    board[move.get(0)] = 0;
    return move.get(1);
  }
}

ArrayList<Integer> can_capture(int[] board, int position) {
  //given a board and a piece on the board (specified by its position on the board), can that piece make an immediate capture? This function returns the list of captures (each stored as a vector of ints).
  int piece = board[position];
  int piece_color = abs(piece)/piece;
  ArrayList<Integer> captures = new ArrayList();
  if ((abs(piece) == 10)||(piece_color == 1)) { //if the piece is a king or if the piece is white, test for upward capture
    if ( (position+18<64) && (position%8 < 6) && (board[position+18] == 0) && (board[position+9]!=0)&&(abs(board[position+9])/board[position+9] == -piece_color)) { //capture up-right
      captures.add(position+9);
    }
    if ( (position+14<64) && (position%8 > 1) && (board[position+14] == 0) && (board[position+7]!=0)&&(abs(board[position+7])/board[position+7] == -piece_color)) { //capture- up-left
      captures.add(position+7);
    }
  }
  if ((abs(piece) == 10)||(piece_color == -1)) { //if the piece is a king or if the piece is black, test for downward capture
    if ( (position-14>-1) && (position%8 < 6) && (board[position-14] == 0) && (board[position-7]!=0)&&(abs(board[position-7])/board[position-7] == -piece_color)) {  //capture down-right
      captures.add(position-7);
    }
    if ( (position-18>-1) && (position%8 > 1) && (board[position-18] == 0) && (board[position-9]!=0)&&(abs(board[position-9])/board[position-9] == -piece_color)) {  //capture down-left
      captures.add(position-9);
    }
  }
  return captures;
}

void print_legal_moves(ArrayList<ArrayList<Integer>> array) {
  print("Printing legal moves ");
  for (int i = 0; i < array.size(); i++) {
    for (int j = 0; j < array.get(i).size(); j++) {
      print(array.get(i).get(j) + " ");
    }
    print("\t");
  }
  println();
}

void print_move(ArrayList<Integer> move) {
  for (int i = 0; i < move.size(); i++) {
    print(move.get(i) + " ");
  }
  println();
}

boolean is_legal_move(int[] board, int position, int destination, int player_color) {
  println("Checking if move is legal for piece:  " + position + " " + destination + " " + player_color); 
  if (board[position] == 0) {
    return false;
  } else if (abs(board[position])/board[position] != player_color) {
    return false;
  } else {
    ArrayList<ArrayList<Integer>> legal_moves_set = legal_moves(board, player_color);
    for (int i = 0; i < legal_moves_set.size(); i++) {
      if ((legal_moves_set.get(i).get(0) == position)&&(legal_moves_set.get(i).get(1) == destination)) {
        return true;
      }
    }
  }
  return false;
}

void clear_board(int[] board) {
  for (int i = 0; i < 64; i++) {
    board[i] = 0;
  }
  turn = 1;
  global_winner = 0;
}

void reset_board(int []board) {
  for (int i = 0; i < 64; i++) {
    board[i] = 0;
  } 
  board[0] = board[2] = board[4] = board[6] = 1; 
  board[9] = board[11] = board[13] = board[15] = 1;
  board[16] = board[18] = board[20] = board[22] = 1;
  board[41] = board[43] = board[45] = board[47] = -1;
  board[48] = board[50] = board[52] = board[54] = -1;
  board[57] = board[59] = board[61] = board[63] = -1;
  turn = 1;
  user_move[0] = user_move[1]= -1;
  global_winner = 0;
  current_legal_moves = legal_moves(board,turn);
}

void mousePressed() {
  int x = (int)(mouseX-200)/50;
  int y = (int)(600-mouseY)/50;
  if ((edit_mode == 0)&&((x>-1)&&(x<8)&&(y>-1)&&(y<8))) { //if the mouse is clicked within the board during game
    println("User clicked on: " + (y*8+x));
    if (user_move[0] == -1) { //if the user has not selected a piece to move
      if (board[y*8+x]*turn>0) { //if the piece belongs to the user
        user_move[0] = y*8+x; //select that piece for movement
      }
    } else { //if the user has selected a piece to move
      user_move[1] = y*8+x; //select the destination for the piece
    }
  } else if ((mouseX>100)&&(mouseX<175)&&(mouseY>200)&&(mouseY<250)) { //if edit button is pressed
    edit_mode = 1 - edit_mode; //switch mode
    user_move[0] = user_move[1] = -1; //reset user move
    must_capture = -1; //reset forced capture
    if (edit_mode == 0){
       current_legal_moves = legal_moves(board,turn); //if edit mode is turned off, the winner is determined, and the legal moves for the current position are evaluated
       global_winner = winner(board);
    }
  } else if ((edit_mode == 1)&&(mouseX>100)&&(mouseX<175)&&(mouseY>260)&&(mouseY<310)) { //if the clear board button is pressed
    clear_board(board); 
  } else if ((edit_mode == 1)&&(mouseX>100)&&(mouseX<175)&&(mouseY>320)&&(mouseY<370)) { //if the reset board button is pressed
    reset_board(board);
  } else if ((edit_mode == 1)&&(mouseX>100)&&(mouseX<175)&&(mouseY>380)&&(mouseY<430)) { //if the switch turn button is pressed
    turn *= -1;
  } else if ((edit_mode == 0)&&(mouseX>100)&&(mouseX<175)&&(mouseY>260)&&(mouseY<310)) { //if the AI button is pressed
    AI_move = new ArrayList();
    AI_move.add(minimax(board, turn, 1));
  } else if ((edit_mode == 1)&&((x>-1)&&(x<8)&&(y>-1)&&(y<8))) { //if the mouse is clicked within the board during edit mode
    println("User clicked on: " + (y*8+x));
    switch (board[y*8+x]) { //change the clicked pieces in the following way: empty square --> white pawn --> white king --> black pawn --> black king --> empty square
    case 0:
      board[y*8+x] = 1; 
      break;
    case 1:
      board[y*8+x] = 10;
      break;
    case 10:
      board[y*8+x] = -1;
      break;
    case -1:
      board[y*8+x] = -10;
      break;
    case -10:
      board[y*8+x] = 0;
      break;
    }
  }
}

int minimax(int[] board, int player_color, int depth) {
  println("Evaluating minimax");
  if (depth == 0) {
    return heuristic(board);
  }
  ArrayList<Integer> best_move = new ArrayList();
  int best_score = 0;
  ArrayList<ArrayList<Integer>> options = legal_moves(board, player_color);
  for (int i = 0; i < options.size(); i++) {
    int[] tempboard = new int[64];
    System.arraycopy( board, 0, tempboard, 0, 64 );
    process_move(tempboard, options.get(i));
    int value = minimax(tempboard, -player_color, depth-1);
    switch(player_color) {
    case 1:
      if (value > best_score) {
        best_score = value;
      }
      break;
    case -1:
      if (value < best_score) {
        best_score = value;
      }
      break;
    }
  }
  return best_score;
}


int heuristic(int[] board) {
  int white_material = 0;
  int black_material = 0;
  int winner = winner(board);
  if (winner == 1) {
    return 9999;
  } else if (winner == -1) {
    return 0;
  }
  for (int i = 0; i < 64; i++) {
    switch(board[i]) {
    case 1:
      white_material += 10;
      break;
    case 10:
      white_material += 14;
      break;
    case -1:
      black_material += 10;
      break;
    case -10:
      black_material += 14;
      break;
    }
  }
  return (1000*white_material)/black_material;
}

/*
 Features yet to add:
 - EDIT Button
 - AI button
 - Notation tracker
 - Clear board
 */


/*
   further optimizations:
 
 */