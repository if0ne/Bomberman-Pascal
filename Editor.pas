unit Editor;

interface

procedure InitEditor();
procedure HandleInputInEditor();
procedure UpdateEditor(dt : integer);
procedure RenderEditor();
procedure DisposeEditor();

implementation

uses
  GraphABC, GlobalVars, Renderer;

type
  EditorState = record
    Map   : array[1..20, 1..20] of integer;
    MapX  : word;
    MapY  : word;
  end;
  
  Cell = record
    X : integer;
    Y : integer;
  end;

const
  TopOffset = 64;
  EditState = 1;
  SaveState = 2;

var
  EditModeState : EditorState;
  
  CurrentX : integer;
  CurrentY : integer;
  CurrentBlock : word;
  CurrentState : word;
  
  MapName : string;
  
  Problems : array[1..25] of string;
  CountProblem : integer;
  
procedure InitEditor;
begin
  MapName:='';
  CountProblem:=0;
  EditModeState.MapX := 15;
  EditModeState.MapY := 11;
  CurrentX := 2;
  CurrentY := 2;
  CurrentBlock := 0;
  CurrentState := EditState;
  for var i:=1 to EditModeState.MapY do
  begin
    for var j:=1 to EditModeState.MapX do
    begin
      if ((i = 1) or (j = 1) or (i = EditModeState.MapY) or (j = EditModeState.MapX)) then
        EditModeState.Map[i, j] := 1
      else
        EditModeState.Map[i, j] := 0;
    end;
  end;
end;

procedure ChangeMapName(var _mapName : string);
begin
  if (LastChar = VK_BACK) then
  begin
    if (Length(_mapName) > 0) then
      Delete(_mapName, Length(_mapName), 1);
  end;
  if ((Chr(LastChar).IsLetter) or (Chr(LastChar).IsDigit)) then
  begin
    if (Length(_mapName) < 12) then
    begin
      _mapName := _mapName + Chr(LastChar);
    end;
  end;
end;

function ContainsMap(_mapName : string) : boolean;
var
  MapFile : Text;
  MapCount : integer;
  Maps : array[1..25] of string;
begin
  Assign(MapFile, 'maps.txt');
  Reset(MapFile);
  MapCount := 0;
  while (not Eof(MapFile) and (MapCount < 24)) do
  begin
    MapCount := MapCount + 1;
    Readln(MapFile, Maps[MapCount]);
  end;
  Close(MapFile);
  ContainsMap := false;
  for var i:=1 to MapCount do
  begin
    if (_mapName = Maps[i]) then
    begin
      ContainsMap := true;
      exit;
    end;
  end;
end;

procedure SaveMapWithName(_mapName : string);
var
  MapFile : Text;
  NewMap : Text;
begin
  Append(MapFile, 'maps.txt');
  Write(MapFile, '');
  Writeln(MapFile, _mapName);
  Close(MapFile);
  Assign(NewMap, 'maps/' + _mapName + '.txt');
  Rewrite(NewMap);
  for var i:=1 to EditModeState.MapY do
  begin
    for var j:=1 to EditModeState.MapX do
    begin
      Write(NewMap, EditModeState.Map[i, j]);
    end;
    Writeln(NewMap);
  end;
  Close(NewMap);
end;

function CheckCountSpawns() : boolean;
var
  SpawnPlayerCount : integer;
  SpawnEnemyCount  : integer;
begin
  CheckCountSpawns := false;
  SpawnPlayerCount := 0;
  SpawnEnemyCount := 0;
  for var i:=1 to EditModeState.MapY do
  begin
    for var j:=1 to EditModeState.MapX do
    begin
      case EditModeState.Map[i,j] of
        4: SpawnEnemyCount := SpawnEnemyCount + 1;
        5: SpawnPlayerCount := SpawnPlayerCount + 1;
      end;
    end;
  end;
  if (SpawnPlayerCount < 2) or (SpawnPlayerCount > 8) then
  begin
    CountProblem:=CountProblem+1;
    Problems[CountProblem]:='Кол-во спавнов игрока либо меньше 2, либо больше 8.';
  end;
  if (SpawnEnemyCount < 1) or (SpawnEnemyCount > 4) then
  begin
    CountProblem:=CountProblem+1;
    Problems[CountProblem]:='Кол-во спавнов ИИ либо меньше 1, либо больше 4.';
  end;
  if ((SpawnPlayerCount > 1) and (SpawnPlayerCount < 9) and (SpawnEnemyCount > 0) and (SpawnEnemyCount < 5)) then
  begin
    CheckCountSpawns := true;
  end;
end;

function FindPath(startPos, targetPos : Cell) : boolean;
var
  stop : boolean;
  NewMap : array[1..20, 1..20] of integer;
  x, y, step : integer;
begin
  step:=0;
  stop:=false;
  for y:=1 to EditModeState.MapY do
    for x:=1 to EditModeState.MapX do
      if (EditModeState.Map[y, x] = 1) then
        NewMap[y, x] := -2
      else
        NewMap[y, x] := -1;
  NewMap[startPos.Y, startPos.X] := 0;
  while ((not stop) and (NewMap[targetPos.Y, targetPos.X] = -1)) do
  begin
    stop := true;
    for y:=1 to EditModeState.MapY do
      for x:=1 to EditModeState.MapX do
        if (NewMap[y, x] = step) then
        begin
          if (y - 1 >= 1) and (NewMap[y - 1, x] <> - 2) and (NewMap[y - 1, x] = -1) then
          begin
            stop := false;
            NewMap[y - 1, x] := step + 1;
          end;
          if (y + 1 <= EditModeState.MapY) and (NewMap[y + 1, x] <> - 2) and (NewMap[y + 1, x] = -1) then
          begin
            stop := false;
            NewMap[y + 1, x] := step + 1;
          end;
          if (x - 1 >= 1) and (NewMap[y, x - 1] <> - 2) and (NewMap[y, x - 1] = -1) then
          begin
            stop := false;
            NewMap[y, x - 1] := step + 1;
          end;
          if (x + 1 <= EditModeState.MapX) and (NewMap[y, x + 1] <> - 2) and (NewMap[y, x + 1] = -1) then
          begin
            stop := false;
            NewMap[y, x + 1] := step + 1;
          end;
        end;
    step:=step+1;
  end;
  if (NewMap[targetPos.Y, targetPos.X] <> -1) then
  begin
    FindPath := true;
  end
  else
  begin
    FindPath := false;
  end;
end;

function FindFirstSpawn() : Cell;
var
  Pose : Cell;
begin
  for var i:=1 to EditModeState.MapY do
    for var j:=1 to EditModeState.MapX do
      if (EditModeState.Map[i, j] = 5) then
      begin
        Pose.X := j;
        Pose.Y := i;
        FindFirstSpawn := Pose;
        exit;
      end;
end;

function CheckRoads() : boolean;
var
  StartPos : Cell;
  OtherPos : array[1..11] of Cell;
  CountOtherPos : integer;
begin
  CountOtherPos := 0;
  StartPos := FindFirstSpawn();
  for var i:=1 to EditModeState.MapY do
    for var j:=1 to EditModeState.MapX do
      if ((EditModeState.Map[i, j] = 5) or (EditModeState.Map[i, j] = 4)) then
      begin
        if not ((i = StartPos.Y) and (j = StartPos.X)) then
        begin
          CountOtherPos:=CountOtherPos + 1;
          OtherPos[CountOtherPos].X := j;
          OtherPos[CountOtherPos].Y := i;
        end;
      end;
  CheckRoads := true;
  for var i:=1 to CountOtherPos do
  begin
    if (not FindPath(StartPos, OtherPos[i])) then
    begin
      CountProblem:=CountProblem + 1;
      Problems[CountProblem]:='Не найден путь для ' + i + '-ого спавна. Координаты: (' + StartPos.X + ';' + StartPos.Y + ') и (' + OtherPos[i].X + ';' + OtherPos[i].Y + ')';
      CheckRoads := false;
      exit;
    end;
  end;
end;

function RightMap() : boolean;
begin
  if CheckCountSpawns() then
  begin
    if CheckRoads() then
    begin
      RightMap := true;
    end
    else
    begin
      RightMap := false;
    end;
  end
  else
  begin
    RightMap := false;
  end;
end;

procedure HandleInputInSaveState();
begin
  if (inputKeys[VK_ENTER]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      CountProblem:=0;
      if (MapName = '') then
      begin
        CountProblem:=CountProblem+1;
        Problems[CountProblem]:='Пустое имя карты';
      end;
      if (ContainsMap(MapName)) then
      begin
        CountProblem:=CountProblem+1;
        Problems[CountProblem]:='Такая карта уже существует';
      end;
      if ((MapName <> '') and (not ContainsMap(MapName)) and (RightMap())) then
      begin
        SaveMapWithName(MapName);
        CurrentState := EditState;
        ChangeState(MenuState);
      end;
    end;
  end;
  if (inputKeys[VK_ESCAPE]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      MapName := '';
      CurrentState := EditState;
    end;
  end;
  if (inputKeys[LastChar]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      ChangeMapName(MapName);
    end;
  end;
end;

procedure HandleInputInEditState();
begin
  if (inputKeys[VK_NumPad1 - 48]) then
    CurrentBlock := 0;
  if (inputKeys[VK_NumPad2 - 48]) then
    CurrentBlock := 1;
  if (inputKeys[VK_NumPad3 - 48]) then
    CurrentBlock := 2;
  if (inputKeys[VK_NumPad4 - 48]) then
    CurrentBlock := 4;
  if (inputKeys[VK_NumPad5 - 48]) then
    CurrentBlock := 5;
  
  if (inputKeys[VK_DOWN] or inputKeys[VK_S]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      if ((CurrentY + 1) < 11) then
        CurrentY := CurrentY + 1;
    end;
  end;
  if (inputKeys[VK_UP] or inputKeys[VK_W]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      if ((CurrentY - 1) > 1) then
        CurrentY := CurrentY - 1;
    end;
  end;
  if (inputKeys[VK_RIGHT] or inputKeys[VK_D]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      if ((CurrentX + 1) < 15) then
        CurrentX := CurrentX + 1;
    end;
  end;
  if (inputKeys[VK_LEFT] or inputKeys[VK_A]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      if ((CurrentX - 1) > 1) then
        CurrentX := CurrentX - 1;
    end;
  end;
  if (inputKeys[VK_SPACE]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      EditModeState.Map[CurrentY, CurrentX] := CurrentBlock;
    end;
  end;
  if (inputKeys[VK_ENTER]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      CountProblem:=0;
      CurrentState := SaveState;
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

procedure HandleInputInEditor;
begin
  case CurrentState of
    EditState :
    begin
      HandleInputInEditState();
    end;
    SaveState :
    begin
      HandleInputInSaveState();
    end;
  end;
end;

procedure UpdateEditor;
begin
  HandleInputInEditor();
end;

procedure RenderInEditMode();
begin
  Window.Clear(clWhite);
  RenderGrass(0, 0, 0, TopOffset);
  for var i:=1 to EditModeState.MapY do
  begin
    for var j:=1 to EditModeState.MapX do
    begin
      case EditModeState.Map[i, j] of
        1:
        begin
          RenderIron((j - 1) * 64, (i - 1) * 64, 0, TopOffset);
        end;
        2:
        begin
          RenderBrick((j - 1) * 64, (i - 1) * 64, 0, TopOffset);
        end;
        4:
        begin
          RenderEnemySpawner((j - 1) * 64, (i - 1) * 64, 0, TopOffset);
        end;
        5:
        begin
          RenderPlayerSpawner((j - 1) * 64, (i - 1) * 64, 0, TopOffset);
        end;
      end;
    end;
  end;
  SetBrushStyle(bsClear);
  
  SetPenColor(clRed);
  SetPenWidth(5);
  Rectangle((CurrentX - 1) * 64, CurrentY * 64, (CurrentX - 1) * 64 + 64, CurrentY * 64 + 64);
  
  SetFontSize(26);
  TextOut(4, 16, 'Выбрано: ');
  
  case CurrentBlock of
    0:
    begin
      RenderGrassBlock(160, 0, 0, 0);
    end;
    1:
    begin
      RenderIron(160, 0, 0, 0);
    end;
    2:
    begin
      RenderBrick(160, 0, 0, 0);
    end;
    4:
    begin
      RenderEnemySpawner(160, 0, 0, 0);
    end;
    5:
    begin
      RenderPlayerSpawner(160, 0, 0, 0);
    end;
  end;
  
  SetBrushStyle(bsClear);
  SetPenColor(clBlue);
  SetPenWidth(5);
  Rectangle(160, 0, 160 + 64, 64);
end;

procedure RenderInSaveMode();
begin
  Window.Clear(clChocolate);
  SetBrushStyle(bsClear);
  SetFontSize(26);
  DrawTextCentered(Window.Width div 2, 128, 'Введите название карты.');
  DrawTextCentered(Window.Width div 2, 156, 'Чтобы закончить ввод - нажмите Enter.');
  TextOut(Window.Width div 2 - 372, 156 + 64, 'Название карты: ' + MapName);
  SetFontSize(8);
  for var i:=1 to CountProblem do
  begin
    TextOut(64, 156 + 88 + 25 * i, Problems[i]);
  end;
end;

procedure RenderEditor;
begin
  SetBrushStyle(bsSolid);
  case CurrentState of
    EditState :
      RenderInEditMode();
    SaveState :
      RenderInSaveMode();
  end;
end;

procedure DisposeEditor;
begin

end;

begin
  
end.