﻿unit Menu;

interface

procedure InitMenu();
procedure HandleInputInMenu();
procedure UpdateMenu(dt : integer);
procedure RenderMenu();
procedure DisposeMenu();

implementation

uses
  GlobalVars, GraphABC, UIAssets;

const
  MaxOptions = 5;

var
  Options   : array[1..MaxOptions] of string;
  CurrentOp : byte;
  Time : real;

procedure InitMenu;
begin
  Options[1] := 'Играть';
  Options[2] := 'Редактор';
  Options[3] := 'Рекорды';
  Options[4] := 'Справка';
  Options[5] := 'Выход';
  CurrentOp  := 1;
  SetWindowSize(960, 768);
  Time := 0;
end;

procedure HandleInputInMenu;
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
        ChangeState(ChooseMapState);
      end;
      if (CurrentOp = 2) then
      begin
        ChangeState(EditorState);
      end;
      if (CurrentOp = 3) then
      begin
        ChangeState(HighscoreState);
      end;
      if (CurrentOp = 4) then
      begin
        ChangeState(HelpState);
      end;
      if (CurrentOp = 5) then
      begin
        IsQuit := true;
      end;
    end;
  end;
  if (inputKeys[VK_ESCAPE]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds;
      IsQuit := true;
    end;
  end;
end;

procedure UpdateMenu;
begin
  HandleInputInMenu();
  Time := Time + 0.985;
end;

procedure RenderMenu;
begin
  Window.Clear();
  SetBrushStyle(bsSolid);
  MenuBackground.Draw(0, 0);
  Logo.Draw(405, 250 + Round(10 * Sin(RadToDeg(Time))));
  SetFontSize(26);
  for var i:=1 to MaxOptions do
  begin
    if (CurrentOp = i) then
    begin
      ActiveButton.Draw(Window.Width div 2 - 128, Window.Height div 2 + 88 * i - 156);
    end
    else
    begin
      Button.Draw(Window.Width div 2 - 128, Window.Height div 2 + 88 * i - 156);
    end;
    SetBrushStyle(bsClear);
    DrawTextCentered(Window.Width div 2, Window.Height div 2 + 88 * i - 112, Options[i]);
  end;
end;

procedure DisposeMenu;
begin
  
end;

begin
  
end.