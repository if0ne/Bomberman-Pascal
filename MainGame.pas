unit MainGame;

interface

procedure InitMainGame();
procedure HandleInputInMainGame();
procedure UpdateMainGame(dt : integer);
procedure RenderMainGame();
procedure DisposeMainGame();

type
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
  Transform = record
    _x : integer;
    _y : integer;
  end;
  Player = record
    _col      : Collider;
    _pos      : Transform;
    _sprite   : word = 1;
    
    Speed     : word;
    Up        : word;
    Left      : word;
    Down      : word;
    Right     : word;
    Place     : word;
    PlayerId  : byte;
    BombCount : byte;
    
    Respawn   : integer;
    IsDead    : boolean;
    Name      : string;
  end;
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
  Bomb = record
    _col      : Collider;
    _pos      : Transform;
    _sprite   : word = 2;
    Time      : integer;
    Pooled    : boolean;
    PlayerId  : byte;
    IsAddable : boolean;
  end;
  Iron = record
    _col    : Collider;
    _pos    : Transform;
    _sprite : word = 3;
  end;
  Brick = record
    _col    : Collider;
    _pos    : Transform;
    _sprite : word = 4;
    Pooled  : boolean;
  end;
  Fire = record
    _pos     : Transform;
    _sprite  : word = 6;
    Time     : integer;
    Pooled   : boolean;
    PlayerId : byte;
  end;
  GameState = record
    Player1          : Player;
    Player2          : Player;
    Player1Score     : integer;
    Player2Score     : integer;
    
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

implementation

uses
  GraphABC, GlobalVars, Renderer;

const
  
  SpawnDelay  = 1000;
  ChangeDelay = 1000;
  
  ToUp    = 1;
  ToRight = 2;
  ToDown  = 3;
  ToLeft  = 4;
  
var
  GameplayState : GameState;
  MainTime : longint;
  SpawnCooldown : longint;
  
  IsPause : boolean;
  Options : array[1..2] of string;
  CurrentOp : byte;
  
procedure Countdown(dt : integer);
begin
  MainTime := MainTime - dt;
end;

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

procedure Respawndown(dt : integer);
begin
  if (GameplayState.Player1.IsDead) then
  begin
    GameplayState.Player1.Respawn := GameplayState.Player1.Respawn - dt;
  end;
  if (GameplayState.Player2.IsDead) then
  begin
    GameplayState.Player2.Respawn := GameplayState.Player2.Respawn - dt;
  end;
end;

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

function CheckCollisionWithEnemy(player : Collider) : boolean;
begin
  CheckCollisionWithEnemy := false;
  for var i:=1 to 6 do
  begin
    if (IsCollide(player, GameplayState.Enemies[i]._col)) then
    begin
      CheckCollisionWithEnemy := true;
      break;
    end;
  end;
end;

function CheckCollision(entity : Collider) : boolean;
begin
  CheckCollision:=false;
  for var i:=1 to GameplayState.ColCount do
  begin
    if (IsCollide(entity, GameplayState.ColliderMap[i])) then
    begin
      CheckCollision:=true;
      break;
    end;
  end;
end;

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
      break;
    end;
  end;
end;

function GetFirstPooledBomb() : word;
begin
  for var i:=1 to GameplayState.BombCount do
  begin
    if (GameplayState.BombMap[i].Pooled = false) then
    begin
      GetFirstPooledBomb := i;
      break;
    end;
    if (i = GameplayState.BombCount) then
    begin
      GetFirstPooledBomb := i + 1;
      GameplayState.BombCount := GameplayState.BombCount + 1;
      break;
    end;
  end;
  if (GameplayState.BombCount = 0) then
  begin
    GameplayState.BombCount := GameplayState.BombCount + 1;
    GetFirstPooledBomb := 1;
  end;
end;

procedure MovePlayer(var movablePlayer : Player);
begin
  if (not movablePlayer.IsDead) then
  begin
    var newCol : Collider;
    newCol := movablePlayer._col;
    if (inputKeys[movablePlayer.Up]) then
    begin
      newCol._y := newCol._y - movablePlayer.Speed;
    end
    else if (inputKeys[movablePlayer.Left]) then
    begin
      newCol._x := newCol._x - movablePlayer.Speed;
    end
    else if (inputKeys[movablePlayer.Down]) then
    begin
      newCol._y := newCol._y + movablePlayer.Speed;
    end
    else if (inputKeys[movablePlayer.Right]) then
    begin
      newCol._x := newCol._x + movablePlayer.Speed;
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
        var x := (movablePlayer._pos._x + 32) div 64 * 64;
        var y := (movablePlayer._pos._y + 32) div 64 * 64;
        var temp : Bomb;
        temp._pos._x := x;
        temp._pos._y := y;
        temp._col._h := 64;
        temp._col._w := 64;
        temp._col._x := x;
        temp._col._y := y;
        temp.Pooled := true;
        temp.IsAddable := true;
        temp.Time := 3000;
        temp.PlayerId := movablePlayer.PlayerId;
        if (not ContainsBomb(temp)) then
        begin
          movablePlayer.BombCount := movablePlayer.BombCount - 1;
          var index := GetFirstPooledBomb();
          GameplayState.BombMap[index] := temp;
        end;
      end;
    end;
    if (CheckCollisionWithEnemy(movablePlayer._col)) then
    begin
      movablePlayer.Respawn := 1500;
      movablePlayer.IsDead := true;
      if (movablePlayer.PlayerId = 1) then
        GameplayState.Player1Score := GameplayState.Player1Score - 3
      else 
      if (movablePlayer.PlayerId = 2) then
        GameplayState.Player2Score := GameplayState.Player2Score - 3;
    end;
  end;
end;

function GetFirstPooledFire() : word;
begin
  for var i:=1 to GameplayState.FireCount do
  begin
    if (GameplayState.FireMap[i].Pooled = false) then
    begin
      GetFirstPooledFire := i;
      break;
    end;
    if (i = GameplayState.FireCount) then
    begin
      GetFirstPooledFire := i + 1;
      GameplayState.FireCount := GameplayState.FireCount + 1;
      break;
    end;
  end;
  if (GameplayState.FireCount = 0) then
  begin
    GameplayState.FireCount := GameplayState.FireCount + 1;
    GetFirstPooledFire := 1;
  end;
end;

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
        if (_fire.PlayerId = 1) then
          GameplayState.Player1Score := GameplayState.Player1Score + 3
        else
        if (_fire.PlayerId = 2) then
          GameplayState.Player2Score := GameplayState.Player2Score + 3;
        GameplayState.Enemies[i].IsDead := true;
        GameplayState.Enemies[i].Respawn := 3000;
        GameplayState.Enemies[i]._col.Pooled := false;
        if (GameplayState.Enemies[i].EnemyType = BlowupEnemy) then
        begin
          var x := (GameplayState.Enemies[i]._pos._x + 32) div 64 * 64;
          var y := (GameplayState.Enemies[i]._pos._y + 32) div 64 * 64;
          var temp : Bomb;
          temp._pos._x := x;
          temp._pos._y := y;
          temp._col._h := 64;
          temp._col._w := 64;
          temp._col._x := x;
          temp._col._y := y;
          temp.Pooled := true;
          temp.IsAddable := false;
          temp.Time := 0;
          temp.PlayerId := _fire.PlayerId;
          if (not ContainsBomb(temp)) then
          begin
            var index := GetFirstPooledBomb();
            GameplayState.BombMap[index] := temp;
          end;
        end;
      end;
    end;
  end;
  
  if (GameplayState.Map[_y, _x] = 1) then
  begin
    BlowUpCell := true;
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
        
        if (_fire.PlayerId = 1) then
        begin
          GameplayState.Player1Score := GameplayState.Player1Score + 1;
        end 
        else if (_fire.PlayerId = 2) then
        begin
          GameplayState.Player2Score := GameplayState.Player2Score + 1;
        end;
        break;
      end;
    end;
  end;

  if ((((GameplayState.Player1._pos._x + 32) div 64 + 1) = _x) and 
  (((GameplayState.Player1._pos._y + 32) div 64 + 1) = _y) and
  not GameplayState.Player1.IsDead) then
  begin
    BlowUpCell := true;
    
    if (_fire.PlayerId = 2) then
    begin
      GameplayState.Player2Score := GameplayState.Player2Score + 5;
    end;
    
    GameplayState.Player1.Respawn := 1500;
    GameplayState.Player1.IsDead := true;
    GameplayState.Player1Score := GameplayState.Player1Score - 3;
    
  end;

  if ((((GameplayState.Player2._pos._x + 32) div 64 + 1) = _x) and 
  (((GameplayState.Player2._pos._y + 32) div 64 + 1) = _y) and
  not GameplayState.Player2.IsDead) then
  begin
    BlowUpCell := true;
    
    if (_fire.PlayerId = 1) then
    begin
      GameplayState.Player1Score := GameplayState.Player1Score + 5;
    end;
    GameplayState.Player2.Respawn := 1500;
    GameplayState.Player2.IsDead := true;
    GameplayState.Player2Score := GameplayState.Player2Score - 3;
    
  end;
  
end;

procedure ExplodeBomb(_bomb : Bomb; waveSize : word);
begin
  var _x := _bomb._pos._x div 64;
  var _y := _bomb._pos._y div 64;
  //To Up
  var center : Fire;
  center._pos._y := _y * 64;
  center._pos._x := _x * 64;
  center.PlayerId := _bomb.PlayerId;
  center.Pooled := true;
  center.Time   := 300;
  var _index := GetFirstPooledFire();
  GameplayState.FireMap[_index] := center;
  if (not BlowUpCell(center)) then
  begin
    //To Up
    for var i:=1 to waveSize do
    begin
      var temp : Fire;
      temp._pos._y := (_y - i) * 64;
      temp._pos._x := _x * 64;
      temp.PlayerId := _bomb.PlayerId;
      temp.Pooled := true;
      temp.Time   := 300;
      var index := GetFirstPooledFire();
      GameplayState.FireMap[index] := temp;
      if (BlowUpCell(temp)) then
      begin
        break;
      end;
    end;
    //To Down
    for var i:=1 to waveSize do
    begin
      var temp : Fire;
      temp._pos._y := (_y + i) * 64;
      temp._pos._x := _x * 64;
      temp.PlayerId := _bomb.PlayerId;
      temp.Pooled := true;
      temp.Time   := 300;
      var index := GetFirstPooledFire();
      GameplayState.FireMap[index] := temp;
      if (BlowUpCell(temp)) then
      begin
        break;
      end;
    end;
    //To Left
    for var i:=1 to waveSize do
    begin
      var temp : Fire;
      temp._pos._y := _y * 64;
      temp._pos._x :=(_x - i) * 64;
      temp.PlayerId := _bomb.PlayerId;
      temp.Pooled := true;
      temp.Time   := 300;
      var index := GetFirstPooledFire();
      GameplayState.FireMap[index] := temp;
      if (BlowUpCell(temp)) then
      begin
        break;
      end;
    end;
    //To Right
    for var i:=1 to waveSize do
    begin
      var temp : Fire;
      temp._pos._y := _y * 64;
      temp._pos._x := (_x + i) * 64;
      temp.PlayerId := _bomb.PlayerId;
      temp.Pooled := true;
      temp.Time   := 300;
      var index := GetFirstPooledFire();
      GameplayState.FireMap[index] := temp;
      if (BlowUpCell(temp)) then
      begin
        break;
      end;
    end;
  end;
end;

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
      if (GameplayState.BombMap[i].IsAddable) then
      begin
        if (GameplayState.BombMap[i].PlayerId = 1) then
        begin
          GameplayState.Player1.BombCount := GameplayState.Player1.BombCount + 1;
        end
        else
        begin
          GameplayState.Player2.BombCount := GameplayState.Player2.BombCount + 1;
        end;
        ExplodeBomb(GameplayState.BombMap[i], 2);
      end
      else
      begin
        ExplodeBomb(GameplayState.BombMap[i], 1);
      end;
    end;
  end;
end;

function IsEmpty(x, y : integer) : boolean;
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

procedure InitPlayer(x, y, playerId : integer);
begin
  if (playerId = 1) then
  begin
    GameplayState.Player1._pos._x     := x;
    GameplayState.Player1._pos._y     := y;
    GameplayState.Player1._col._x     := x;
    GameplayState.Player1._col._y     := y;
    GameplayState.Player1.IsDead      := false;
    GameplayState.Player1.Respawn     := 0;
    GameplayState.Player1._col.Pooled := true;
  end;
  if (playerId = 2) then
  begin
    GameplayState.Player2._pos._x     := x;
    GameplayState.Player2._pos._y     := y;
    GameplayState.Player2._col._x     := x;
    GameplayState.Player2._col._y     := y;
    GameplayState.Player2.IsDead      := false;
    GameplayState.Player2.Respawn     := 0;
    GameplayState.Player2._col.Pooled := true;
  end;
end;

procedure SpawnPlayer(var _player : Player);
begin
  var trans : Transform;
  if (_player.PlayerId = 1) then
  begin
    if (GameplayState.Player2.IsDead) then
    begin
      trans := GameplayState.SpawnPoints[Random(1, GameplayState.SpawnCount)];
    end
    else
    begin
      var max := sqrt(sqr(GameplayState.Player2._pos._x - GameplayState.SpawnPoints[1]._x) +
      sqr(GameplayState.Player2._pos._y - GameplayState.SpawnPoints[1]._y));
      var id := 1;
      for var i:=2 to GameplayState.SpawnCount do
      begin
        if (max < sqrt(sqr(GameplayState.Player2._pos._x - GameplayState.SpawnPoints[i]._x) +
        sqr(GameplayState.Player2._pos._y - GameplayState.SpawnPoints[i]._y))) then
        begin
          max := sqrt(sqr(GameplayState.Player2._pos._x - GameplayState.SpawnPoints[i]._x) +
                 sqr(GameplayState.Player2._pos._y - GameplayState.SpawnPoints[i]._y));
          id := i;
        end;
      end;
      trans := GameplayState.SpawnPoints[id];
    end;
    InitPlayer(trans._x, trans._y, 1);
  end;
  
  if (_player.PlayerId = 2) then
  begin
    if (GameplayState.Player1.IsDead) then
    begin
      trans := GameplayState.SpawnPoints[Random(4) + 1];
    end
    else
    begin
      var max := sqrt(sqr(GameplayState.Player1._pos._x - GameplayState.SpawnPoints[1]._x) +
      sqr(GameplayState.Player1._pos._y - GameplayState.SpawnPoints[1]._y));
      var id := 1;
      for var i:=2 to GameplayState.SpawnCount do
      begin
        if (max < sqrt(sqr(GameplayState.Player1._pos._x - GameplayState.SpawnPoints[i]._x) +
        sqr(GameplayState.Player1._pos._y - GameplayState.SpawnPoints[i]._y))) then
        begin
          max := sqrt(sqr(GameplayState.Player1._pos._x - GameplayState.SpawnPoints[i]._x) +
                 sqr(GameplayState.Player1._pos._y - GameplayState.SpawnPoints[i]._y));
          id := i;
        end;
      end;
      trans := GameplayState.SpawnPoints[id];
    end;
    InitPlayer(trans._x, trans._y, 2);
  end;
end;

procedure SpawnEnemy(var _enemy : Enemy; x, y:integer);
begin
  with _enemy do
  begin
    _col._x := x;
    _col._y := y;
    _col._h := 48;
    _col._w := 48;
    _col._offsetX := 8;
    _col._offsetY := 8;
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
      Speed := 3;
      _sprite := 6;
    end
    else
    if (EnemyType = SlowEnemy) then
    begin
      Speed := 2;
      _sprite := 7;
    end
    else
    if (EnemyType = BlowupEnemy) then
    begin
      Speed := 2;
      _sprite := 8;
    end;
    Respawn := 0;
    CurPosInArray._x := x div 64 + 1;
    CurPosInArray._y := y div 64 + 1;
    Direction := Random(1, 4);
  end;
end;

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

function GetCurPosInArr(var _enemy : Enemy) : Transform;
begin
  var trans : Transform;
  if (((_enemy._pos._x + 60) div 64 + 1) <> _enemy.NewPosInArray._x) and ((_enemy._pos._x div 64 + 1) <> _enemy.NewPosInArray._x) then
  begin
    _enemy.NewPosInArray._x := _enemy._pos._x div 64 + 1;
  end;
  if (((_enemy._pos._y + 60) div 64 + 1) <> _enemy.NewPosInArray._y) and ((_enemy._pos._y div 64 + 1) <> _enemy.NewPosInArray._y)then
  begin
    _enemy.NewPosInArray._y := _enemy._pos._y div 64 + 1;
  end;
  trans._x := _enemy.NewPosInArray._x;
  trans._y := _enemy.NewPosInArray._y;
  GetCurPosInArr := trans;
end;

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

procedure UpdateRespawn(dt : integer);
begin
  if ((GameplayState.Player1.Respawn <= 0) and (GameplayState.Player1.IsDead)) then
  begin
    SpawnPlayer(GameplayState.Player1);
  end;
  if ((GameplayState.Player2.Respawn <= 0) and (GameplayState.Player2.IsDead)) then
  begin
    SpawnPlayer(GameplayState.Player2);
  end;
end;

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
              GameplayState.Enemies[i]._pos._y := GameplayState.Enemies[i]._pos._y - GameplayState.Enemies[i].Speed;
              GameplayState.Enemies[i]._col._y := GameplayState.Enemies[i]._pos._y;
            end;
            ToDown :
            begin
              GameplayState.Enemies[i]._pos._y := GameplayState.Enemies[i]._pos._y + GameplayState.Enemies[i].Speed;
              GameplayState.Enemies[i]._col._y := GameplayState.Enemies[i]._pos._y;
            end;
            ToRight :
            begin
              GameplayState.Enemies[i]._pos._x := GameplayState.Enemies[i]._pos._x + GameplayState.Enemies[i].Speed;
              GameplayState.Enemies[i]._col._x := GameplayState.Enemies[i]._pos._x;
            end;
            ToLeft :
            begin
              GameplayState.Enemies[i]._pos._x := GameplayState.Enemies[i]._pos._x - GameplayState.Enemies[i].Speed;
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

procedure RenderGround();
begin
  RenderGrass(0, 0, 0, TopOffset);
end;

procedure RenderIrons();
begin
  for var i:=1 to GameplayState.IronCount do
  begin
    RenderIron(GameplayState.IronMap[i]._pos._x, GameplayState.IronMap[i]._pos._y, 0, TopOffset);
  end;
end;

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
          var temp : Collider;
          temp._x := (columns - 1) * 64;
          temp._y := (rows - 1) * 64;
          temp._h := 64;
          temp._w := 64;
          temp.Pooled := true;
          GameplayState.colCount := GameplayState.colCount + 1;
          temp.ColId := GameplayState.colCount;
          GameplayState.ColliderMap[GameplayState.colCount] := temp;
          
          var _iron : Iron;
          _iron._col := GameplayState.ColliderMap[GameplayState.colCount];
          _iron._pos._x := temp._x;
          _iron._pos._y := temp._y;
          GameplayState.IronCount := GameplayState.IronCount + 1;
          GameplayState.IronMap[GameplayState.IronCount] := _iron;   
        end;
        2:
        begin
          var temp : Collider;
          temp._x := (columns - 1) * 64;
          temp._y := (rows - 1) * 64;
          temp._h := 64;
          temp._w := 64;
          temp.Pooled := true;
          GameplayState.colCount := GameplayState.colCount + 1;
          temp.ColId := GameplayState.colCount;
          GameplayState.ColliderMap[GameplayState.colCount] := temp;
          
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
  //Player 1
  with GameplayState do
  begin
    Player1._pos._x           := 0;
    Player1._pos._y           := 0;
    Player1._col._x           := 0;
    Player1._col._y           := 0;
    Player1._col._h           := 52;
    Player1._col._w           := 32;
    Player1._col._offsetX     := 16;
    Player1._col._offsetY     := 6;
    Player1._col.Pooled       := false;
    Player1.Speed             := 2;
    Player1.Down              := VK_S;
    Player1.Up                := VK_W;
    Player1.Left              := VK_A;
    Player1.Right             := VK_D;
    Player1.Place             := VK_G;
    Player1.PlayerId          := 1;
    Player1.IsDead            := true;
    Player1.Respawn           := 0;
    Player1.Name              := Player1Name;
    Player1.BombCount         := 3;
    //Player 2
    Player2._pos._x           := 0;
    Player2._pos._y           := 0;
    Player2._col._x           := 0;
    Player2._col._y           := 0;
    Player2._col._h           := 52;
    Player2._col._w           := 32;
    Player2._col._offsetX     := 16;
    Player2._col._offsetY     := 6;
    Player2._col.Pooled       := true;
    Player2.Speed             := 2;
    Player2.Down              := VK_DOWN;
    Player2.Up                := VK_UP;
    Player2.Left              := VK_LEFT;
    Player2.Right             := VK_RIGHT;
    Player2.Place             := VK_L;
    Player2.PlayerId          := 2;
    Player2.IsDead            := true;
    Player2.Respawn           := 0;
    Player2.Name              := Player2Name;
    Player2.BombCount         := 3;
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
  
  //Init 
  GameplayState.Player1Score := 0;
  GameplayState.Player2Score := 0;
  
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
      MainTime := MainTime - 500;
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
    MovePlayer(GameplayState.Player1);
    MovePlayer(GameplayState.Player2);
    UpdateEnemy(dt);
    Countdown(dt);
    Bombdown(dt);
    Firedown(dt);
    Respawndown(dt);
    UpdateBomb(dt);
    UpdateFire(dt);
    UpdateRespawn(dt);
    UpdateRespawnEnemies(dt);
  end;
  if ((MainTime < 0)) then
  begin
    Player1Score := GameplayState.Player1Score;
    Player2Score := GameplayState.Player2Score;
    ChangeState(EndHighState);
  end;
end;

procedure RenderMainGame;
begin
  Window.Clear();
  SetBrushStyle(bsSolid);
  RenderGround();
  RenderIrons();
  RenderBricks();
  RenderBombs();
  RenderEnemies();

  if (not GameplayState.Player1.IsDead) then
  begin
    RenderPlayer(GameplayState.Player1._pos._x, GameplayState.Player1._pos._y, 0, TopOffset, GameplayState.Player1.PlayerId, GameplayState.Player1.Name);
  end;
  if (not GameplayState.Player2.IsDead) then
  begin
    RenderPlayer(GameplayState.Player2._pos._x, GameplayState.Player2._pos._y, 0, TopOffset, GameplayState.Player2.PlayerId, GameplayState.Player2.Name);
  end;
  
  SetBrushStyle(bsSolid);
  RenderFires();
  
  SetFontSize(14);
  SetBrushStyle(bsSolid);
  SetBrushColor(clWhite);
  
  //UI
  var TimeString := (MainTime div 1000) div 60 + ':' + (MainTime div 1000) mod 60;
  TextOut(WindowWidth div 2 - 96, 8, 'Осталось времени');
  TextOut(WindowWidth div 2 - 32, 32, TimeString);
  TextOut(16, 26, GameplayState.Player1.Name + ' Score: ' + GameplayState.Player1Score);
  TextOut(WindowWidth - 164, 26, GameplayState.Player2.Name + ' Score: ' + GameplayState.Player2Score);
  
  //Pause
  if (IsPause) then
  begin
    SetBrushStyle(bsSolid);
    SetBrushColor(clChocolate);
    FillRect(Window.Width div 2 - 128, Window.Height div 2 - 96, Window.Width div 2 + 128, Window.Height div 2 + 96);
    SetFontSize(26);
    SetBrushStyle(bsClear);
    DrawTextCentered(Window.Width div 2, Window.Height div 2 - 54, 'Пауза');
    SetFontSize(20);
    for var i := 1 to 2 do
    begin
      if (CurrentOp = i) then
      begin
        SetBrushStyle(bsSolid);
        SetBrushColor(clLightBlue);
        FillRect(Window.Width div 2 - 82, Window.Height div 2 - 54 - 22 + 50 * i, Window.Width div 2 + 82, Window.Height div 2 - 54 + 22 + 50 * i);
      end;
      DrawTextCentered(Window.Width div 2, Window.Height div 2 - 54 + 50 * i, Options[i]);
    end;
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