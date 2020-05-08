unit Highscore;

interface

procedure InitHighscore();
procedure InitNewHighscore();
procedure HandleInputInHighscore();
procedure HandleInputInNewHighscore();
procedure UpdateNewHighscore(dt : integer);
procedure UpdateHighscore(dt : integer);
procedure RenderNewHighscore();
procedure RenderHighscore();
procedure DisposeNewHighscore();

implementation

uses
  GraphABC, GlobalVars, UIAssets;

const
  MaxOptions = 1;
  MaxAllPlayer = MaxPlayers + 25;
var 
  TextFile : Text;
  Count : integer;
  NickAndScores : array[1..5] of string;
  Options   : array[1..MaxOptions] of string;
  CurrentOp : byte;
  
  NewNick : array[1..MaxAllPlayer] of string;
  NewScore : array[1..MaxAllPlayer] of integer;
  NewCount : integer;
  
  Poses : array[1..MaxPlayers] of integer;
  FinalPlayers : array[1..MaxPlayers] of string;

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

function IsInTop(id : integer) : boolean;
begin
  IsInTop := false;
  for var i:=1 to MaxPlayers do
  begin
    if (Poses[i] = id) then
    begin
      IsInTop := true;
      exit;
    end;
  end;
end;

////////////////////////////////////////

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
  for var i:=1 to MaxPlayers do
  begin
    if (not ReplaceSamePlayer(PlayerNames[i], PlayerScores[i])) then
    begin
      Count := Count + 1;
      NewScore[Count] := PlayerScores[i];
      NewNick[Count] := PlayerNames[i];
    end;
  end;
  SortNew();
  for var i:=1 to Count do
  begin
    for var j:=1 to MaxPlayers do
    begin
      if (NewNick[i] = PlayerNames[j]) then
      begin
        Poses[j] := i;
      end;
    end;
  end;
  
  for var j:=1 to MaxPlayers do
  begin
    if (Poses[j] <= 5) then
    begin
      FinalPlayers[j] := 'Игрок ' + PlayerNames[j] + ' находится на ' + Poses[j] + ' месте.';
    end
    else
    begin
      FinalPlayers[j] := 'Игрок ' + PlayerNames[j] + ' не набрал достаточно очков, для топа.';
    end;
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
    if (IsInTop(i)) then
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
  for var i:=1 to MaxPlayers do
  begin
    DrawLabel(Window.Width div 2, 118 + 74 * (NewCount + MaxOptions + i), FinalPlayers[i]);
  end;
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