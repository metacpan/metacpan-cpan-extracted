# perl -w
#
# Drawing sample
#
use strict;
use warnings;

use Win32::GUI();

my $Menu = Win32::GUI::MakeMenu(
    "&Draw" => "&Draw",
    ">  &Dots"   => "DrawDots",
    ">  &Lines"   => "DrawLines",
    ">  &Boxes"   => { -name => "DrawBoxes", -checked => 1 },
    ">  &Circles" => "DrawCircles",
);

my $Win = new Win32::GUI::Window(
    -left   => 100,
    -top    => 100,
    -width  => 300,
    -height => 300,
    -name   => "Window",
    -text   => "Win32::GUI drawing demo",
    -menu   => $Menu,
);

my $Timer = $Win->AddTimer("Timer1", 1);

srand();

$Win->Show();
Win32::GUI::Dialog();

sub Window_Terminate {
    return -1;
}

sub DrawDots_Click {
    $Menu->{DrawDots}->Checked(1);
    $Menu->{DrawLines}->Checked(0);
    $Menu->{DrawBoxes}->Checked(0);
    $Menu->{DrawCircles}->Checked(0);
    $Win->InvalidateRect(1);
}

sub DrawLines_Click {
    $Menu->{DrawDots}->Checked(0);
    $Menu->{DrawLines}->Checked(1);
    $Menu->{DrawBoxes}->Checked(0);
    $Menu->{DrawCircles}->Checked(0);
    $Win->InvalidateRect(1);
}

sub DrawBoxes_Click {
    $Menu->{DrawDots}->Checked(0);
    $Menu->{DrawLines}->Checked(0);
    $Menu->{DrawBoxes}->Checked(1);
    $Menu->{DrawCircles}->Checked(0);
    $Win->InvalidateRect(1);
}

sub DrawCircles_Click {
    $Menu->{DrawDots}->Checked(0);
    $Menu->{DrawLines}->Checked(0);
    $Menu->{DrawBoxes}->Checked(0);
    $Menu->{DrawCircles}->Checked(1);
    $Win->InvalidateRect(1);
}

sub Timer1_Timer {
    my $W = $Win->ScaleWidth;
    my $H = $Win->ScaleHeight;
    my $DC = $Win->GetDC;
    my $left;
    my $top;
    my $right;
    my $bottom;
    my $P;
    my $oldP;
    my $B;
    my $oldB;

    if($Menu->{DrawDots}->Checked) {
        for(1..20) {
            $DC->SetPixel(
                rand()*$W, 
                rand()*$H, 
                [ rand()*255, rand()*255, rand()*255 ],
            );
        }
    } elsif($Menu->{DrawBoxes}->Checked) {
        $P = new Win32::GUI::Pen(   
            -color => [ rand()*255, rand()*255, rand()*255 ], 
            -width => rand()*5,
        );
        $B = new Win32::GUI::Brush(
            [ rand()*255, rand()*255, rand()*255 ]
        );
        $oldP = $DC->SelectObject($P);
        $oldB = $DC->SelectObject($B);
        $left   = rand()*$W;
        $top    = rand()*$H;
        $right  = $left + rand()*($W-$left);
        $bottom = $top + rand()*($H-$top);
        $DC->Rectangle($left, $top, $right, $bottom);
    } elsif($Menu->{DrawCircles}->Checked) {
        $P = new Win32::GUI::Pen(
            -color => [ rand()*255, rand()*255, rand()*255 ], 
            -width => rand()*5,
        );
        $B = new Win32::GUI::Brush(
            [ rand()*255, rand()*255, rand()*255 ]
        );
        $oldP = $DC->SelectObject($P);
        $oldB = $DC->SelectObject($B);
        $left   = rand()*$W;
        $top    = rand()*$H;
        $right  = $left + rand()*($W-$left);
        $bottom = $top + rand()*($H-$top);
        $DC->Ellipse($left, $top, $right, $bottom);
    } elsif($Menu->{DrawLines}->Checked) {
        $P = new Win32::GUI::Pen(
            -color => [ rand()*255, rand()*255, rand()*255 ], 
            -width => rand()*5,
        );
        $oldP = $DC->SelectObject($P);
        $DC->BeginPath();
        $DC->MoveTo(rand()*$W, rand()*$H);
        $DC->LineTo(rand()*$W, rand()*$H);
        $DC->EndPath();
        $DC->StrokePath();
    }
    
    # put the old brush/pen back, so that the new ones are correctly
    # released when their destructors are called
    $DC->SelectObject($oldP) if defined $oldP;
    $DC->SelectObject($oldB) if defined $oldB;
}
