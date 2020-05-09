unit GlobalVars;

interface

const
  MenuState       = 1;  //Состояние меню 
  HelpState       = 2;  //Состояние вывода справки
  ChooseMapState  = 3;  //Состояние выбора карты
  InputNamesState = 4;  //Состояние ввода ников
  MainGameState   = 5;  //Состояние самой игры (бомбермена)
  EditorState     = 7;  //Состояние редактора
  HighscoreState  = 10; //Состояние вывода рекордов
  EndHighState    = 11; //Состояние вывода результатов
  
  DelayInput = 180; //Задержка между нажатиями клавиш
  
  SlowEnemy   = 1; //Тип монстра - обычный
  FastEnemy   = 2; //Тип монстра - быстрый
  BlowupEnemy = 3; //Тип монстра - взрывающийся
  
  TopOffset = 64; //Смещение отрисовки относительно вверха
  
  MaxPlayers = 2; //Максимальное число игроков
  
type
  plNames  = array[1..MaxPlayers] of string;
  plScores = array[1..MaxPlayers] of integer;

var
  inputKeys : array[0..255] of boolean; //Состояние клавиш
  LastChar : integer;                   //Последний нажатый символ
  IsQuit : boolean;                     //Конец программы или нет
  LastChange : longint;                 //Время последнего нажатия клавиши
  _CurrentState : byte;                 //Текущее состояние
  _CurrentMap : string;                 //Текущее имя карты
  
  PlayerNames  : plNames;               //Имена игроков
  PlayerScores : plScores;              //Счет игроков
  
{Процедура смены текущего состояния             }
{Параметры: toState - на какое состояние менять }
procedure ChangeState(toState : byte);
{Процедура очищающая данные состояния }
{Параметры: startPos - состояние      }
procedure DisposeState(state : byte);
{Процедура инициализирующая данные состояния }
{Параметры: startPos - состояние             }
procedure InitState(state : byte); 

implementation

uses
  Menu, Help, Highscore, MapMenu, InputNames, MainGame, Editor;

procedure DisposeState;
begin
  case state of
    MainGameState :
    begin
      DisposeMainGame();
    end;
    EndHighState :
    begin
      DisposeNewHighscore();
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