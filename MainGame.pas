unit MainGame;

interface

{Процедура инциализации сцены игры }
procedure InitMainGame();
{Процедура отлова нажатия клавиш сцене игры }
procedure HandleInputInMainGame();
{Процедура обновления логики в сцене игры }
procedure UpdateMainGame(dt : integer);
{Процедура отрисовки ввода сцены игры }
procedure RenderMainGame();
{Процедура очистки данных сцены игры }
procedure DisposeMainGame();


implementation

uses
  GraphABC, GlobalVars, Renderer, UIAssets;

const
  
  SpawnDelay  = 1000; //Задержка спавна монстров
  
  ToUp    = 1; //Направление вверх
  ToRight = 2; //Направление вправо
  ToDown  = 3; //Направление вниз
  ToLeft  = 4; //Направление влево
  
type
  {Запись физического объекта, который взаимодействует с другими физическими объектами }
  Collider = record
      _x       : integer;
      _y       : integer;
      _w       : integer;
      _h       : integer;
      _offsetX : integer;
      _offsetY : integer;
      Pooled   : boolean;
      ColId    : word;
    end;
  {Запись координат объекта }
  Transform = record
    _x : integer;
    _y : integer;
  end;
  {Запись игрока }
  Player = record
    _col        : Collider;
    _pos        : Transform;
    _sprite     : word = 1;
    
    Speed       : word;
    Up          : word;
    Left        : word;
    Down        : word;
    Right       : word;
    Place       : word;
    
    PlayerId    : byte;
    PlayerScore : integer;
    BombCount   : byte;
    
    Respawn     : integer;
    IsDead      : boolean;
    Immortal    : integer;
    IsImmortal  : boolean;
    Name        : string;
  end;
  {Запись врага }
  Enemy = record
    _col          : Collider;
    _pos          : Transform;
    _sprite       : word;
    
    Speed         : word;
    Respawn       : integer;
    IsDead        : boolean;
    
    EnemyType     : byte;
    Direction     : byte;
    LastChange    : integer;
    NeedChange    : boolean;
    CurPosInArray : Transform;
    NewPosInArray : Transform;
  end;
  {Запись бомбы }
  Bomb = record
    _col      : Collider;
    _pos      : Transform;
    _sprite   : word = 2;
    Time      : integer;
    Pooled    : boolean;
    PlayerId  : byte;
    IsAddable : boolean;
  end;
  {Запись неломаемого блока }
  Iron = record
    _col    : Collider;
    _pos    : Transform;
    _sprite : word = 3;
  end;
  {Запись ломаемого блока }
  Brick = record
    _col    : Collider;
    _pos    : Transform;
    _sprite : word = 4;
    Pooled  : boolean;
  end;
  {Запись огня}
  Fire = record
    _pos     : Transform;
    _sprite  : word = 6;
    Time     : integer;
    Pooled   : boolean;
    PlayerId : byte;
  end;
  {Запись состояния сцены игры }
  GameState = record
    Players          : array[1..MaxPlayers] of Player;

    Map              : array[1..20, 1..20] of integer;
    MapX             : word;
    MapY             : word;
   
    ColliderMap      : array[1..255] of Collider;
    ColCount         : word;
    
    IronMap          : array[1..255] of Iron;
    IronCount        : word;
    
    BrickMap         : array[1..255] of Brick;
    BrickCount       : word;
    
    BombMap          : array[1..63] of Bomb;
    BombCount        : word;
    
    FireMap          : array[1..255] of Fire;
    FireCount        : word;
    
    SpawnPoints      : array[1..8] of Transform;
    SpawnCount       : word;
    
    SpawnEnemies     : array[1..4] of Transform;
    SpawnCountEnemy  : word;
    Enemies          : array[1..6] of Enemy;
    
    CurrentMap       : string;
    
  end;

var
  GameplayState : GameState;       //Сцена игры
  MainTime : longint;              //Оставшиеся время игры
  SpawnCooldown : longint;         //Время смерти монстров
  
  IsPause : boolean;               //Поставлена пауза или нет
  Options : array[1..2] of string; //Кнопки в паузе
  CurrentOp : byte;                //Текущая кнопка

{Процедура уменьшения времени игры   }
{Параметры: dt - время между кадрами }  
procedure Countdown(dt : integer);
begin
  MainTime := MainTime - dt;
end;

{Процедура уменьшения времени взрыва бомбы }
{Параметры: dt - время между кадрами       } 
procedure Bombdown(dt : integer);
begin
  for var i:=1 to GameplayState.BombCount do
  begin
    if (GameplayState.BombMap[i].Pooled) then
    begin
      GameplayState.BombMap[i].Time := GameplayState.BombMap[i].Time - dt;
    end;
  end;
end;

{Процедура уменьшения существования огня }
{Параметры: dt - время между кадрами     } 
procedure Firedown(dt : integer);
begin
  for var i:=1 to GameplayState.FireCount do
  begin
    if (GameplayState.FireMap[i].Pooled) then
    begin
      GameplayState.FireMap[i].Time := GameplayState.FireMap[i].Time - dt;
    end;
  end;
end;

{Процедура уменьшения времени спавнка игрока }
{Параметры: dt - время между кадрами         } 
procedure Respawndown(dt : integer);
begin
  for var i:=1 to MaxPlayers do
  begin
    if (GameplayState.Players[i].IsDead) then
    begin
      GameplayState.Players[i].Respawn := GameplayState.Players[i].Respawn - dt;
    end;
  end;
end;

{Процедура уменьшения времени щита игрока }
{Параметры: dt - время между кадрами      } 
procedure Immortaldown(dt : integer);
begin
  for var i:=1 to MaxPlayers do
  begin
    if (GameplayState.Players[i].IsImmortal) then
    begin
      GameplayState.Players[i].Immortal := GameplayState.Players[i].Immortal - dt;
      if (GameplayState.Players[i].Immortal <= 0) then
        GameplayState.Players[i].IsImmortal := false;
    end;
  end;
end;

{Процедура проверки сталковения двух коллайдеров (Алгоритм AABB) }
{Параметры: first, second - физические объекты                   } 
function IsCollide(first, second : Collider) : boolean;
begin
  if ((first.Pooled = false) or (second.Pooled = false)) then
  begin
    IsCollide := false;
  end
  else
  begin
    if (((first._x + first._w + first._offsetX) <= (second._x + second._offsetX)) 
    or ((first._x + first._offsetX) >= (second._x + second._w + second._offsetX))) then
    begin
      IsCollide := false;
    end
    else
    if (((first._y + first._h + first._offsetY) <= (second._y + second._offsetY)) 
    or ((first._y + first._offsetY) >= (second._y + second._h + + second._offsetY))) then
    begin
      IsCollide := false;
    end
    else
    begin
      IsCollide := true;
    end;
  end;
end;

{Функция создания физического объекта                          }
{Параметры: x, y - позиция, offsetX, offsetY - смещение,       }
{           w, h - ширина, высота, isPooled - активный или нет } 
function CreateCollider(x, y, offsetX, offsetY, h, w : integer; isPooled : boolean) : Collider;
begin
  var temp : Collider;
  temp._x := x;
  temp._y := y;
  temp._offsetX := offsetX;
  temp._offsetY := offsetY;
  temp._h := h;
  temp._w := w;
  temp.Pooled := isPooled;
  Inc(GameplayState.colCount);
  temp.ColId := GameplayState.colCount;
  GameplayState.ColliderMap[GameplayState.colCount] := temp;
  CreateCollider := temp;
end;

{Функция попытки убить игрока }
{Параметры: _player - игрок   }
function TryKillPlayer(var _player : Player) : boolean;
begin
  TryKillPlayer := false;
  if (not _player.IsImmortal) then
  begin
    _player.Respawn := 2000;
    _player.IsDead := true;
    TryKillPlayer := true;
  end;
end;

{Функция проверки столкновений с врагами       }
{Параметры: _player - физический объект игрока }
function CheckCollisionWithEnemy(_player : Collider) : boolean;
begin
  CheckCollisionWithEnemy := false;
  for var i:=1 to 6 do
  begin
    if (IsCollide(_player, GameplayState.Enemies[i]._col)) then
    begin
      CheckCollisionWithEnemy := true;
      exit;
    end;
  end;
end;

{Функция проверки столкновений с блоками       }
{Параметры: entity - физический объект игрока  }
function CheckCollision(entity : Collider) : boolean;
begin
  CheckCollision:=false;
  for var i:=1 to GameplayState.ColCount do
  begin
    if (IsCollide(entity, GameplayState.ColliderMap[i])) then
    begin
      CheckCollision:=true;
      exit;
    end;
  end;
end;

{Функция проверки существует бомба на данный позиции или нет }
{Параметры: _bomb - добавляемая бомба                        }
function ContainsBomb(_bomb : Bomb) : boolean;
begin
  ContainsBomb := false;
  for var i := 1 to GameplayState.BombCount do
  begin
    if ((_bomb._pos._x = GameplayState.BombMap[i]._pos._x) and 
    (_bomb._pos._y = GameplayState.BombMap[i]._pos._y) and 
    GameplayState.BombMap[i].Pooled = true) then
    begin
      ContainsBomb := true;
      exit;
    end;
  end;
end;

{Функция получения свободного индекса бомбы в массиве }
function GetFirstPooledBomb() : word;
begin
  for var i:=1 to GameplayState.BombCount do
  begin
    if (GameplayState.BombMap[i].Pooled = false) then
    begin
      GetFirstPooledBomb := i;
      exit;
    end;
    if (i = GameplayState.BombCount) then
    begin
      GetFirstPooledBomb := i + 1;
      GameplayState.BombCount := GameplayState.BombCount + 1;
      exit;
    end;
  end;
  if (GameplayState.BombCount = 0) then
  begin
    GameplayState.BombCount := GameplayState.BombCount + 1;
    GetFirstPooledBomb := 1;
  end;
end;

{Процедура создания бомбы                                        }
{Параметры: x, y - позиция, playerId - номер игрока              }
{           byPlayer - бомба игрока или нет, time - время взрыва } 
procedure CreateBomb(x, y : integer; playerId : word; byPlayer : boolean; time : integer);
begin
  var _x := (x + 32) div 64 * 64;
  var _y := (y + 32) div 64 * 64;
  var temp : Bomb;
  temp._pos._x := _x;
  temp._pos._y := _y;
  temp._col._h := 64;
  temp._col._w := 64;
  temp._col._x := _x;
  temp._col._y := _y;
  temp.Pooled := true;
  temp.IsAddable := byPlayer;
  temp.Time := time;
  temp.PlayerId := playerId;
  if (not ContainsBomb(temp)) then
  begin
    Dec(GameplayState.Players[playerId].BombCount);
    var index := GetFirstPooledBomb();
    GameplayState.BombMap[index] := temp;
  end;
end;

{Процедура управления игроком                                           }
{Параметры: movablePlayer - управляемый игрок, dt - время между кадрами }
procedure MovePlayer(var movablePlayer : Player; dt : integer);
begin
  if (not movablePlayer.IsDead) then
  begin
    var newCol : Collider;
    newCol := movablePlayer._col;
    if (inputKeys[movablePlayer.Up]) then
    begin
      newCol._y := newCol._y - round(movablePlayer.Speed * dt / 1000);
    end
    else if (inputKeys[movablePlayer.Left]) then
    begin
      newCol._x := newCol._x - round(movablePlayer.Speed * dt / 1000);
    end
    else if (inputKeys[movablePlayer.Down]) then
    begin
      newCol._y := newCol._y + round(movablePlayer.Speed * dt / 1000);
    end
    else if (inputKeys[movablePlayer.Right]) then
    begin
      newCol._x := newCol._x + round(movablePlayer.Speed * dt / 1000);
    end;
    if (not CheckCollision(newCol)) then
    begin
      movablePlayer._col := newCol;
      movablePlayer._pos._x := newCol._x;
      movablePlayer._pos._y := newCol._y;
    end;
    if (inputKeys[movablePlayer.Place]) then
    begin
      if (movablePlayer.BombCount > 0) then
      begin
        CreateBomb(movablePlayer._pos._x, movablePlayer._pos._y, movablePlayer.PlayerId, true, 3000);
      end;
    end;
    if ((CheckCollisionWithEnemy(movablePlayer._col))) then
    begin
      if (TryKillPlayer(movablePlayer)) then
      begin
        movablePlayer.PlayerScore := movablePlayer.PlayerScore - 3;
      end;
    end;
  end;
end;

{Функция получения свободного индекса огня в массиве }
function GetFirstPooledFire() : word;
begin
  for var i:=1 to GameplayState.FireCount do
  begin
    if (GameplayState.FireMap[i].Pooled = false) then
    begin
      GetFirstPooledFire := i;
      exit;
    end;
    if (i = GameplayState.FireCount) then
    begin
      GetFirstPooledFire := i + 1;
      GameplayState.FireCount := GameplayState.FireCount + 1;
      exit;
    end;
  end;
  if (GameplayState.FireCount = 0) then
  begin
    GameplayState.FireCount := GameplayState.FireCount + 1;
    GetFirstPooledFire := 1;
  end;
end;

{Фукнция создания огня                                           }
{Параметры: x, y - позиция, nx, ny - смещение огня               }
{           playerId - номер игрока                              } 
function CreateFire(x, y, nx, ny : integer; playerId : word) : Fire;
begin
  var _x := x div 64;
  var _y := y div 64;
  var _fire : Fire;
  _fire._pos._x := (_x + nx) * 64;
  _fire._pos._y := (_y + ny) * 64;
  _fire.PlayerId := playerId;
  _fire.Pooled := true;
  _fire.Time := 300;
  var _index := GetFirstPooledFire();
  GameplayState.FireMap[_index] := _fire;
  CreateFire := _fire;
end;

{Фукнция взрыва клетки                                           }
{Параметры: _fire - огонь на клетке                              }
function BlowUpCell(_fire : Fire) : boolean;
begin
  var _x := _fire._pos._x div 64 + 1;
  var _y := _fire._pos._y div 64 + 1;
  BlowUpCell := false;
  
  for var i:=1 to 6 do
  begin
    if ((((GameplayState.Enemies[i]._pos._x + 32) div 64 + 1) = _x) and (((GameplayState.Enemies[i]._pos._y + 32) div 64 + 1) = _y)) then
    begin
      if (not GameplayState.Enemies[i].IsDead) then
      begin
        BlowUpCell := true;
        GameplayState.Players[_fire.PlayerId].PlayerScore := GameplayState.Players[_fire.PlayerId].PlayerScore + 3;
        GameplayState.Enemies[i].IsDead := true;
        GameplayState.Enemies[i].Respawn := 3000;
        GameplayState.Enemies[i]._col.Pooled := false;
        if (GameplayState.Enemies[i].EnemyType = BlowupEnemy) then
        begin
          CreateBomb(GameplayState.Enemies[i]._pos._x, GameplayState.Enemies[i]._pos._y, _fire.PlayerId, false, 20);
        end;
      end;
    end;
  end;
  
  if (GameplayState.Map[_y, _x] = 1) then
  begin
    BlowUpCell := true;
    exit;
  end
  else
  if (GameplayState.Map[_y, _x] = 2) then
  begin
    GameplayState.Map[_y, _x] := 0;
    for var i:=1 to GameplayState.BrickCount do
    begin
      if ((GameplayState.BrickMap[i]._pos._x = _fire._pos._x) and
      (GameplayState.BrickMap[i]._pos._y = _fire._pos._y) and
      GameplayState.BrickMap[i].Pooled) then
      begin
        BlowUpCell := true;
        GameplayState.ColliderMap[GameplayState.BrickMap[i]._col.ColId].Pooled := false; 
        GameplayState.BrickMap[i].Pooled := false;
        
        GameplayState.Players[_fire.PlayerId].PlayerScore := GameplayState.Players[_fire.PlayerId].PlayerScore + 1;
        exit;
      end;
    end;
  end;

  for var i:=1 to MaxPlayers do
  begin
    if ((((GameplayState.Players[i]._pos._x + 32) div 64 + 1) = _x) and 
    (((GameplayState.Players[i]._pos._y + 32) div 64 + 1) = _y) and
    not GameplayState.Players[i].IsDead) then
    begin
      BlowUpCell := true;
      if (TryKillPlayer(GameplayState.Players[i])) then
      begin
        if (_fire.PlayerId <> GameplayState.Players[i].PlayerId) then
        begin
          GameplayState.Players[_fire.PlayerId].PlayerScore := GameplayState.Players[_fire.PlayerId].PlayerScore + 10;
        end;
        GameplayState.Players[i].PlayerScore := GameplayState.Players[i].PlayerScore - 3;
      end;
    end;
  end;
end;

{Процедура взрыва бомбы                                           }
{Параметры: _bomb - бомба, waveSize - длина волны взрыва          }
procedure ExplodeBomb(_bomb : Bomb; waveSize : word);
begin
  var center := CreateFire(_bomb._pos._x, _bomb._pos._y, 0, 0, _bomb.PlayerId);
  if (not BlowUpCell(center)) then
  begin
    //To Up
    for var i:=1 to waveSize do
    begin
      var temp := CreateFire(_bomb._pos._x, _bomb._pos._y, 0, -i, _bomb.PlayerId);
      if (BlowUpCell(temp)) then
      begin
        break;
      end;
    end;
    //To Down
    for var i:=1 to waveSize do
    begin
      var temp := CreateFire(_bomb._pos._x, _bomb._pos._y, 0, i, _bomb.PlayerId);
      if (BlowUpCell(temp)) then
      begin
        break;
      end;
    end;
    //To Left
    for var i:=1 to waveSize do
    begin
      var temp := CreateFire(_bomb._pos._x, _bomb._pos._y, -i, 0, _bomb.PlayerId);
      if (BlowUpCell(temp)) then
      begin
        break;
      end;
    end;
    //To Right
    for var i:=1 to waveSize do
    begin
      var temp := CreateFire(_bomb._pos._x, _bomb._pos._y, i, 0, _bomb.PlayerId);
      if (BlowUpCell(temp)) then
      begin
        break;
      end;
    end;
  end;
end;

{Процедура обновления огня           }
{Параметры: dt - время между кадрами }  
procedure UpdateFire(dt : integer);
begin
  for var i:=1 to GameplayState.FireCount do
  begin
    if ((GameplayState.FireMap[i].Time <= 0) and (GameplayState.FireMap[i].Pooled)) then
    begin
      GameplayState.FireMap[i].Pooled := false;
    end;
  end;
end;

{Процедура обновления бомб           }
{Параметры: dt - время между кадрами }  
procedure UpdateBomb(dt : integer);
begin
  for var i:=1 to GameplayState.BombCount do
  begin
    if ((GameplayState.BombMap[i].Time <= 0) and (GameplayState.BombMap[i].Pooled)) then
    begin
      if (i = GameplayState.BombCount) then
      begin
        GameplayState.BombCount := GameplayState.BombCount - 1;
      end
      else
      begin
        GameplayState.BombMap[i].Pooled := false;
      end;
      
      Inc(GameplayState.Players[GameplayState.BombMap[i].PlayerId].BombCount);
      if (GameplayState.Players[GameplayState.BombMap[i].PlayerId].BombCount > 3) then
        GameplayState.Players[GameplayState.BombMap[i].PlayerId].BombCount := 3;
      
      if (GameplayState.BombMap[i].IsAddable) then
      begin
        ExplodeBomb(GameplayState.BombMap[i], 2);
      end
      else
      begin
        ExplodeBomb(GameplayState.BombMap[i], 1);
      end;
      
    end;
  end;
end;

{Функция проверки, свободно на клетке или нет           }
{Параметры: x, y - координаты в двумерном массиве       }  
function IsEmpty(x, y : integer) : boolean;
begin
  if (x > 0) and (x < 16) and (y > 0) and (y < 12) then
  begin
    if ((GameplayState.Map[y, x] = 1) or (GameplayState.Map[y, x] = 2)) then
    begin
      IsEmpty := false;
    end
    else
    begin
      IsEmpty := true;
    end;
  end;
end;

{Функция проверки, свободно в определенном направлении для монстра }
{Параметры: _enemy - враг, dir - направление                       }  
function IsEmptyForEnemy(_enemy : Enemy; dir : integer) : boolean;
begin
  IsEmptyForEnemy := true;
  case Dir of
    ToUp:
    begin
      if (not IsEmpty(_enemy.CurPosInArray._x, _enemy.CurPosInArray._y - 1)) then
        IsEmptyForEnemy := false;
    end;
    ToDown:
    begin
      if (not IsEmpty(_enemy.CurPosInArray._x, _enemy.CurPosInArray._y + 1)) then
        IsEmptyForEnemy := false;
    end;
    ToRight:
    begin
      if (not IsEmpty(_enemy.CurPosInArray._x + 1, _enemy.CurPosInArray._y)) then
        IsEmptyForEnemy := false;
    end;
    ToLeft:
    begin
      if (not IsEmpty(_enemy.CurPosInArray._x - 1, _enemy.CurPosInArray._y)) then
        IsEmptyForEnemy := false;
    end;
  end;
end;

{Функция проверки, мертвы ли другие игроки или нет }
{Параметры: playerId - номер спавнящегося игрока   }  
function AreOtherDead(playerId : integer) : boolean;
var
  deadCount : integer;
begin
  deadCount := 0;
  for var i:=1 to MaxPlayers do
  begin
    if (GameplayState.Players[i].PlayerId <> playerId) then
    begin
      if (GameplayState.Players[i].IsDead) then
        Inc(deadCount);
    end;
  end;
  if (deadCount = (MaxPlayers - 1)) then
    AreOtherDead := true
  else
    AreOtherDead := false;
end;

{Процедура получения самой опасной координаты                }
{Параметры: x, y - координаты точки, playerId - номер игрока }  
procedure GetDangerousPoint(var x, y : integer; playerId : integer);
var
  n : integer;
begin
  x := 0;
  y := 0;
  n := 0;
  for var i:=1 to MaxPlayers do
  begin
    if (GameplayState.Players[i].PlayerId <> playerId) then
    begin
      if (not GameplayState.Players[i].IsDead) then
      begin
        Inc(n);
        x += GameplayState.Players[i]._pos._x;
        y += GameplayState.Players[i]._pos._y;
      end;
    end;
  end;
  for var i:=1 to 6 do
  begin
    if (not GameplayState.Enemies[i].IsDead) then
    begin
      Inc(n);
      x += GameplayState.Enemies[i]._pos._x;
      y += GameplayState.Enemies[i]._pos._y;
    end;
  end;
  x := Round(x / n);
  y := Round(y / n);
end;

{Процедура спавна игрока                }
{Параметры: _player - спавнящийся игрок }  
procedure SpawnPlayer(var _player : Player);
begin
  var trans, dang : Transform;
  if (AreOtherDead(_player.PlayerId)) then
  begin
    trans := GameplayState.SpawnPoints[Random(1, GameplayState.SpawnCount)];
  end
  else
  begin
    GetDangerousPoint(dang._x, dang._y, _player.PlayerId);
    var max := sqrt(sqr(dang._x - GameplayState.SpawnPoints[1]._x) +
    sqr(dang._y - GameplayState.SpawnPoints[1]._y));
    var id := 1;
    for var i:=2 to GameplayState.SpawnCount do
    begin
      if (max < sqrt(sqr(dang._x - GameplayState.SpawnPoints[i]._x) +
      sqr(dang._y - GameplayState.SpawnPoints[i]._y))) then
      begin
        max := sqrt(sqr(dang._x - GameplayState.SpawnPoints[i]._x) +
               sqr(dang._y - GameplayState.SpawnPoints[i]._y));
        id := i;
      end;
    end;
    trans := GameplayState.SpawnPoints[id];
  end;
  _player._pos._x := trans._x;
  _player._pos._y := trans._y;
  _player._col._x := trans._x;
  _player._col._y := trans._y;
  _player._col.Pooled := true;
  _player.IsDead := false;
  _player.Respawn := 0;
  _player.IsImmortal := true;
  _player.Immortal := 1500;
end;

{Процедура спавна врага       }
{Параметры: x, y - координаты }  
procedure SpawnEnemy(var _enemy : Enemy; x, y:integer);
begin
  with _enemy do
  begin
    _col._x := x;
    _col._y := y;
    _col._h := 32;
    _col._w := 32;
    _col._offsetX := 16;
    _col._offsetY := 16;
    _col.Pooled := true;
    _pos._x := x;
    _pos._y := y;
    NewPosInArray._x := x div 64 + 1;
    NewPosInArray._y := y div 64 + 1;
    IsDead := false;
    NeedChange := true;
    EnemyType := Random(1, 3);
    if (EnemyType = FastEnemy) then
    begin
      Speed := 150;
      _sprite := 6;
    end
    else
    if (EnemyType = SlowEnemy) then
    begin
      Speed := 125;
      _sprite := 7;
    end
    else
    if (EnemyType = BlowupEnemy) then
    begin
      Speed := 125;
      _sprite := 8;
    end;
    Respawn := 0;
    CurPosInArray._x := x div 64 + 1;
    CurPosInArray._y := y div 64 + 1;
    Direction := Random(1, 4);
  end;
end;

{Процедура попытки смены направления движения врага }
{Параметры: _enemy - враг                           }  
procedure TryToChangeDir(var _enemy : Enemy);
begin
  if ((_enemy.Direction = ToRight) or (_enemy.Direction = ToLeft)) then
  begin
    if (IsEmptyForEnemy(_enemy, ToUp) and IsEmptyForEnemy(_enemy, ToDown)) then
    begin
      var dir := Random(1, 2);
      if (dir = 1) then
      begin
        _enemy.Direction := ToUp;
      end
      else
      begin
        _enemy.Direction := ToDown;
      end;
    end
    else
    if (IsEmptyForEnemy(_enemy, ToUp)) then
    begin
      _enemy.Direction := ToUp;
    end
    else
    if (IsEmptyForEnemy(_enemy, ToDown)) then
    begin
      _enemy.Direction := ToDown;
    end;   
  end
  else
  begin
    if (IsEmptyForEnemy(_enemy, ToLeft) and IsEmptyForEnemy(_enemy, ToRight)) then
    begin
      var dir := Random(1, 2);
      if (dir = 1) then
      begin
        _enemy.Direction := ToLeft;
      end
      else
      begin
        _enemy.Direction := ToRight;
      end;
    end
    else
    if (IsEmptyForEnemy(_enemy, ToLeft)) then
    begin
      _enemy.Direction := ToLeft;
    end
    else
    if (IsEmptyForEnemy(_enemy, ToRight)) then
    begin
      _enemy.Direction := ToRight;
    end;   
  end;
end;

{Функция получения координат в двумерном массиве врага  }
{Параметры: _enemy - враг                               }  
function GetCurPosInArr(var _enemy : Enemy) : Transform;
begin
  var trans : Transform;
  if (((_enemy._pos._x + 58) div 64 + 1) <> _enemy.NewPosInArray._x) and ((_enemy._pos._x div 64 + 1) <> _enemy.NewPosInArray._x) then
  begin
    _enemy.NewPosInArray._x := _enemy._pos._x div 64 + 1;
  end;
  if (((_enemy._pos._y + 58) div 64 + 1) <> _enemy.NewPosInArray._y) and ((_enemy._pos._y div 64 + 1) <> _enemy.NewPosInArray._y)then
  begin
    _enemy.NewPosInArray._y := _enemy._pos._y div 64 + 1;
  end;
  trans._x := _enemy.NewPosInArray._x;
  trans._y := _enemy.NewPosInArray._y;
  GetCurPosInArr := trans;
end;

{Функция проверки координаты врага на новые координаты }
{Параметры: _enemy - враг      }  
function CheckEnemyPosition(var _enemy : Enemy) : boolean;
begin
  var x := _enemy.CurPosInArray._x;
  var y := _enemy.CurPosInArray._y;
  var newPos := GetCurPosInArr(_enemy);
  if ((x <> newPos._x) or (y <> newPos._y)) then
  begin
    CheckEnemyPosition := true;
    _enemy.CurPosInArray._x := newPos._x;
    _enemy.CurPosInArray._y := newPos._y;
  end
  else
  begin
    CheckEnemyPosition := false;
  end;
end;

{Процедура обновления респавна игроков }
{Параметры: dt - время между кадрами   }  
procedure UpdateRespawn(dt : integer);
begin
  for var i:=1 to MaxPlayers do
  begin
    if ((GameplayState.Players[i].Respawn <= 0) and (GameplayState.Players[i].IsDead)) then
    begin
      SpawnPlayer(GameplayState.Players[i]);
    end;
  end;
end;

{Процедура обновления респавна врагов }
{Параметры: dt - время между кадрами  } 
procedure UpdateRespawnEnemies(dt : integer);
begin
  for var i:=1 to 6 do
  begin
    if ((GameplayState.Enemies[i].Respawn > 0) and (GameplayState.Enemies[i].IsDead)) then
    begin
      GameplayState.Enemies[i].Respawn := GameplayState.Enemies[i].Respawn - dt;
    end
    else
    begin
      if (Milliseconds() - SpawnCooldown > SpawnDelay) then
      begin
        if (GameplayState.Enemies[i].IsDead) then
        begin
          SpawnCooldown := Milliseconds();
          var trans : Transform;
          trans := GameplayState.SpawnEnemies[Random(1, GameplayState.SpawnCountEnemy)];
          SpawnEnemy(GameplayState.Enemies[i], trans._x, trans._y);
        end;
      end;
    end;
  end;
end;

{Процедура обновления врагов           }
{Параметры: dt - время между кадрами   } 
procedure UpdateEnemy(dt : integer);
begin
  for var i:=1 to 6 do
  begin
    if (not GameplayState.Enemies[i].IsDead) then
    begin
      GetCurPosInArr(GameplayState.Enemies[i]);
      if (GameplayState.Enemies[i].NeedChange) then
      begin
        TryToChangeDir(GameplayState.Enemies[i]);
        GameplayState.Enemies[i].NeedChange := false;
      end
      else
      begin
        if (IsEmptyForEnemy(GameplayState.Enemies[i], GameplayState.Enemies[i].Direction)) then
        begin
          case GameplayState.Enemies[i].Direction of
            ToUp :
            begin
              GameplayState.Enemies[i]._pos._y := GameplayState.Enemies[i]._pos._y - round(GameplayState.Enemies[i].Speed * dt / 1000);
              GameplayState.Enemies[i]._col._y := GameplayState.Enemies[i]._pos._y;
            end;
            ToDown :
            begin
              GameplayState.Enemies[i]._pos._y := GameplayState.Enemies[i]._pos._y + round(GameplayState.Enemies[i].Speed * dt / 1000);
              GameplayState.Enemies[i]._col._y := GameplayState.Enemies[i]._pos._y;
            end;
            ToRight :
            begin
              GameplayState.Enemies[i]._pos._x := GameplayState.Enemies[i]._pos._x + round(GameplayState.Enemies[i].Speed * dt / 1000);
              GameplayState.Enemies[i]._col._x := GameplayState.Enemies[i]._pos._x;
            end;
            ToLeft :
            begin
              GameplayState.Enemies[i]._pos._x := GameplayState.Enemies[i]._pos._x - round(GameplayState.Enemies[i].Speed * dt / 1000);
              GameplayState.Enemies[i]._col._x := GameplayState.Enemies[i]._pos._x;
            end;
          end;
        end
        else
        begin
          case GameplayState.Enemies[i].Direction of
            ToUp :
            begin
              GameplayState.Enemies[i].Direction := ToDown;
            end;
            ToDown :
            begin
              GameplayState.Enemies[i].Direction := ToUp;
            end;
            ToRight :
            begin
              GameplayState.Enemies[i].Direction := ToLeft;
            end;
            ToLeft :
            begin
              GameplayState.Enemies[i].Direction := ToRight;
            end;
          end;
        end;
      end;
      GameplayState.Enemies[i].NeedChange := CheckEnemyPosition(GameplayState.Enemies[i]);
    end;
  end;
end;

{Процедура рисования врагов }
procedure RenderEnemies();
begin
 for var i:=1 to 6 do
 begin
   if (not GameplayState.Enemies[i].IsDead) then
   begin
     RenderEnemy(GameplayState.Enemies[i]._pos._x, GameplayState.Enemies[i]._pos._y, 0, TopOffset, GameplayState.Enemies[i].EnemyType);
   end;
 end;
end;

{Процедура рисования земли }
procedure RenderGround();
begin
  RenderGrass(0, 0, 0, TopOffset);
end;

{Процедура рисования неломаемых блоков }
procedure RenderIrons();
begin
  for var i:=1 to GameplayState.IronCount do
  begin
    RenderIron(GameplayState.IronMap[i]._pos._x, GameplayState.IronMap[i]._pos._y, 0, TopOffset);
  end;
end;

{Процедура рисования ломаемых блоков }
procedure RenderBricks();
begin
  for var i:=1 to GameplayState.BrickCount do
  begin
    if (GameplayState.BrickMap[i].Pooled) then
    begin
      RenderBrick(GameplayState.BrickMap[i]._pos._x, GameplayState.BrickMap[i]._pos._y, 0, TopOffset);
    end;
  end;
end;

{Процедура рисования бомб }
procedure RenderBombs();
begin
  for var i:=1 to GameplayState.BombCount do
  begin
    if (GameplayState.BombMap[i].Pooled) then
    begin
      RenderBomb(GameplayState.BombMap[i]._pos._x, GameplayState.BombMap[i]._pos._y, 0, TopOffset);
    end;
  end;
end;

{Процедура рисования огня }
procedure RenderFires();
begin
  for var i:=1 to GameplayState.FireCount do
  begin
    if (GameplayState.FireMap[i].Pooled) then
    begin
      RenderFire(GameplayState.FireMap[i]._pos._x, GameplayState.FireMap[i]._pos._y, 0, TopOffset);
    end;
  end;
end;

{Процедура рисования игроков }
procedure RenderPlayers();
begin
  for var i:=1 to MaxPlayers do
  begin
    if (not GameplayState.Players[i].IsDead) then
    begin
      RenderPlayer(GameplayState.Players[i]._pos._x, GameplayState.Players[i]._pos._y, 0, TopOffset, GameplayState.Players[i].PlayerId, GameplayState.Players[i].Name);
      if (GameplayState.Players[i].IsImmortal) then
      begin
        RenderShield(GameplayState.Players[i]._pos._x, GameplayState.Players[i]._pos._y, 0, TopOffset);
      end;
    end;
  end;
end;

{Процедура рисования порталов врага }
procedure RenderPortals();
begin
  for var i:=1 to GameplayState.SpawnCountEnemy do
  begin
    RenderEnemySpawner(GameplayState.SpawnEnemies[i]._x, GameplayState.SpawnEnemies[i]._y, 0, TopOffset);
  end;
end;

{Процедура загрузки карты             }
{Параметры: filename - название карты }
procedure LoadMap(filename : string);
begin
  var textFile : Text;
  var rows, columns : integer;
  rows := 0;
  columns := 0;
  Assign(textFile, 'maps/' + filename);
  Reset(textFile);
  while (not Eof(textFile)) do
  begin
    rows := rows + 1;
    var line : string;
    Readln(textFile, line);
    columns := 0;
    for var i:=1 to Length(line) do
    begin
      GameplayState.Map[rows, i] := Ord(line[i]) - 48;
      columns := columns + 1;
    end;
  end;
  GameplayState.MapY := rows;
  GameplayState.MapX := columns;
  Close(textFile);
end;

{Процедура заполения массивов блоков и порталов }
procedure FillMap();
begin
  for var rows:=1 to GameplayState.MapY do
  begin
    for var columns:=1 to GameplayState.MapX do
    begin
      case (GameplayState.Map[rows, columns]) of
        5:
        begin
          if (GameplayState.SpawnCount + 1 < 8) then
          begin
            GameplayState.SpawnCount := GameplayState.SpawnCount + 1;
            var temp : Transform;
            temp._x := (columns - 1) * 64;
            temp._y := (rows - 1) * 64;
            GameplayState.SpawnPoints[GameplayState.SpawnCount] := temp;
          end;
        end;
        4:
        begin
          if (GameplayState.SpawnCountEnemy + 1 < 4) then
          begin
            GameplayState.SpawnCountEnemy := GameplayState.SpawnCountEnemy + 1;
            var temp : Transform;
            temp._x := (columns - 1) * 64;
            temp._y := (rows - 1) * 64;
            GameplayState.SpawnEnemies[GameplayState.SpawnCountEnemy] := temp;
          end;
        end;
        1:
        begin
          var temp := CreateCollider((columns - 1) * 64, (rows - 1) * 64, 0, 0, 64, 64, true);  
          var _iron : Iron;
          _iron._col := GameplayState.ColliderMap[GameplayState.colCount];
          _iron._pos._x := temp._x;
          _iron._pos._y := temp._y;
          GameplayState.IronCount := GameplayState.IronCount + 1;
          GameplayState.IronMap[GameplayState.IronCount] := _iron;   
        end;
        2:
        begin
          var temp := CreateCollider((columns - 1) * 64, (rows - 1) * 64, 0, 0, 64, 64, true);  
          var _brick : Brick;
          _brick._col := GameplayState.ColliderMap[GameplayState.colCount];
          _brick._pos._x := temp._x;
          _brick._pos._y := temp._y;
          _brick.Pooled := true;
          GameplayState.BrickCount := GameplayState.BrickCount + 1;
          GameplayState.BrickMap[GameplayState.BrickCount] := _brick;  
        end;
      end;
    end;
  end;
end;

procedure InitMainGame();
begin
  with GameplayState do
  begin
    for var i:=1 to MaxPlayers do
    begin
      Players[i]._pos._x       := 0;
      Players[i]._pos._y       := 0;
      Players[i]._col          := CreateCollider(0, 0, 16, 6, 52, 32, false);
      Players[i].PlayerId      := i;
      Players[i].IsDead        := true;
      Players[i].Respawn       := 0;
      Players[i].BombCount     := 3;
      Players[i].Name          := PlayerNames[i];
      Players[i].Speed         := 125;
      Players[i].PlayerScore   := 0;
      if (i = 1) then
      begin
        Players[i].Down        := VK_S;
        Players[i].Up          := VK_W;
        Players[i].Left        := VK_A;
        Players[i].Right       := VK_D;
        Players[i].Place       := VK_G;
      end;
      if (i = 2) then
      begin
        Players[i].Down        := VK_DOWN;
        Players[i].Up          := VK_UP;
        Players[i].Left        := VK_LEFT;
        Players[i].Right       := VK_RIGHT;
        Players[i].Place       := VK_L;
      end;
    end;
    //Map
    CurrentMap                := _CurrentMap;
    LoadMap(CurrentMap + '.txt');
    ColCount                  := 0;
    BombCount                 := 0;
    BrickCount                := 0;
    FireCount                 := 0;
    IronCount                 := 0;
    for var i:=1 to 6 do
    begin
      Enemies[i].LastChange := 0;
      Enemies[i]._col.Pooled := true;
      Enemies[i].IsDead := true;
    end;
  end;
  FillMap();
  
  MainTime := 120000;
  IsPause := false;
  
  Options[1] := 'Продолжить';
  Options[2] := 'Выйти';
  CurrentOp := 1;
end;

procedure HandleInputInMainGame;
begin
  if (inputKeys[VK_O]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      MainTime := MainTime - 2000;
    end;
  end;
  if (inputKeys[VK_ESCAPE]) then
  begin
    if (Milliseconds() - LastChange > DelayInput) then
    begin
      LastChange := Milliseconds();
      if (not IsPause) then
      begin
        IsPause := true;
        CurrentOp := 1;
      end
      else
      begin
        IsPause := false;
      end;
    end;
  end;
  if (IsPause) then
  begin
    if (inputKeys[VK_DOWN] or inputKeys[VK_S]) then
    begin
      if (Milliseconds() - LastChange > DelayInput) then
      begin
        LastChange := Milliseconds();
        if (CurrentOp + 1 > 2) then
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
          CurrentOp := 2;
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
        if (CurrentOp = 2) then
        begin
          ChangeState(MenuState);
        end
        else
        if (CurrentOp = 1) then
        begin
          IsPause := false;
        end;
      end;
    end;
  end;
end;

procedure UpdateMainGame;
begin
  HandleInputInMainGame();
  if (not IsPause) then
  begin
    for var i:=1 to MaxPlayers do
    begin
      MovePlayer(GameplayState.Players[i], dt);
    end;
    UpdateEnemy(dt);
    Countdown(dt);
    Bombdown(dt);
    Firedown(dt);
    Respawndown(dt);
    Immortaldown(dt);
    UpdateBomb(dt);
    UpdateFire(dt);
    UpdateRespawn(dt);
    UpdateRespawnEnemies(dt);
  end;
  if ((MainTime < 0)) then
  begin
    for var i:=1 to MaxPlayers do
    begin
      PlayerScores[i] := GameplayState.Players[i].PlayerScore;
    end;
    ChangeState(EndHighState);
  end;
end;

procedure RenderMainGame;
begin
  Window.Clear();
  SetBrushStyle(bsSolid);
  RenderGround();
  RenderPortals();
  RenderIrons();
  RenderBricks();
  RenderBombs();
  RenderEnemies();
  RenderPlayers();
 
  
  SetBrushStyle(bsSolid);
  RenderFires();
  
  SetFontSize(14);
  SetBrushStyle(bsSolid);
  SetBrushColor(clWhite);
  
  //UI
  var TimeString := (MainTime div 1000) div 60 + ':' + (MainTime div 1000) mod 60;
  TextOut(WindowWidth div 2 - 96, 8, 'Осталось времени');
  TextOut(WindowWidth div 2 - 32, 32, TimeString);
  TextOut(16, 26, GameplayState.Players[1].Name + ' Score: ' + GameplayState.Players[1].PlayerScore);
  for var i:=1 to GameplayState.Players[1].BombCount do
  begin
    RenderBombIcon(224 + 28 * i, 20, 0, 0);
  end;
  for var i:= 1 to GameplayState.Players[2].BombCount do
  begin
    RenderBombIcon(WindowWidth - 274 - 28 * i, 20, 0, 0);
  end;
  TextOut(WindowWidth - 256, 26, GameplayState.Players[2].Name + ' Score: ' + GameplayState.Players[2].PlayerScore);

  //Pause
  if (IsPause) then
  begin
    SetBrushStyle(bsSolid);
    
    SetBrushColor(ARGB(50, 0, 0, 0));
    FillRectangle(0, 0, 960, 768);
    
    PauseBack.Draw(Window.Width div 2 - 128, Window.Height div 2 - 96);
    SetFontSize(26);
    SetFontColor(clWhite);
    DrawTextCentered(Window.Width div 2, Window.Height div 2 - 54, 'Пауза');
    SetFontSize(20);
    for var i := 1 to 2 do
    begin
      if (CurrentOp = i) then
      begin
        DrawChooseLine(Window.Width div 2 - 125, Window.Height div 2 - 74 + 50 * i, 251,  40);
      end;
      DrawTextCentered(Window.Width div 2, Window.Height div 2 - 54 + 50 * i, Options[i]);
    end;
    SetFontColor(clBlack);
  end;
  
end;

procedure DisposeMainGame;
begin
  MainTime := 120000;
  for var i:=1 to GameplayState.ColCount do
  begin
    GameplayState.ColliderMap[i].Pooled := false;
  end;
  for var i:=1 to GameplayState.BombCount do
  begin
    GameplayState.BombMap[i].Pooled := false;
  end;
  for var i:=1 to GameplayState.BrickCount do
  begin
    GameplayState.BrickMap[i].Pooled := false;
  end;
  for var i:=1 to GameplayState.FireCount do
  begin
    GameplayState.FireMap[i].Pooled := false;
  end;

  GameplayState.ColCount    := 0;
  GameplayState.BombCount   := 0;
  GameplayState.BrickCount  := 0;
  GameplayState.FireCount   := 0;
  GameplayState.IronCount   := 0;
  GameplayState.SpawnCount  := 0;
  GameplayState.SpawnCountEnemy := 0;
end;

begin
  
end.