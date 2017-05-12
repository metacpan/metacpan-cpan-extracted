#!/usr/bin/perl 

use Test::More tests => 5;
use FindBin;
use strict;
use warnings;

use lib "$FindBin::Bin/../lib";

BEGIN {
	use_ok('VANAMBURG::Suit') || print "Bail out!";
}
my $hearts = VANAMBURG::Suit->new(
	name         => "Hearts",
	unicode_char => "\x{2661}",
	abbreviation => 'H'
);
ok( $hearts->name eq "Hearts", 'suit name' );
ok( $hearts->abbreviation eq "H",        'suit abbreviation' );
ok( $hearts->unicode_char eq "\x{2661}", 'suit unicode_char' );
my $hearts2 = VANAMBURG::Suit->new(
	name         => "Hearts",
	unicode_char => "\x{2661}",
	abbreviation => 'H'
);

ok( $hearts->equals($hearts2), 'suit equals' );
