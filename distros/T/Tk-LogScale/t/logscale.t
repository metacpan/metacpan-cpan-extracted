use strict;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "# tests only work with installed Test::More module\n";
	print "1..1\n";
	print "ok 1\n";
	exit;
    }
}

use Tk;

my $top;
BEGIN {
    if (!eval { $top = new MainWindow }) {
	print "1..0 # skip cannot open DISPLAY\n";
	CORE::exit;
    }
}

use Tk::LabFrame;

plan tests => 5;

if (!defined $ENV{BATCH}) { $ENV{BATCH} = 1 }
if (@ARGV && $ARGV[0] eq '-demo') { $ENV{BATCH} = 0 }

use_ok("Tk::LogScale");

my @bla;
$bla[$_] = 50000 for (0..3);

$top->geometry('+1+1'); # for twm

my $li = 0;
foreach my $orient ('horizontal', 'vertical') {
    foreach my $showvalue (0, 1) {
	my $f = $top->LabFrame(-label => "-orient: $orient, -showvalue: $showvalue:", -labelside => "acrosstop")->pack(-fill => "x");
	my $ls = $f->LogScale(-variable => \$bla[$li],
			      -showvalue => $showvalue,
			      -resolution => 0.01,
			      -orient => $orient,
			      -from => 1000,
			      -to => 100000,
			      -background => "red",
			      -valuefmt => sub { sprintf("1:%d", $_[0]) },
			      -func    => sub { eval { log($_[0])/log(10) } },
			      -invfunc => sub { 10**$_[0] },
			      -command => sub { diag "Changed to $_[0]" },
			     )->pack(-fill => ($orient eq 'horizontal' ? "x" : "y"));
	isa_ok($ls, "Tk::LogScale");
	$li++;
    }
}

$top->update;

{
    my $f = $top->LabFrame(-label => "Value of \$bla[3]",
			   -labelside => "acrosstop")->pack(-fill => "x");
    $f->Label(-width => 30,
	      -textvariable => \$bla[3],
	     )->pack;

    $f->Button(-text => "Set to (approx.) 50000",
	       -command => sub { $bla[3] = 50000 })->pack;
}

if (1) {
    # hack to allow only odd numbers from 3 to 13
    my $bla2 = 1;
    my $l;
    my $orient = "vertical";
    my $f = $top->LabFrame(-label => "Allow only odd numbers from 3 to 13",
			   -labelside => "acrosstop")->pack(-fill => "x");
    $l = $f->LogScale(-variable => \$bla2,
		      -showvalue => 1,
		      -resolution => 4,
		      -orient => $orient,
		      -from => 3,
		      -to => 13,
		      -func    => sub { ($_[0]-3)*2 },
		      -invfunc => sub { ($_[0]/2)+3 },
		      -command => sub { diag "Odd number: $_[0]" },
		     )->pack;
}

$top->Button(-text => "OK",
	     -command => sub {
		 $top->destroy;
	     })->pack;

if ($ENV{BATCH}) {
    $top->after(500, sub { $top->destroy });
}
MainLoop;
