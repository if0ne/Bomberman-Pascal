unit MapMenu;

interface

{Процедура инциализации выбора карт }
procedure InitMapMenu();
{Процедура отлова нажатия клавиш в выборе карт }
procedure HandleInputInMapMenu();
{Процедура обновления логики выбора карт }
procedure UpdateMapMenu(dt : integer);
{Процедура отрисовки выбора карт }
procedure RenderMapMenu();

implementation

uses
  GraphABC, GlobalVars, UIAssets;
  
const
  MaxOptions = 1; //Максимальное кол-во кнопок в данном состоянии
var 
  TextFile : Text;                          //Текстовой файл с названием карт
  Count : integer;                          //Кол-во карт
  Maps : array[1..12] of string;            //Названия карт
  Options : array[1..MaxOptions] of string; //Кнопки
  CurrentOp : byte;                         //Текущая кнопка или карта
  
procedure InitMapMenu;
begin
  CurrentOp := 1;
  Options[1] := 'Назад';
  Count := 0;
  Assign(TextFile, 'maps.txt');
  Reset(TextFile);
  while (not Eof(TextFile) and (Count < 12)) do
  begin
    Count := Count + 1;
    Readln(TextFile, Maps[Count]);
  end;
  Close(TextFile);
end;

procedure HandleInputInMapMenu;
begin
  if (inputKeys[VK_DOWN] or inputKeys[VK_S]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      if (CurrentOp + 1 > Count + MaxOptions) then
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
        CurrentOp := Count + MaxOptions;
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
      if (CurrentOp = Count + 1) then
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
  SetBrushStyle(bsSolid);
  Window.Clear();
  Background.Draw(0, 0);
  DrawHeader(Window.Width div 2, 78, 'Выберите карту');
  SetFontSize(26);
  for var i:=1 to Count do
  begin
    if (CurrentOp = i) then
    begin
      SetBrushStyle(bsSolid);
      SetPenWidth(2);
      SetPenColor(clBlack);
      SetBrushColor(RGB(201, 160, 230));
      DrawChooseLine(-2, 118 + 50 * i - 20, Window.Width, 40);
      SetPenWidth(0);
    end;
    SetBrushStyle(bsClear);
    DrawTextCentered(Window.Width div 2, 118 + 50 * i, Maps[i]);
  end;
  SetFontColor(clBlack);
  for var i:=1 to MaxOptions do
  begin
    var isActive := false;
    if (CurrentOp = (i + Count)) then
    begin
      isActive := true;
    end;
    DrawButton(Window.Width div 2, 138 + 50 *(Count + i), Options[i], defaultSize, isActive);
  end;
end;

begin
  
end.