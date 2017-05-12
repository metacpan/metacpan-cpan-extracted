#This example creates a scrolling bitmap within another window. This example uses
#a hooked event to paint to the window directly, rather than using a Graphic
#Control.
use strict;
use warnings;

use Win32::GUI qw(WS_CLIPCHILDREN WS_CAPTION WS_SIZEBOX
                  WS_CHILD WS_EX_CLIENTEDGE
		  SB_ENDSCROLL SB_THUMBPOSITION);

#create a new class which stops the WM_ERASEBKGND message from erasing the background
#this stops the flicker of the window on resize.
my $WC = new Win32::GUI::Class(
    -name => "NoFlicker", 
    -style => 0,
);

#Create the window and child controls.
my $mainwin = new Win32::GUI::Window (
    -pos         => [100, 100],
    -size        => [330, 235],
    -name        => "Window",
    -text        => "Bitmap Scroll demo",
    -pushstyle   => WS_CLIPCHILDREN,
    -class       => $WC,
    #NEM Events for this window
    -onResize    => \&MainResize,
    -onTerminate => sub {return -1;}
);

$mainwin->AddButton (
    -name        => 'Open',
    -pos         => [205, 20],
    -size        => [110, 20],
    -text        => 'Open Bitmap',
    -onClick     => \&FindAndOpenBitmap,
);

#Define global variables
my $memdc;
my $bitmap;        #will hold the bitmap

#Create a child window with a scroll bars. 
my $ChildWin = new Win32::GUI::Window (
    -parent      => $mainwin,
    -name        => "ChildWin",
    -pos         => [0, 0],
    -size        => [200, 200],
    -popstyle    => WS_CAPTION | WS_SIZEBOX,
    -pushstyle   => WS_CHILD | WS_CLIPCHILDREN,
    -pushexstyle => WS_EX_CLIENTEDGE,
    -class       => $WC,
    -hscroll     => 1,
    -vscroll     => 1,
    -onScroll    => \&Scroll,
    -onResize    => sub {&Resize($bitmap,@_)},
    -onPaint     => sub {&Paint($memdc,@_)},
);

#Create a memory DC compatible with the child window DC
$memdc=$ChildWin->GetDC->CreateCompatibleDC();

#show both windows and enter the Dialog phase.
$mainwin->Show();
$ChildWin->Show();
Win32::GUI::Dialog();

sub Paint {
  #Paint event handler, called when ever the window needs to be redrawn/painted
  #get the window that needs to be repainted, in this case it is the child window
  my $mdc=shift;
  my $win=shift;
  my $dc=shift;
  #Perform a bit block transfer of the memory DC into the window DC
  #The cordinates are based upon the position of the scroll bars
  $dc->BitBlt($win->GetClientRect,$mdc,$win->ScrollPos(0),$win->ScrollPos(1));
  $dc->Validate();
  return 0;
}

sub AdjScroll
{ my $bmap = shift;
  my $cwin = shift;
  # Set the scroll bar page of each scroll bar.
  # This has the effect of increasing/decreasing the size of the bar within
  # the scroll bar as the window is resized.
  if ( $bmap )
  { my ( $width, $height ) = $bmap->Info();
    my ( $cwid, $chei ) = ( $cwin->GetClientRect )[ 2 .. 3 ];
    my ( $sx, $sy ) = ( $cwin->ScrollPos( 0 ), $cwin->ScrollPos( 1 ));
    while ( 1 )
    { # the ScrollPage calls might trigger a Resize event, so this code might
      # run reentrantly.  To be sure we don't use old data later and overwrite
      # newer data, we reobtain the ClientRect after each operation that might
      # change it.
      $cwin->ScrollPage( 0, $cwid );
      my ( $cwidA, $cheiA ) = ( $cwin->GetClientRect )[ 2 .. 3 ];
      $cwin->ScrollPage( 1, $cheiA );
      my ( $cwid2, $chei2 ) = ( $cwin->GetClientRect )[ 2 .. 3 ];
      last if $cwid == $cwid2  &&  $chei == $chei2;
      ( $cwid, $chei ) = ( $cwid2, $chei2 );
    }
    if ( $sx != $cwin->ScrollPos( 0 )  ||  $sy != $cwin->ScrollPos( 1 ))
    { $cwin->InvalidateRect( 0 );
    }
  }
}

sub MainResize {
  my $win=shift;
  my ($width, $height) = ($win->GetClientRect)[2..3];
  $win->Open->Left($width-120);
  $win->ChildWin->Resize($width-150,$height);
  return 1;
}

sub Resize
{ # Resize handler, get the window
  AdjScroll( $_[ 0 ], $_[ 1 ] );
  return 1;
}

my ( %state );

sub OpenBitmap
{ my ( $bmap, $mdc, $cwin ) = @_;
  if ( $bmap )
  { # if we have a valid bitmap, get the dimensions
    my ( $width, $height ) = $bmap->Info();
    # select the bitmap into the memory DC so it can be manipulated later.
    $mdc->SelectObject( $bmap );
    # set the scroll bars to 0, unless same size as before
    if ( ! exists $state{ $cwin }
      ||  $state{ $cwin }[ 0 ] != $width
      ||  $state{ $cwin }[ 1 ] != $height )
    { $state{ $cwin } = [ $width, $height ];
      $cwin->ScrollRange( 0, 0, $width - 1 );
      $cwin->ScrollRange( 1, 0, $height - 1 );
      $cwin->ScrollPos( 0, 0 );
      $cwin->ScrollPos( 1, 0 );
    }
    AdjScroll( $bmap, $cwin );
    # invalidate the child window so windows triggers the paint event
    $cwin->InvalidateRect( 1 );
  }
  return 1;
}

sub FindAndOpenBitmap {
  #Function to load in the bitmap
  my $file = Win32::GUI::GetOpenFileName(
                   -owner => $mainwin,
                   -hidereadonly => 0,
                   -title  => "Open an bitmap file",
                   -filter => ['Bitmaps' => '*.bmp',
                               'All files'    => '*.*',
                              ],                
                   );
  $bitmap=new Win32::GUI::Bitmap($file);   
  if ($bitmap) {
    OpenBitmap($bitmap,$memdc,$ChildWin);
  }
  return 1;
}

sub Scroll {
  # Scroll event handler. We have to explicitly "move" the scroll bars.
  # Once they have been moved, we repaint the window.
  my( $win, $scrollbar, $operation, $position ) = @_;
  if ( $operation != SB_ENDSCROLL  &&  $operation != SB_THUMBPOSITION )
  { $win->Scroll( $scrollbar, $operation, -1, 1 );
    $win->InvalidateRect( 0 );
  }
  return 1;
}
