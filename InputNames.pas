unit InputNames;

interface

{Процедура инциализации ввода никнеймов }
procedure InitInputNames();
{Процедура отлова нажатия клавиш в вводе никнеймов }
procedure HandleInputInInputNames();
{Процедура обновления логики ввода никнеймов }
procedure UpdateInputNames(dt : integer);
{Процедура отрисовки ввода никнеймов }
procedure RenderInputNames();

implementation

uses
  GraphABC, GlobalVars, UIAssets;

const
  MaxOptions = MaxPlayers + 1; //Максимальное кол-во кнопок и полей ввода в данном состоянии

var
  CurrentOp : byte;                         //Текущая кнопка или поле ввода
  Options : array[1..MaxOptions] of string; //Кнопки и поля ввода
  InputPlayerNames : plNames;               //Никнеймы игроков
  
  Problems : array[1..5] of string;         //Вспомогательная переменная, хранящая ошибки при вводе ников
  CountProblem : integer;                   //Кол-во ошибок

{Процедура попытки смены текущего состояния на игровую сцену }
procedure TryToChangeState();
begin
  CountProblem := 0;
  for var i:=1 to MaxPlayers do
  begin
    if (InputPlayerNames[i] = '') then
    begin
      CountProblem := CountProblem + 1;
      Problems[CountProblem] := 'Имя игрока ' + i + ' пустое.';
    end;
  end;
  if (CountProblem <> 0) then
  begin
    exit;
  end;
  for var i:=1 to MaxPlayers - 1 do
  begin
    for var j:=(i+1) to MaxPlayers do
    begin
      if (InputPlayerNames[i] = InputPlayerNames[j]) then
      begin
        CountProblem := CountProblem + 1;
        Problems[CountProblem] := 'Имя игрока ' + i + ' и игрока ' + j + ' совпадают.';
      end;
    end;
  end;
  if (CountProblem <> 0) then
  begin
    exit;
  end;
  PlayerNames := InputPlayerNames;
  ChangeState(MainGameState);
end;

{Процедура изменения никнейма }
{Параметры: nick - никнейм }
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

procedure InitInputNames;
begin
  CurrentOp := 1;
  for var i:=1 to MaxPlayers do
  begin
    Options[i] := 'Имя игрока ' + i + ':';
    InputPlayerNames[i] := '';
  end;
  Options[MaxPlayers + 1] := 'Назад';
  CountProblem := 0;
end;

procedure HandleInputInInputNames;
begin
  if (inputKeys[VK_DOWN]) then
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
  if (inputKeys[VK_UP]) then
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
      if (CurrentOp = (MaxPlayers + 1)) then
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
      if (CurrentOp <= MaxPlayers) then
      begin
        ChangeNick(InputPlayerNames[CurrentOp]);
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
  for var i:=1 to MaxOptions do
  begin
    if (i <= MaxPlayers) then
    begin
      if (CurrentOp = i) then
      begin
        SetBrushStyle(bsSolid);
        DrawChooseLine(0, 156 + 64 * i, Window.Width, 40);
      end;
      SetBrushStyle(bsClear);
      TextOut(Window.Width div 2 - 372, 156 + 64 * i, Options[i] + InputPlayerNames[i]);
    end
    else
    begin
      var isActive := false;
      if ((i > MaxPlayers) and (CurrentOp = i)) then
        isActive := true;
      DrawButton(Window.Width div 2, 176 + 64 * i, Options[i], defaultSize, isActive);
    end;
  end;
  for var i:=1 to CountProblem do
  begin
    DrawLabel(Window.Width div 2, 196 + 64 * MaxOptions + 74 * i, Problems[i]);
  end;
  SetBrushStyle(bsSolid)
end;

begin
  
end.