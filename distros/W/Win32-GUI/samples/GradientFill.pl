#!perl -w

use strict;
use warnings;

use Win32::GUI  qw(WS_CAPTION WS_SIZEBOX WS_CHILD WS_CLIPCHILDREN WS_EX_CLIENTEDGE );

#Create the window and child window.

my $Win = new Win32::GUI::Window (
    -pos         => [100, 100],
    -size        => [450, 450],
    -name        => "Window",
    -text        => "Win32::GUI Gradent Fill demo",
    #NEM Events for this window
    -onTerminate => sub {return -1;}
);

#Create a child window
my $ChildWin = new Win32::GUI::Window (
    -parent      => $Win,
    -name        => "ChildWin",
    -pos         => [0, 0],
    -size        => [398, 398],
    -popstyle    => WS_CAPTION | WS_SIZEBOX,
    -pushstyle   => WS_CHILD | WS_CLIPCHILDREN,
    -pushexstyle => WS_EX_CLIENTEDGE,
    #NEM Events for this window
    -onPaint      => \&Paint,
);

#show both windows and enter the Dialog phase.
$Win->Show();
$ChildWin->Show();
Win32::GUI::Dialog();

sub Paint {
  #We need to paint our window
  my $win = shift;
  #get the DC
  my $dc = $win->GetDC;
  #draw a filled triangle, with points at 0,0 (blue) 100,100 (red) and 0,100 (green). 
  $dc->GradientFillTriangle(0,0,[0,0,255],100,100,[255,0,0],0,100,[0,255,0]);
  #draw a vertical filled rectangle red to blue 
  $dc->GradientFillRectangle(100,100,300,300,[255,0,0],[0,0,255],1);
  #draw a horizontal filled rectable black to while
  $dc->GradientFillRectangle(300,300,400,400,[0,0,0],[255,255,255]);
  $dc->Validate;
}
