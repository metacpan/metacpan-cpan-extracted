#!/pro/bin/perl

use strict;
use warnings;

use Tk;
use Tk::Clock;

my @bw = reverse qw( Black White );

my $m = MainWindow->new;

$m->configure (
    -foreground	=> $bw[0],
    -background	=> $bw[1],
    );

my $face = $^O =~ m/mswin/i ? "Arial" : "DejaVu Sans Mono";

my $c = $m->Clock (
    -background	=> $bw[1],
    -relief	=> "flat",
   )->pack (
    -expand	=> 1,
    -fill	=> "both",
    -padx	=> 30,
    -pady	=> 30,
    -side	=> "left",
    );
$c->config (
    useDigital	=> 0,
    useInfo	=> 1,
    useAnalog	=> 1,
    secsColor	=> "Red",
    handColor	=> $bw[0],
    tickColor	=> $bw[0],
    tickFreq	=> 1,
    tickDiff	=> 1,
    handCenter	=> 1,
    anaScale	=> 800,
    autoScale	=> 1,
    infoFormat	=> "",
    infoFont	=> "{$face} 48",
    infoColor	=> "Gray10",
    );

my ($l, $rest, $end, $secs, $left) = ("");

sub rest
{
    use integer;
    my $now = time;

    unless (defined $end) {
	$rest = "";
	$secs = "";
	$left = "";
	$end  = undef;
	return;
	}

    $now > $end and return;

    $secs = $end - $now;
    $rest = int (($secs + 10) / 60);

    $l->configure (
	-background	=> "Black",
	-foreground	=>
	    $rest >  5 ? "Green4" :
	    $rest >  3 ? "Yellow" :
	    $secs > 60 ? "Orange" : "Red");

    $left = sprintf "%02d:%02d", $secs / 60, $secs % 60;
    $c->config (infoFormat => $left);
    $secs == 60 and $l->bell for 1..2;
    $secs  < 60 and $rest = $secs;

    if ($rest) {
	$l->after (100, \&rest);
	return;
	}

    $l->bell for 1..10;
    $l->configure (-background	=> "Red");
    $l->after (30000, sub { $l->configure (-background => "Black") });
    $c->config (infoFormat => "");
    $rest = "";
    $end  = undef;
    } # rest

sub start
{
    my $val = 60 * shift;
    $end = time + $val;
    rest ();
    } # start

my $f = $m->Frame (-background => "Black")->pack (
    -expand	=> 1,
    -padx	=> 30,
    -pady	=> 30,
    -fill	=> "both",
    -side	=> "left",
    );

$l = $f->Label (
    -textvariable	=> \$rest,
    -font		=> "{$face} 200 bold",
    -background		=> "Black",
    )->pack (-expand => 1, -side => "top", -fill => "both", -anchor => "c");

my $g    = $f->Frame (-background => "Black")->pack (
    -side => "bottom", -anchor => "se", -fill => "x");
my $ctrl = $g->Frame (-background => "Black")->pack (
    -side => "bottom", -anchor => "se", -fill => "x");
my $smll = $g->Frame (-background => "Black")->pack (
    -side => "top",    -anchor => "s",  -fill => "x");

$smll->Label (
    -textvariable	=> \$secs,
    -background		=> "Black",
    -foreground		=> "Yellow",
    -anchor		=> "sw",
    )->pack (-side => "left",  -anchor => "w");
$smll->Label (
    -textvariable	=> \$left,
    -background		=> "Black",
    -foreground		=> "Yellow",
    -anchor		=> "se",
    )->pack (-side => "right", -anchor => "e");

my %bo = (
    -borderwidth	=> 1,
    -highlightthickness	=> 1,
    -relief		=> "flat",
    -activebackground	=> "Gray10",
    -activeforeground	=> "Red2",
    -highlightcolor	=> "Red2",
    -background		=> "Black",
    -foreground		=> "Red2",
    );
for (1 .. 6) {
    my $d = 5 * $_;
    $ctrl->Button (%bo,
	-text		=> $d,
	-font	=> "fixed",
	-command	=> sub { start ($d) },
	)->grid (-row => 0, -column => $_ - 1, -sticky => "news");
    }

$ctrl->Button (%bo,
    -text	=> " 0",
    -font	=> "fixed",
    -command	=> sub { $end = undef; rest (); },
    )->grid (-row => 1, -column => 0, -sticky => "news");
$ctrl->Button (%bo,
    -text	=> "-1",
    -font	=> "fixed",
    -command	=> sub { defined $end and $end -= 60; },
    )->grid (-row => 1, -column => 1, -sticky => "news");
$ctrl->Button (%bo,
    -text	=> "-\x{00bd}",
    -font	=> "fixed",
    -command	=> sub { defined $end and $end -= 30; },
    )->grid (-row => 1, -column => 2, -sticky => "news");
$ctrl->Button (%bo,
    -text	=> "+\x{00bd}",
    -font	=> "fixed",
    -command	=> sub { defined $end and $end += 30; },
    )->grid (-row => 1, -column => 3, -sticky => "news");
$ctrl->Button (%bo,
    -text	=> "+1",
    -font	=> "fixed",
    -command	=> sub { defined $end and $end += 60; },
    )->grid (-row => 1, -column => 4, -sticky => "news");
$ctrl->Button (%bo,
    -text	=> "XX",
    -font	=> "fixed",
    -command	=> sub { exit; },
    )->grid (-row => 1, -column => 5, -sticky => "news");

$ctrl->gridColumnconfigure ($_, -weight => 1) for 0..5;

MainLoop;
