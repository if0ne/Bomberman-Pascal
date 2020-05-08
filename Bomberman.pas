program Bomberman;

uses
  GraphABC, GlobalVars, Menu, Help, Highscore, MapMenu, InputNames, MainGame, Editor, UIAssets, Renderer; 

var
  CurrentTime, LastTime : longint;
  DeltaTime : integer;
 
procedure HandleKeyDown(key : integer);
begin
  inputKeys[key] := true;
  LastChar := key;
end;  

procedure HandleKeyUp(key : integer);
begin
  inputKeys[key] := false;
end;  

procedure Update(dt : integer);
begin
  case _CurrentState of
    MenuState :
    begin
      UpdateMenu(dt);
    end;
    HelpState :
    begin
      UpdateHelp(dt);
    end;
    HighscoreState :
    begin
      UpdateHighscore(dt);
    end;
    ChooseMapState :
    begin
      UpdateMapMenu(dt);
    end;
    InputNamesState :
    begin
      UpdateInputNames(dt);
    end;
    MainGameState :
    begin
      UpdateMainGame(dt);
    end;
    EndHighState :
    begin
      UpdateNewHighscore(dt);
    end;
    EditorState :
    begin
      UpdateEditor(dt);
    end;
  end;
end;

procedure Render();
begin
  case _CurrentState of
    MenuState :
    begin
      RenderMenu();
    end;
    HelpState :
    begin
      RenderHelp();
    end;
    HighscoreState :
    begin
      RenderHighscore();
    end;
    ChooseMapState :
    begin
      RenderMapMenu();
    end;
    InputNamesState :
    begin
      RenderInputNames();
    end;
    MainGameState :
    begin
      RenderMainGame();
    end;
    EndHighState :
    begin
      RenderNewHighscore();
    end;
    EditorState :
    begin
      RenderEditor();
    end;
  end;
end;  
  
begin
  SetSmoothingOff();
  Randomize();
  
  InitAssets();
  InitRenderer();
  
  OnKeyDown := HandleKeyDown;
  OnKeyUp   := HandleKeyUp;
  
  SetWindowIsFixedSize(true);
  LockDrawing();
  LastChange := Milliseconds();
  
  ChangeState(MenuState);
  Window.CenterOnScreen();
  
  IsQuit := false; 
  DeltaTime := 0;
  
  SetFontName('Consolas');

  while (not IsQuit) do
  begin
    CurrentTime := Milliseconds();
    Update(DeltaTime);
    Render();
    Redraw();
    LastTime := Milliseconds();
    DeltaTime := LastTime - CurrentTime;
    if (DeltaTime <> 0) then
    begin
      SetWindowTitle('Bomberman (FPS:' + Trunc(1/DeltaTime * 1000) + ')');
    end;
    if (17 - DeltaTime >= 0) then
    begin
      Sleep(17 - DeltaTime);
    end;
  end;
  UnlockDrawing();
  Window.Clear();
  Window.Close();
end.