unit Renderer;

interface

{Процедура инциализации рендера }
procedure InitRenderer();
{Процедура рисования игрока                                         }
{Параметры: x, y - позиция, offset_x, offset_y - смещение на экране }
{           player_id - номер игрока, player_name - имя игрока      }
procedure RenderPlayer(x, y, offset_x, offset_y : integer; player_id : byte; player_name : string);
{Процедура рисования щита                                           }
{Параметры: x, y - позиция, offset_x, offset_y - смещение на экране }
procedure RenderShield(x, y, offset_x, offset_y : integer);
{Процедура рисования врага                                          }
{Параметры: x, y - позиция, offset_x, offset_y - смещение на экране }
{           enemy_type - тип монстра                                }
procedure RenderEnemy(x, y, offset_x, offset_y : integer; enemy_type : byte);
{Процедура рисования земли                                          }
{Параметры: x, y - позиция, offset_x, offset_y - смещение на экране }
procedure RenderGrass(x, y, offset_x, offset_y : integer);
{Процедура рисования блока земли                                    }
{Параметры: x, y - позиция, offset_x, offset_y - смещение на экране }
procedure RenderGrassBlock(x, y, offset_x, offset_y : integer);
{Процедура рисования неломаемых блоков                              }
{Параметры: x, y - позиция, offset_x, offset_y - смещение на экране }
procedure RenderIron(x, y, offset_x, offset_y : integer);
{Процедура рисования ломаемых блоков                                }
{Параметры: x, y - позиция, offset_x, offset_y - смещение на экране }
procedure RenderBrick(x, y, offset_x, offset_y : integer);
{Процедура рисования бомб                                           }
{Параметры: x, y - позиция, offset_x, offset_y - смещение на экране }
procedure RenderBomb(x, y, offset_x, offset_y : integer);
{Процедура рисования огня                                           }
{Параметры: x, y - позиция, offset_x, offset_y - смещение на экране }
procedure RenderFire(x, y, offset_x, offset_y : integer);
{Процедура рисования портала игроков                                }
{Параметры: x, y - позиция, offset_x, offset_y - смещение на экране }
procedure RenderPlayerSpawner(x, y, offset_x, offset_y : integer);
{Процедура рисования портала монстров                               }
{Параметры: x, y - позиция, offset_x, offset_y - смещение на экране }
procedure RenderEnemySpawner(x, y, offset_x, offset_y : integer);
{Процедура рисования иконки бомбы                                   }
{Параметры: x, y - позиция, offset_x, offset_y - смещение на экране }
procedure RenderBombIcon(x, y, offset_x, offset_y : integer);

implementation

uses
  GraphABC, GlobalVars;

const
  TileSize = 64;            
  
  Player1_Sprite = 1;        //Номер первого игрока
  Player2_Sprite = 2;        //Номер второго игрока
  Bomb_Sprite = 3;           //Номер бомбы
  Iron_Sprite = 4;           //Номер неломаемого блока
  Brick_Sprite = 5;          //Номер ломаемого блока
  Enemy1_Sprite = 6;         //Номер обычного монстра
  Enemy2_Sprite = 7;         //Номер быстрого монстра
  Enemy3_Sprite = 8;         //Номер взрывного монстра 
  EnemySpawner_Sprite = 9;   //Номер портала монстра
  PlayerSpawner_Sprite = 10; //Номер портала игрока
  PlayerShield_Sprite = 11;  //Номер щита игрока
  Fire_Sprite = 12;          //Номер огня
  
var
  Sprites : array[1..12] of Picture; //Массив всех картинок
  HighGraphics : boolean;            //Использовать спрайты для блоков или нет
  
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