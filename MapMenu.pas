unit MapMenu;

interface

procedure InitMapMenu();
procedure HandleInputInMapMenu();
procedure UpdateMapMenu(dt : integer);
procedure RenderMapMenu();
procedure DisposeMapMenu();

implementation

uses
  GraphABC, GlobalVars;

var 
  TextFile : Text;
  Count : integer;
  Maps : array[1..25] of string;
  CurrentOp : byte;
  i : integer;
  
procedure InitMapMenu;
begin
  CurrentOp := 1;
  Count := 0;
  Assign(TextFile, 'maps.txt');
  Reset(TextFile);
  while (not Eof(TextFile) and (Count < 24)) do
  begin
    Count := Count + 1;
    Readln(TextFile, Maps[Count]);
  end;
  Close(TextFile);
  Count := Count + 1;
  Maps[Count] := 'Назад';
end;

procedure HandleInputInMapMenu;
begin
  if (inputKeys[VK_DOWN] or inputKeys[VK_S]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      if (CurrentOp + 1 > Count) then
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
        CurrentOp := Count;
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
      if (CurrentOp = Count) then
      begin
        ChangeState(MenuState);
      end
      else
      begin
        _CurrentMap := Maps[CurrentOp];
        ChangeState(InputNamesState);
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

procedure UpdateMapMenu;
begin
  HandleInputInMapMenu();
end;

procedure RenderMapMenu;
begin
  Window.Clear(clChocolate);
  SetBrushStyle(bsClear);
  SetFontSize(26);
  DrawTextCentered(Window.Width div 2, 128, 'Выберите карту.');
  SetBrushStyle(bsClear);
  SetBrushColor(clLightBlue);
  for var i:=1 to Count do
  begin
    if (CurrentOp = i) then
    begin
      SetBrushStyle(bsSolid);
      FillRect(Window.Width div 2 - 82, 128 + 50 * i - 22, Window.Width div 2 + 82, 128 + 50 * i + 22);
    end;
    DrawTextCentered(Window.Width div 2, 128 + 50 * i, Maps[i]);
  end;
end;

procedure DisposeMapMenu;
begin
  
end;

begin
  
end.