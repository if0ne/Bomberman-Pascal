unit UIAssets;

interface

uses GraphABC;

procedure InitAssets();

var
  MenuBackground : Picture;
  Logo : Picture;
  Background : Picture;
  Button, ActiveButton : Picture;
  HelpTitle, HelpBack : Picture;

implementation

procedure InitAssets;
begin
  MenuBackground := new Picture('assets/MenuBackground.png');
  Logo := new Picture('assets/Logo.png');
  Background := new Picture('assets/Background.png');
  Button := new Picture('assets/Button.png');
  ActiveButton := new Picture('assets/ActiveButton.png');
  HelpTitle := new Picture('assets/HelpTitle.png');
  HelpBack := new Picture('assets/HelpBack.png');
end;

begin
  
end.