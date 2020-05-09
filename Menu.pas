unit Menu;

interface

{Процедура инциализации меню }
procedure InitMenu();
{Процедура отлова нажатия клавиш в меню }
procedure HandleInputInMenu();
{Процедура обновления логики меню }
procedure UpdateMenu(dt : integer);
{Процедура отрисовки меню }
procedure RenderMenu();

implementation

uses
  GlobalVars, GraphABC, UIAssets;

const
  MaxOptions = 5; //Максимальное кол-во кнопок в данном состоянии

var
  Options   : array[1..MaxOptions] of string; //Кнопки
  CurrentOp : byte;                           //Текущая кнопка
  Time : real;                                //Вспомогательная переменная для отрисовки имени создателя

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
  Background.Draw(0, 0);
  Title.Draw(94, 87);
  Logo.Draw(440, 216 + Round(10 * Sin(RadToDeg(Time))));
  for var i:=1 to MaxOptions do
  begin
    var isActive :=false;
    if (CurrentOp = i) then
    begin
      isActive := true;
    end;
    DrawButton(Window.Width div 2, 322 + 94 * (i - 1), Options[i], defaultSize, isActive);
  end;
end;

begin
  
end.