unit Renderer;

interface

procedure InitRenderer();
procedure RenderPlayer(x, y, offset_x, offset_y : integer; player_id : byte; player_name : string);
procedure RenderShield(x, y, offset_x, offset_y : integer);
procedure RenderEnemy(x, y, offset_x, offset_y : integer; enemy_type : byte);
procedure RenderGrass(x, y, offset_x, offset_y : integer);
procedure RenderGrassBlock(x, y, offset_x, offset_y : integer);
procedure RenderIron(x, y, offset_x, offset_y : integer);
procedure RenderBrick(x, y, offset_x, offset_y : integer);
procedure RenderBomb(x, y, offset_x, offset_y : integer);
procedure RenderFire(x, y, offset_x, offset_y : integer);
procedure RenderPlayerSpawner(x, y, offset_x, offset_y : integer);
procedure RenderEnemySpawner(x, y, offset_x, offset_y : integer);
procedure RenderBombIcon(x, y, offset_x, offset_y : integer);

implementation

uses
  GraphABC, GlobalVars;

const
  TileSize = 64;
  
  Player1_Sprite = 1;
  Player2_Sprite = 2;
  Bomb_Sprite = 3;
  Iron_Sprite = 4;
  Brick_Sprite = 5;
  Enemy1_Sprite = 6;
  Enemy2_Sprite = 7;
  Enemy3_Sprite = 8;
  EnemySpawner_Sprite = 9;
  PlayerSpawner_Sprite = 10;
  PlayerShield_Sprite = 11;
  Fire_Sprite = 12;
  
var
  Sprites : array[1..32] of Picture;  
  HighGraphics : boolean;
  
procedure InitRenderer();
begin
  HighGraphics := false;
  
  Sprites[Player1_Sprite]       := new Picture('assets/Player1.png');
  Sprites[Player2_Sprite]       := new Picture('assets/Player2.png');
  Sprites[Bomb_Sprite]          := new Picture('assets/Bomb.png');
  Sprites[Iron_Sprite]          := new Picture('assets/Iron.png');
  Sprites[Brick_Sprite]         := new Picture('assets/Brick.png');
  Sprites[Enemy1_Sprite]        := new Picture('assets/Enemy1.png');
  Sprites[Enemy2_Sprite]        := new Picture('assets/Enemy2.png');
  Sprites[Enemy3_Sprite]        := new Picture('assets/Enemy3.png');
  Sprites[EnemySpawner_Sprite]  := new Picture('assets/EnemyPortal.png');
  Sprites[Fire_Sprite]          := new Picture('assets/Fire.png');
  Sprites[PlayerSpawner_Sprite] := new Picture('assets/HeroPortal.png');
  Sprites[PlayerShield_Sprite]  := new Picture('assets/Shield.png');
end;

procedure RenderEnemy;
var
  sprite_id : integer;
begin
  SetBrushStyle(bsSolid);
  sprite_id := 1;
  case enemy_type of
    SlowEnemy   : sprite_id := Enemy1_Sprite;
    FastEnemy   : sprite_id := Enemy2_Sprite;
    BlowupEnemy : sprite_id := Enemy3_Sprite;
  end;
  Sprites[sprite_id].Draw(x + offset_x, y + offset_y, TileSize, TileSize);
end;

procedure RenderGrass;
begin
  SetBrushStyle(bsSolid);
  SetBrushColor(RGB(255, 219, 123));
  //Constants: 15 = MapX, 11 = MapY
  FillRectangle(x + offset_x, y + offset_y, 15 * TileSize + offset_x, 11 * TileSize + offset_y);
end;

procedure RenderGrassBlock;
begin
  SetBrushStyle(bsSolid);
  SetBrushColor(RGB(255, 219, 123));
  FillRectangle(x + offset_x, y + offset_y, x + offset_x + TileSize, y + offset_y + TileSize);
end;

procedure RenderIron;
begin
  SetBrushStyle(bsSolid);
  if (HighGraphics) then
  begin
    Sprites[Iron_Sprite].Draw(x + offset_x, y + offset_y, TileSize, TileSize);
  end
  else
  begin
    //Constants : 56 - смещение темного цвета серого
    SetBrushColor(clLightGray);
    FillRectangle(x + offset_x, y + offset_y, x + offset_x + TileSize, y + offset_y + TileSize);
    SetBrushColor(clDarkGray);
    FillRectangle(x + offset_x, y + offset_y + 56, x + offset_x + TileSize, y + offset_y + TileSize);
    FillRectangle(x + offset_x + 56, y + offset_y, x + offset_x + TileSize, y + offset_y + TileSize);
  end;
end;

procedure RenderBrick;
begin
  SetBrushStyle(bsSolid);
  if (HighGraphics) then
  begin
    Sprites[Brick_Sprite].Draw(x + offset_x, y + offset_y, TileSize, TileSize);
  end
  else
  begin
    SetBrushColor(clOrangeRed);
    FillRectangle(x + offset_x, y + offset_y, x + offset_x + TileSize, y + offset_y + TileSize);
  end;
end;

procedure RenderBomb;
begin
  SetBrushStyle(bsSolid);
  Sprites[Bomb_Sprite].Draw(x + offset_x, y + offset_y, TileSize, TileSize);
end;

procedure RenderBombIcon;
begin
  SetBrushStyle(bsSolid);
  Sprites[Bomb_Sprite].Draw(x + offset_x, y + offset_y, 32, 32);
end;

procedure RenderPlayer;
begin
  SetBrushStyle(bsClear);
  SetFontSize(8);
  DrawTextCentered(x + offset_x + TileSize div 2, y + offset_y, player_name);
  //Constants: 1 - номер первого игрока
  if (player_id = 1) then
  begin
    Sprites[Player1_Sprite].Draw(x + offset_x, y + offset_y, TileSize, TileSize);
  end
  else
  begin
    Sprites[Player2_Sprite].Draw(x + offset_x, y + offset_y, TileSize, TileSize);
  end; 
end;

procedure RenderShield;
begin
  SetBrushStyle(bsSolid);
  Sprites[PlayerShield_Sprite].Draw(x + offset_x, y + offset_y, TileSize, TileSize);
end;

procedure RenderFire;
begin
  Sprites[Fire_Sprite].Draw(x + offset_X, y + offset_Y, TileSize, TileSize);
end;

procedure RenderPlayerSpawner;
begin
  SetBrushStyle(bsSolid);
  Sprites[PlayerSpawner_Sprite].Draw(x + offset_x, y + offset_y, TileSize, TileSize);
end;

procedure RenderEnemySpawner;
begin
  SetBrushStyle(bsSolid);
  Sprites[EnemySpawner_Sprite].Draw(x + offset_x, y + offset_y, TileSize, TileSize);
end;

begin
  
end.