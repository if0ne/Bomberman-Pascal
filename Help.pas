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
  Count := 4;
  CurrentOp := 1;
  HelpStr[1] := 'WASD - управлением игроком 1. G - поставить бомбу.';
  HelpStr[2] := '↑←↓→ - управлением игроком 2. L - поставить бомбу.';
  HelpStr[3] := 'Взрыв стенки - 1 балл, игрока - 5 баллов.';
  HelpStr[4] := 'Смерть - -3 балла.';
  Options[1] := 'Назад';
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
  HelpTitle.Draw(300, 48);
  HelpBack.Draw(74, 154);
  SetBrushStyle(bsClear);
  SetFontSize(18);
  SetFontColor(clWhite);
  for var i:=1 to Count do
  begin
    TextOut(96, 158 + 50 * i, i + '. ' + HelpStr[i]);
  end;
  SetBrushStyle(bsSolid);
  SetFontSize(26);
  SetFontColor(clBlack);
  for var i:=1 to MaxOptions do
  begin
    if (CurrentOp = i) then
    begin
      ActiveButton.Draw(Window.Width div 2 - 128, 502 + 88 * (i - 1) - 36);
    end
    else
    begin
      Button.Draw(Window.Width div 2 - 128, 502 + 88 * (i - 1) - 36);
    end;
    SetBrushStyle(bsClear);
    DrawTextCentered(Window.Width div 2, 502 + 88 * (i - 1) + 8, Options[i]);
  end;
end;

procedure DisposeHelp;
begin
  
end;

begin
  
end.