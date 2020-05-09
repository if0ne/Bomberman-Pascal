unit UIAssets;

interface

uses GraphABC;

{Процедура инциализации вспомогательных ресурсов }
procedure InitAssets();
{Процедура рисования кнопки с текстом                              }
{Параметры: x, y - позиция, text - текст, fontSize - размер шрифта }
{           isActive - выбрана кнопка или нет                      }
procedure DrawButton(x, y : integer; text : string; fontSize : integer; isActive : boolean);
{Процедура рисования заголовка                                     }
{Параметры: x, y - позиция, text - текст                           }
procedure DrawHeader(x, y : integer; text : string);
{Процедура рисования надписи со счетом                             }
{Параметры: x, y - позиция, text - текст, fontSize - размер шрифта }
{           scoreType - тип надписи                                }
procedure DrawScoreLabel(x, y: integer; text : string; scoreType : word);
{Процедура рисования линии выбора }
{Параметры: x, y - позиция, w, h - ширина, высота                  }
procedure DrawChooseLine(x, y, w, h : integer);
{Процедура рисования надписи                                       }
{Параметры: x, y - позиция, text - текст                           }
procedure DrawLabel(x, y : integer; text : string);

const
  DefaultSize = 26; //Стандартный размер шрифта
  LittleSize  = 8;  //Маленький размер шрифта
  
  GoldType = 1;     //Золотой тип надписи со счетом
  SilverType = 2;   //Серебрянный тип надписи со счетом
  BronzeType = 3;   //Бронзовый тип надписи со счетом
  DefaultType = 4;  //Стандартный тип надписи со счетом
  NewType = 5;      //Новый тип надписи со счетом

var
  Logo, Title, Header, TextLabel : Picture; //Автор игры, название игры, фон заголовка, фон надписи
  Background, Score : Picture;              //Фон меню, фон надписи со счетом 
  Button, ActiveButton : Picture;           //Кнопка, активная кнопка
  HelpBack : Picture;                       //Фон для справки
  PauseBack : Picture;                      //Фон для паузы

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