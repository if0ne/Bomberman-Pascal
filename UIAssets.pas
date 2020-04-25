unit UIAssets;

interface

uses GraphABC;

procedure InitAssets();
procedure DrawButton(x, y : integer; text : string; fontSize : integer; isActive : boolean);
procedure DrawHeader(x, y : integer; text : string);
procedure DrawScoreLabel(x, y: integer; text : string; scoreType : word);
procedure DrawChooseLine(x, y, w, h : integer);
procedure DrawLabel(x, y : integer; text : string);

const
  DefaultSize = 26;
  LittleSize  = 8;
  
  GoldType = 1;
  SilverType = 2;
  BronzeType = 3;
  DefaultType = 4;
  NewType = 5;

var
  Logo, Title, Header, TextLabel : Picture;
  Background, Score : Picture;
  Button, ActiveButton : Picture;
  HelpBack : Picture;
  PauseBack : Picture;

implementation

procedure InitAssets;
begin
  Logo         := new Picture('assets/Logo.png');
  Background   := new Picture('assets/Background.png');
  Button       := new Picture('assets/Button.png');
  ActiveButton := new Picture('assets/ActiveButton.png');
  HelpBack     := new Picture('assets/HelpBack.png');
  Title        := new Picture('assets/Title.png');
  Header       := new Picture('assets/Header.png');
  Score        := new Picture('assets/Score.png');
  TextLabel    := new Picture('assets/Label.png');
  PauseBack    := new Picture('assets/PauseBack.png');
end;

procedure DrawButton;
begin
  SetBrushStyle(bsSolid);
  SetFontSize(fontSize);
  if (isActive) then
    ActiveButton.Draw(x - 122, y - 42)
  else
    Button.Draw(x - 122, y - 42);
  SetBrushStyle(bsClear);
  DrawTextCentered(x, y, text);
end;

procedure DrawHeader;
begin
  SetBrushStyle(bsSolid);
  SetFontStyle(FsItalic);
  SetFontSize(32);
  Header.Draw(x - 262, y - 56);
  SetBrushStyle(bsClear);
  DrawTextCentered(x, y, text);
  SetFontStyle(FsNormal);
end;

procedure DrawScoreLabel;
begin
  SetBrushStyle(bsSolid);
  Score.Draw(x - 132, y - 32);
  SetFontSize(defaultSize);
  SetBrushStyle(bsClear);
  DrawTextCentered(x, y, text);
  SetBrushStyle(bsSolid);
  case scoreType of
    GoldType :
    begin
      SetBrushColor(RGB(255, 231, 84));
    end;
    SilverType :
    begin
      SetBrushColor(RGB(204, 205, 208));
    end;
    BronzeType :
    begin
      SetBrushColor(RGB(252, 123, 49));
    end;
    NewType:
    begin
      SetBrushColor(RGB(46, 182, 186));
    end;
    DefaultType:
    begin
      SetBrushStyle(bsClear);
    end;
  end;
  if (BrushStyle = bsSolid) then
  begin
    SetPenWidth(1);
    SetPenColor(clBlack);
    Circle(x - 112, y, 12);
    SetPenWidth(0);
  end;
end;

procedure DrawChooseLine;
begin
  SetBrushStyle(bsSolid);
  SetPenWidth(2);
  SetPenColor(clBlack);
  SetBrushColor(RGB(201, 160, 230));
  Rectangle(x -2, y, x + w + 2, y + h);
  SetPenWidth(0);
end;

procedure DrawLabel;
begin
  SetBrushStyle(bsSolid);
  SetFontSize(18);
  TextLabel.Draw(x - 459, y - 32);
  SetBrushStyle(bsClear);
  SetFontColor(clWhite);
  DrawTextCentered(x, y, text);
  SetFontColor(clBlack);
end;

begin
  
end.