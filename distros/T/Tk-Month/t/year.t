# -*- perl -*-

use 5;
use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok( 'Tk' ); }
BEGIN { use_ok( 'Tk::Year' ); }

SKIP: {
	skip "No X11 display set", 1
		unless exists $ENV{DISPLAY};

	my $top=MainWindow->new();
	my $f = $top->Frame()->pack();
	my $m = $f->Button(
		-text		=> 'Exit',
		-command	=> sub { exit; },
	)->pack();
	my $a = $top->Year()->pack();
	
	ok($a, "Created and packed a Year object");
}

#MainLoop;


