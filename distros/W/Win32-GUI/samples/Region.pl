#!perl -w
#This example uses regions to create clipping areas in an DC.
use strict;
use warnings;

use Win32::GUI 1.03_03, qw( SB_THUMBTRACK SB_LINEDOWN SB_LINEUP
                            WS_CAPTION WS_SIZEBOX WS_CHILD
                            WS_CLIPCHILDREN WS_EX_CLIENTEDGE RGN_DIFF);

my $regiontype=0;

#Create the window and child controls.

my $Win = new Win32::GUI::Window (
    -pos         => [100, 100],
    -size        => [330, 235],
    -name        => "Window",
    -text        => "Win32::GUI Region demo",
    #NEM Events for this window
    -onTimer     => \&Timer,
    -onTerminate => sub {return -1;}
);

$Win->AddTimer("Timer", 1);

$Win->AddButton (
    -name        => 'rectange',
    -pos         => [205, 20],
    -size        => [110, 20],
    -text        => 'Rectangle',
    -onClick     => sub {$regiontype=0},
);

$Win->AddButton (
    -name        => 'Elliptic',
    -pos         => [205, 40],
    -size        => [110, 20],
    -text        => 'Elliptic',
    -onClick     => sub {$regiontype=1},
);

$Win->AddButton (
    -name        => 'Rounded Rectangle',
    -pos         => [205, 60],
    -size        => [110, 20],
    -text        => 'Rounded Rectangle',
    -onClick     => sub {$regiontype=2},
);

#Create a child window with a scroll bar. 
my $ChildWin = new Win32::GUI::Window (
    -parent      => $Win,
    -name        => "ChildWin",
    -pos         => [0, 0],
    -size        => [200, 200],
    -popstyle    => WS_CAPTION | WS_SIZEBOX,
    -pushstyle   => WS_CHILD | WS_CLIPCHILDREN,
    -pushexstyle => WS_EX_CLIENTEDGE,
    -hscroll     => 1,
    -onScroll    => \&Scroll,
);

my $H = $ChildWin->ScaleHeight;

#set the scroll bar range and position based upon
#the height of the child window.
$ChildWin->ScrollRange(0,0,$H);
$ChildWin->ScrollPos(0,$H/2);

#show both windows and enter the Dialog phase.
$Win->Show();
$ChildWin->Show();
Win32::GUI::Dialog();

sub Scroll {
    #scoll handler.
    my($win,$scrollbar, $operation, $position) = @_;
    if($operation == SB_THUMBTRACK) {
        $win->ScrollPos(0,$position);
    }
    elsif($operation == SB_LINEDOWN) {
        $win->ScrollPos(0,$win->ScrollPos(0)+1);
    }
    elsif($operation == SB_LINEUP) {
        $win->ScrollPos(0,$win->ScrollPos(0)-1);
    }
}

sub Timer {
    #get the dimentions and DC from the child window
    my $W = $ChildWin->ScaleWidth;
    my $H = $ChildWin->ScaleHeight;
    my $DC = $ChildWin->GetDC;
    #We could draw directly to the window, but to remove
    #drawing flicker we create a memory DC and draw to that.
    #Once drawing has been finished, we BitBlt the memory DC
    #direct into the window DC. 
    #
    #For a large amount of GDI drawing, the use of a memory DC
    #can also be quicker.
    #
    #We create a Compatible DC, and a Compatible Bitmap. To
    #improve performance you would
    #only recreate these objects if the dimentions of the source
    #DC have change. 
    my $DC2=$DC->CreateCompatibleDC();
    my $bit=$DC->CreateCompatibleBitmap($W,$H); 
    #Select the bitmap into the new DC
    my $oldbit = $DC2->SelectObject($bit);

    #The size of the region is based upon the scroll bar position
    #Don't allow it to be zero
    my $size=$ChildWin->ScrollPos(0) || 1;

    #Create a region
    my $region;
    if ($regiontype==0) {
        #create a rectangle region
        $region=CreateRectRgn Win32::GUI::Region(0,0,$size,$size);
    }
    elsif ($regiontype==1) {
        #create a Elliptic region (in this case a circle)
        $region=CreateEllipticRgn Win32::GUI::Region(0,0,$size,$size);
    }
    else {
        #create a rectangle region with rounded corners
        $region=CreateRoundRectRgn Win32::GUI::Region(0,0,$size,$size,20,20);
    }

    #Clear the area outside the region we are painting into:
    my $region2 = CreateRectRgn Win32::GUI::Region(0,0,$W,$H);
    my $region3 = CreateRectRgn Win32::GUI::Region(0,0,$W,$H);
    $region3->CombineRgn($region2,$region,RGN_DIFF);
    $DC2->PaintRgn($region3);

    #Use the region for clipping for the rest of the GDI operations.
    $DC2->SelectClipRgn($region);

    for(1..40) {
        #create a randon pen and brush, and select them into the DC
        my $P1 = new Win32::GUI::Pen(
            -color => [ rand()*255, rand()*255, rand()*255 ],
            -width => rand()*5,
        );
        my $B = new Win32::GUI::Brush([ rand()*255, rand()*255, rand()*255]);
        my $oldP = $DC2->SelectObject($P1);
        my $oldB = $DC2->SelectObject($B);
        my $left   = rand()*$W;
        my $top    = rand()*$H;
        my $right  = $left + rand()*($W-$left);
        my $bottom = $top + rand()*($H-$top);
        #create a random rectangle
        $DC2->Rectangle($left, $top, $right, $bottom);

        my $P2 = new Win32::GUI::Pen(
                -color => [ rand()*255, rand()*255, rand()*255 ],
                -width => rand()*5,
        );
        $DC2->SelectObject($P2);
        #create a random line
        $DC2->Line(rand()*$W,rand()*$H,rand()*$W, rand()*$H );

        #restore the original Pen and Brush so that the new ones
        #are not selected into the DC, and they get destroyed
        #when they go out of scope, otherwise we have a huge
        #resource leak, and quickly stop drawing correctly
        $DC2->SelectObject($oldP);
        $DC2->SelectObject($oldB);
    }

    #We now update the screen in one action
    $DC->BitBlt(0, 0, $W,$H,$DC2, 0, 0);

    #As for the Pen and Brush above, restore the original bitmap
    $DC2->SelectObject($oldbit);

    #We now delete the memory DC
    $DC2->DeleteDC();
}
