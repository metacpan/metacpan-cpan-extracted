BEGIN {
    unshift(@INC, "lib");
}

use strict;
use warnings;
use Tk;
use TkUtil::Configure;

my $canvasL;
my $canvasR;

sub Banner {
    $canvasL->createText(10, 100, -text => "Please resize me", 
        -font => "Courier 24", -fill => 'black', -anchor => 'nw');
}

my $mw;
eval qq(\$mw = MainWindow->new);
if ($@) {
    print STDERR "No DISPLAY to connect to\n";
    exit(0);
}
my $frame = $mw->Frame->pack(-fill => 'both', -expand => 1);
$canvasL = $frame->Canvas(-width => 300, -background => 'light blue')->
    pack(-side => 'left', -fill => 'y', -expand => 1);
$canvasR = $frame->Canvas(-width => 300, -background => 'red')->
    pack(-side => 'left', -fill => 'both', -expand => 1);

Banner();

my $tkc;
$tkc = TkUtil::Configure->new(top => $mw, on => [$canvasL, $canvasR, $frame], 
    callback =>
    sub { 
        my ($widget, $w, $h) = @_;
        if (ref($widget) =~ /^Tk::Frame/) {
            $mw->title("Overall frame resize $w x $h");
        }
        else {
            $widget->delete('all');
            Banner();
            my $culled = $tkc->culled();
            my $msg = "this canvas is now $w x $h (culled from $culled)";
            $widget->createText(10, 140, -text => $msg, -anchor => 'nw');
            # draw line to show we really have dimensions right
            $widget->createLine(0, 0, $w-1, $h-1, -fill => 'black');
        }
    }
);

MainLoop;
