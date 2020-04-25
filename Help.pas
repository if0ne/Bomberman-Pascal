unit Help;

interface

procedure InitHelp();
procedure HandleInputInHelp();
procedure UpdateHelp(dt : integer);
procedure RenderHelp();
procedure DisposeHelp();

implementation

uses
  GlobalVars, GraphABC, UIAssets;
  
const
  MaxOptions = 1;
  
var
  Count : integer;
  HelpStr : array[1..4] of string;
  Options   : array[1..MaxOptions] of string;
  CurrentOp : byte;

procedure InitHelp;
begin
  HelpStr[1] := 'WASD - управлением игроком 1. G - поставить бомбу.';
  HelpStr[2] := '↑←↓→ - управлением игроком 2. L - поставить бомбу.';
  HelpStr[3] := 'Взрыв стенки - 1 балл, монстра - 3 балла, игрока - 5 баллов.';
  HelpStr[4] := 'Смерть - -3 балла.';
  Options[1] := 'Назад';
  Count := 4;
  CurrentOp := 1;
end;

procedure HandleInputInHelp;
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

procedure UpdateHelp;
begin
  HandleInputInHelp();
end;

procedure RenderHelp;
begin
  Window.Clear();
  SetBrushStyle(bsSolid);
  Background.Draw(0, 0);
  //Constants: 78 - размер по макету
  DrawHeader(Window.Width div 2, 78, 'СПРАВКА');
  //Constants: 74, 154 - размер по макету
  HelpBack.Draw(74, 154);
  SetBrushStyle(bsClear);
  SetFontSize(16);
  SetFontColor(clWhite);
  for var i:=1 to Count do
  begin
    //Constants: 96, 158, 50 - размер по макету
    TextOut(96, 158 + 50 * i, i + '. ' + HelpStr[i]);
  end;
  SetBrushStyle(bsSolid);
  SetFontColor(clBlack);
  for var i:=1 to MaxOptions do
  begin
    var isActive := false;
    if (CurrentOp = i) then
    begin
      isActive := true;
    end;
    DrawButton(Window.Width div 2, 502 + 88 * (i - 1) + 8, Options[i], defaultSize, true);
  end;
end;

procedure DisposeHelp;
begin
  
end;

begin
  
end.