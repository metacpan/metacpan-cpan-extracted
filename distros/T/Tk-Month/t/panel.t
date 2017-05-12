# -*- perl -*-


use 5;
use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok( 'Tk' ); }
BEGIN { use_ok( 'Tk::Panel' ); }

SKIP: {
	skip "No X11 display set", 1
		unless exists $ENV{DISPLAY};

	my $top=MainWindow->new();
	my $f = $top->Panel()->pack();
	my $m = $f->Button(
		-text		=> 'Exit',
		-command	=> sub { exit; },
	)->pack();
	
	ok($f, "Created and packed a Panel object");
}

#MainLoop;

