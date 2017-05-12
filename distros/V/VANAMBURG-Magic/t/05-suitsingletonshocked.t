#!/usr/bin/perl 

use Test::More tests => 20;
use FindBin;
use strict;
use warnings;

use lib "$FindBin::Bin/../lib";

BEGIN {
	use_ok('VANAMBURG::SuitSingletonSHoCkeD') || print "Bail out!";
}
my $ss = VANAMBURG::SuitSingletonSHoCkeD->instance;
isa_ok( $ss,          'VANAMBURG::SuitSingletonSHoCkeD' );
isa_ok( $ss->club,    'VANAMBURG::OrderedSuit' );
isa_ok( $ss->heart,   'VANAMBURG::OrderedSuit' );
isa_ok( $ss->spade,   'VANAMBURG::OrderedSuit' );
isa_ok( $ss->diamond, 'VANAMBURG::OrderedSuit' );

ok( $ss->spade->value == 1,                             'spade value' );
ok( $ss->heart->value == 2,                             'heart value' );
ok( $ss->club->value == 3,                              'club value' );
ok( $ss->diamond->value == 4,                           'diamond value' );

ok( $ss->spade->equals($ss->spade), 'spade is spade');
ok( $ss->spade->equals( $ss->heart) == 0, 'spade not heart');

ok( $ss->suit_cycle->[0] == $ss->spade,                 'suit cycle 0' );
ok( $ss->suit_cycle->[1] == $ss->heart,                 'suit cycle 1' );
ok( $ss->suit_cycle->[2] == $ss->club,                  'suit cycle 2' );
ok( $ss->suit_cycle->[3] == $ss->diamond,               'suit cycle 3' );

ok( $ss->next_suit( $ss->spade )->equals( $ss->heart ), 'next suit spade' );
ok( $ss->next_suit( $ss->heart )->equals( $ss->club ),  'next suit heart' );
ok( $ss->next_suit( $ss->club )->equals( $ss->diamond ),  'next suit club' );
ok( $ss->next_suit( $ss->diamond )->equals( $ss->spade ), 'next suit diamond' );
