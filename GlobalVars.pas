unit GlobalVars;

interface

const
  MenuState       = 1;
  HelpState       = 2;
  ChooseMapState  = 3;
  InputNamesState = 4;
  MainGameState   = 5;
  EditorState     = 7;
  HighscoreState  = 10;
  EndHighState    = 11;
  
  DelayInput = 180;
  
  SlowEnemy   = 1;
  FastEnemy   = 2;
  BlowupEnemy = 3;
  
  TopOffset = 64;
  
  MaxPlayers = 2;
  
type
  plNames  = array[1..MaxPlayers] of string;
  plScores = array[1..MaxPlayers] of integer;

var
  inputKeys : array[0..255] of boolean;
  LastChar : integer;
  IsQuit : boolean;
  LastChange : longint;
  _CurrentState : byte;
  _CurrentMap : string;
  
  PlayerNames  : plNames;
  PlayerScores : plScores;
  
procedure ChangeState(toState : byte); 
procedure DisposeState(state : byte);
procedure InitState(state : byte); 

implementation

uses
  Menu, Help, Highscore, MapMenu, InputNames, MainGame, Editor;

procedure DisposeState;
begin
  case state of
    MenuState :
    begin
      DisposeMenu();
    end;
    HelpState :
    begin
      DisposeHelp();
    end;
    HighscoreState:
    begin
      DisposeHighscore();
    end;
    ChooseMapState :
    begin
      DisposeMapMenu();
    end;
    InputNamesState :
    begin
      DisposeInputNames();
    end;
    MainGameState :
    begin
      DisposeMainGame();
    end;
    EndHighState :
    begin
      DisposeNewHighscore();
    end;
    EditorState :
    begin
      DisposeEditor();
    end;
  end;
end;

procedure InitState;
begin
  case state of
    MenuState :
    begin
      InitMenu();
    end;
    HelpState:
    begin
      InitHelp();
    end;
    HighscoreState :
    begin
      InitHighscore();
    end;
    ChooseMapState :
    begin
      InitMapMenu();
    end;
    InputNamesState :
    begin
      InitInputNames();
    end;
    MainGameState :
    begin
      InitMainGame();
    end;
    EndHighState :
    begin
      InitNewHighscore();
    end;
    EditorState :
    begin
      InitEditor();
    end;
  end;
end;

procedure ChangeState;
begin
  DisposeState(_CurrentState);
  InitState(toState);
  _CurrentState := toState; 
end;

begin
  
end.