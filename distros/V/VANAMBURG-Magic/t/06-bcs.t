#!/usr/bin/perl 

use Test::More tests => 6;
use FindBin;
use strict;
use warnings;

use lib "$FindBin::Bin/../lib";

BEGIN {
	use_ok('VANAMBURG::BCS') || print "Bail out!";
}

my $bcs = VANAMBURG::BCS->new;
isa_ok($bcs, 'VANAMBURG::BCS');
ok($bcs->card_count == 52, 'bcs card count');

ok( $bcs->top_card->abbreviation eq 'AS', 'bcs top card');
ok( $bcs->bottom_card->abbreviation eq 'KS', 'bcs bottom card');
ok( $bcs->card_at_location(5)->abbreviation eq 'QC', 'card at location 5');