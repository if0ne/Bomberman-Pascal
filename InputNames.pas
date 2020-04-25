unit InputNames;

interface

procedure InitInputNames();
procedure HandleInputInInputNames();
procedure UpdateInputNames(dt : integer);
procedure RenderInputNames();
procedure DisposeInputNames();

implementation

uses
  GraphABC, GlobalVars, UIAssets;

var
  CurrentOp : byte;
  Options : array[1..3] of string;
  Player1, Player2 : string;
  
  Problems : array[1..25] of string;
  CountProblem : integer;

procedure InitInputNames;
begin
  CurrentOp := 1;
  Options[1] := 'Имя игрока 1: ';
  Options[2] := 'Имя игрока 2: ';
  Options[3] := 'Назад';
  Player1 := '';
  Player2 := '';
  CountProblem := 0;
end;

procedure TryToChangeState();
begin
  CountProblem := 0;
  if ((Player1 = '') or (Player2 = '')) then
  begin
    CountProblem := CountProblem + 1;
    Problems[CountProblem] := 'Имя игрока 1 или игрока 2 пустое.'
  end
  else
  if (Player1 = Player2) then
  begin
    CountProblem := CountProblem + 1;
    Problems[CountProblem] := 'Имя игрока 1 и игрока 2 совпадают.'
  end
  else
  begin
    Player1Name := Player1;
    Player2Name := Player2;
    ChangeState(MainGameState);
  end;
end;

procedure ChangeNick(var nick : string);
begin
  if (LastChar = VK_BACK) then
  begin
    if (Length(nick) > 0) then
      Delete(nick, Length(nick), 1);
  end;
  if ((Chr(LastChar).IsLetter) or (Chr(LastChar).IsDigit)) then
  begin
    if (Length(nick) < 12) then
    begin
      nick := nick + Chr(LastChar);
    end;
  end;
end;

procedure HandleInputInInputNames;
begin
  if (inputKeys[VK_DOWN]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      if (CurrentOp + 1 > 3) then
      begin
        CurrentOp := 1;
      end
      else
      begin
        CurrentOp := CurrentOp + 1;
      end;
    end;
  end;
  if (inputKeys[VK_UP]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      if (CurrentOp - 1  < 1) then
      begin
        CurrentOp := 3;
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
      if (CurrentOp = 3) then
      begin
        ChangeState(ChooseMapState);
      end
      else
      begin
        TryToChangeState();
      end;
    end;
  end;
  if (inputKeys[VK_ESCAPE]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      ChangeState(ChooseMapState);
    end;
  end;
  if (inputKeys[LastChar]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      if (CurrentOp = 1) then
      begin
        ChangeNick(Player1);
      end
      else
      if (CurrentOp = 2) then
      begin
        ChangeNick(Player2);
      end;
    end;
  end;
end;

procedure UpdateInputNames;
begin
  HandleInputInInputNames();
end;

procedure RenderInputNames;
begin
  Window.Clear();
  Background.Draw(0, 0);
  SetBrushStyle(bsClear);
  DrawHeader(Window.Width div 2, 78, 'Введите никнеймы');
  DrawLabel(Window.Width div 2, 178, 'Чтобы закончить ввод - нажмите Enter.');
  SetFontSize(26);
  for var i:=1 to 3 do
  begin
    if (i < 3) and (CurrentOp = i) then
    begin
      DrawChooseLine(0, 156 + 64 * i, Window.Width, 40);
    end;
    SetBrushStyle(bsClear);
    if (i = 1) then
    begin
      TextOut(Window.Width div 2 - 372, 156 + 64 * i, Options[i] + Player1);
    end
    else
    if (i = 2) then
    begin
      TextOut(Window.Width div 2 - 372, 156 + 64 * i, Options[i] + Player2);
    end
    else
    begin
      var isActive := false;
      if ((i > 2) and (CurrentOp = i)) then
        isActive := true;
      DrawButton(Window.Width div 2, 176 + 64 * i, Options[i], defaultSize, isActive);
    end;
  end;
  for var i:=1 to CountProblem do
  begin
    DrawLabel(Window.Width div 2, 388 + 64 * i, Problems[i]);
  end;
  SetBrushStyle(bsSolid)
end;

procedure DisposeInputNames;
begin
  
end;

begin
  
end.