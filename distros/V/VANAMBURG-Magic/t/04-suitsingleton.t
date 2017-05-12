#!/usr/bin/perl 

use Test::More tests => 11;
use FindBin;
use strict;
use warnings;

use lib "$FindBin::Bin/../lib";

BEGIN {
	use_ok('VANAMBURG::SuitSingleton') || print "Bail out!";
}
my $ss = VANAMBURG::SuitSingleton->instance;
isa_ok( $ss,          'VANAMBURG::SuitSingleton' );
isa_ok( $ss->club,    'VANAMBURG::Suit' );
isa_ok( $ss->heart,   'VANAMBURG::Suit' );
isa_ok( $ss->spade,   'VANAMBURG::Suit' );
isa_ok( $ss->diamond, 'VANAMBURG::Suit' );
ok($ss->suit_by_abbreviation('S')->equals($ss->spade), 's by abbrev');
ok($ss->suit_by_abbreviation('H')->equals($ss->heart), 'h by abbrev');
ok($ss->suit_by_abbreviation('C')->equals($ss->club), 'c by abbrev');
ok($ss->suit_by_abbreviation('D')->equals($ss->diamond), 'd by abbrev');
ok(!($ss->suit_by_abbreviation('D')->equals($ss->spade)), 'd by abbrev not spade');
