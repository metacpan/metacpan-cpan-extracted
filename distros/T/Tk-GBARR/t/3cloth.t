use strict;
use vars '$loaded';
use Tk;

my $top;
BEGIN {
    if (!eval {
	$top = MainWindow->new;
    }) {
	print "1..0 # skip cannot open DISPLAY\n";
	CORE::exit;
    }
}

BEGIN { $^W= 1; $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tk::Cloth;
$loaded = 1;
my $ok = 1;
print "ok @{[ $ok++ ]}\n";

my $cloth;
eval {
    $cloth = $top->Cloth->pack;
};
if (!$cloth)                   { print "not " } print "ok @{[ $ok++ ]}\n";
if (ref $cloth ne 'Tk::Cloth') { print "not " } print "ok @{[ $ok++ ]}\n";

eval {
    $cloth->configure(-scrollregion => [-100, -100, 100, 100]);
};
if ($@) { print "not " } print "ok @{[ $ok++ ]}\n";


my $to = $cloth->Text(-coords => [0,0], -text => "blah", -anchor => "nw");
if (ref $to ne 'Tk::Cloth::Text') { print "not " } print "ok @{[ $ok++ ]}\n";

my $go;
eval {
    $go = $cloth->Grid(-coords => [0,0,20,10], -width => 3);
};
if (ref $go ne 'Tk::Cloth::Grid' and $Tk::VERSION > 800.015) { print "not " } print "ok @{[ $ok++ ]}\n";

my $r;
eval {
    $r = $cloth->Rectangle(
			   -coords => [0,0,100,100],
			   -fill => 'green'
			  );
};
if (ref $r ne 'Tk::Cloth::Rectangle') { print "not " } print "ok @{[ $ok++ ]}\n";

my $tag;
eval {
    $tag = $cloth->Tag;
};
if (ref $tag ne 'Tk::Cloth::Tag') { print "not " } print "ok @{[ $ok++ ]}\n";

my($ov1, $ov2);
eval {
    $ov1 = $tag->Oval(
		      -coords => [100,0,200,100],
		      -fill => 'blue'
		     );
    $ov2 = $tag->Oval(
		      -coords => [0,200,100,100],
		      -fill => 'red'
		     );
};
if (ref $ov1 ne 'Tk::Cloth::Oval' ||
    ref $ov2 ne 'Tk::Cloth::Oval') { print "not " } print "ok @{[ $ok++ ]}\n";

my $new_col;
eval {
    $tag->configure(-fill => "green");
    $new_col = $ov1->cget(-fill);
};
if ($new_col ne "green") { print "not " } print "ok @{[ $ok++ ]}\n";

$cloth->update;
#Tk::MainLoop;
