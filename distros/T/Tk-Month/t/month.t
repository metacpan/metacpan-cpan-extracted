# -*- perl -*-

# Test script for the Tk Tk::Month widget.

use 5;
use warnings;
use strict;

use Test::More tests => 3;

BEGIN { use_ok( 'Tk' ); }
BEGIN { use_ok( 'Tk::Month' ); }

my $delay  = 0;
my $period = 5000;

SKIP: {
	skip "no X11 display variable set", 1 unless (exists $ENV{'DISPLAY'});

	my $top=MainWindow->new();
	my $f = $top->Frame()->pack();
	my $m = $f->Button(
		-text		=> 'Exit',
		-command	=> sub { exit; },
	)->pack();
	my $a = $top->Month()->pack();

	ok($a, 'Create an object and pack it');
}

#MainLoop;

