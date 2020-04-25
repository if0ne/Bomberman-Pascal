unit Highscore;

interface

procedure InitHighscore();
procedure InitNewHighscore(pl1s : integer; pl1n : string; pl2s : integer; pl2n : string);
procedure HandleInputInHighscore();
procedure HandleInputInNewHighscore();
procedure UpdateNewHighscore(dt : integer);
procedure UpdateHighscore(dt : integer);
procedure RenderNewHighscore();
procedure RenderHighscore();
procedure DisposeNewHighscore();
procedure DisposeHighscore();

implementation

uses
  GraphABC, GlobalVars, UIAssets;

const
  MaxOptions = 1;
var 
  TextFile : Text;
  Count : integer;
  NickAndScores : array[1..7] of string;
  Options   : array[1..MaxOptions] of string;
  CurrentOp : byte;
  
  NewNick : array[1..27] of string;
  NewScore : array[1..27] of integer;
  NewCount : integer;
  
  Pos1, Pos2 : integer;
  FinalPlayer1 : string;
  FinalPlayer2 : string;

procedure ParseLine(var nick : string; var score : integer; str : string);
var
  i, code : integer;
begin
  i:=1;
  if (Length(str) > 0) then
  begin
    while (str[i] <> ' ') do
    begin
      nick := nick + str[i];
      i := i + 1;
    end;
    val(Copy(str, i + 1, Length(str)), score, code);
  end;
end;

procedure SortNew();
begin
  for var i := 1 to Count - 1 do
  begin
    for var j := 1 to Count - i do
    begin
      if NewScore[j] < NewScore[j+1] then 
      begin
        var k := NewScore[j];
        NewScore[j] := NewScore[j+1];
        NewScore[j+1] := k;
        var s := NewNick[j];
        NewNick[j] := NewNick[j+1];
        NewNick[j+1] := s;
      end;
    end;
  end;
end;

function ReplaceSamePlayer(nick : string; score : integer) : boolean;
begin
  ReplaceSamePlayer := false;
  for var i:=1 to Count do
  begin
    if (nick = NewNick[i]) then
    begin
      ReplaceSamePlayer := true;
      NewScore[i] := score;
      break;
    end;
  end;
end;

procedure InitHighscore;
begin
  CurrentOp := 1;
  Options[1] := 'Назад';
  Count := 0;
  Assign(TextFile, 'scores.txt');
  Reset(TextFile);
  while (not Eof(TextFile) and (Count < 5)) do
  begin
    Count := Count + 1;
    Readln(TextFile, NickAndScores[Count]);
  end;
  Close(TextFile);
end;

procedure InitNewHighscore;
begin
  CurrentOp := 1;
  Options[1] := 'Выход';
  Count := 0;
  Assign(TextFile, 'scores.txt');
  Reset(TextFile);
  while (not Eof(TextFile) and (Count < 25)) do
  begin
    Count := Count + 1;
    var line : string;
    Readln(TextFile, line);
    ParseLine(NewNick[Count], NewScore[Count], line);
  end;
  if (not ReplaceSamePlayer(pl1n, pl1s)) then
  begin
    Count := Count + 1;
    NewScore[Count] := pl1s;
    NewNick[Count] := pl1n;
  end;
  if (not ReplaceSamePlayer(pl2n, pl2s)) then
  begin
    Count := Count + 1;
    NewScore[Count] := pl2s;
    NewNick[Count] := pl2n;
  end;
  SortNew();
  for var i:=1 to Count do
  begin
    if (NewNick[i] = pl1n) then
    begin
      Pos1 := i;
    end
    else
    if (NewNick[i] = pl2n) then
    begin
      Pos2 := i;
    end;
  end;
  
  if (Pos1 <= 5) then
  begin
    FinalPlayer1 := 'Игрок ' + pl1n + ' находится на ' + Pos1 + ' месте.';
  end
  else
  begin
    FinalPlayer1 := 'Игрок ' + pl1n + ' не набрал достаточно очков, для топа.';
  end;
  
  if (Pos2 <= 5) then
  begin
    FinalPlayer2 := 'Игрок ' + pl2n + ' находится на ' + Pos2 + ' месте.';
  end
  else
  begin
    FinalPlayer2 := 'Игрок ' + pl2n + ' не набрал достаточно очков, для топа.';
  end;
  
  if (Count > 5) then
  begin
    NewCount := 5;
  end
  else
  begin
    NewCount := Count;
  end;
  Close(TextFile);
end;

procedure HandleInputInHighscore;
begin
  if (inputKeys[VK_DOWN] or inputKeys[VK_S]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      if (CurrentOp + 1 > MaxOptions) then
      begin
        CurrentOp := 1;
      end
      else
      begin
        CurrentOp := CurrentOp + 1;
      end;
    end;
  end;
  if (inputKeys[VK_UP] or inputKeys[VK_W]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      if (CurrentOp - 1  < 1) then
      begin
        CurrentOp := MaxOptions;
      end
      else
      begin
        CurrentOp := CurrentOp - 1;
      end;
    end;
  end;
  if (inputKeys[VK_ENTER]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      if (CurrentOp = 1) then
      begin
        ChangeState(MenuState);
      end;
    end;
  end;
  if (inputKeys[VK_ESCAPE]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      ChangeState(MenuState);
    end;
  end;
end;

procedure HandleInputInNewHighscore;
begin
 if (inputKeys[VK_DOWN] or inputKeys[VK_S]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      if (CurrentOp + 1 > MaxOptions) then
      begin
        CurrentOp := 1;
      end
      else
      begin
        CurrentOp := CurrentOp + 1;
      end;
    end;
  end;
  if (inputKeys[VK_UP] or inputKeys[VK_W]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      if (CurrentOp - 1  < 1) then
      begin
        CurrentOp := MaxOptions;
      end
      else
      begin
        CurrentOp := CurrentOp - 1;
      end;
    end;
  end;
  if (inputKeys[VK_ENTER]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      if (CurrentOp = 1) then
      begin
        ChangeState(MenuState);
      end;
    end;
  end;
  if (inputKeys[VK_ESCAPE]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      ChangeState(MenuState);
    end;
  end; 
end;

procedure UpdateNewHighscore;
begin
  HandleInputInNewHighscore();
end;

procedure UpdateHighscore;
begin
  HandleInputInHighscore();
end;

procedure RenderHighscore;
begin
  Window.Clear();
  SetBrushStyle(bsSolid);
  Background.Draw(0, 0);
  DrawHeader(Window.Width div 2, 78, 'Таблица рекордов');
  for var i:=1 to Count do
  begin
    var scoreType := DefaultType;
    if (i = 1) then
    begin
      scoreType := GoldType;
    end
    else
    if (i = 2) then
    begin
      scoreType := SilverType;
    end
    else
    if (i = 3) then
    begin
      scoreType := BronzeType;
    end;
    DrawScoreLabel(Window.Width div 2, 128 + 74 * i,  NickAndScores[i], scoreType);
  end;
  for var i:=1 to 1 do
  begin
    var isActive := false;
    if (CurrentOp = i) then
    begin
      isActive := true
    end;
    DrawButton(Window.Width div 2, 128 + 74 * (Count + i) + 15, Options[i], defaultSize, isActive);
  end;
end;

procedure RenderNewHighscore;
begin
  Window.Clear();
  SetBrushStyle(bsSolid);
  Background.Draw(0, 0);
  DrawHeader(Window.Width div 2, 78, 'Ваши результаты');
  for var i:=1 to NewCount do
  begin
    if ((i = Pos1) or (i = Pos2)) then
    begin
      DrawScoreLabel(Window.Width div 2, 98 + 74 * i,  NewNick[i] + ' ' + NewScore[i], NewType);
    end
    else
    begin
      DrawScoreLabel(Window.Width div 2, 98 + 74 * i,  NewNick[i] + ' ' + NewScore[i], DefaultType);
    end;
  end;
  for var i:=1 to MaxOptions do
  begin
    var isActive := false;
    if (CurrentOp = i) then
    begin
      isActive := true;
    end;
    DrawButton(Window.Width div 2, 113 + 74 * (NewCount + i), Options[i], defaultSize, isActive);
  end;
  DrawLabel(Window.Width div 2, 118 + 74 * (NewCount + MaxOptions + 1), FinalPlayer1);
  DrawLabel(Window.Width div 2, 118 + 74 * (NewCount + MaxOptions + 2), FinalPlayer2);
end;

procedure DisposeHighscore;
begin
  
end;

procedure DisposeNewHighscore;
begin
  Assign(TextFile, 'scores.txt');
  Rewrite(TextFile);
  for var i:=1 to Count do
  begin
    var line := NewNick[i] + ' ' + NewScore[i];
    Writeln(TextFile, line);
  end;
  Close(TextFile);
end;

begin
  
end.