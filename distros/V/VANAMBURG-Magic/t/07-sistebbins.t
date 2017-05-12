#!/usr/bin/perl 

use Test::More tests => 32;
use FindBin;
use strict;
use warnings;

use lib "$FindBin::Bin/../lib";

BEGIN {
	use_ok('VANAMBURG::SiStebbins') || print "Bail out!";
}
my $si = VANAMBURG::SiStebbins->new;
isa_ok( $si, 'VANAMBURG::SiStebbins' );
ok( $si->card_count == 52, 'si stebbins chased card count' );
ok( $si->card_at_location(1)->abbreviation eq 'AC',  'top card' );
ok( $si->card_at_location(2)->abbreviation eq '4H',  'card 2' );
ok( $si->card_at_location(3)->abbreviation eq '7S',  'card 3' );
ok( $si->card_at_location(4)->abbreviation eq '10D', 'card 4' );
ok( $si->card_at_location(5)->abbreviation eq 'KC',  'card 5' );
ok( $si->card_at_location(6)->abbreviation eq '3H',  'card 6' );
ok( $si->card_at_location(7)->abbreviation eq '6S',  'card 7' );
ok( $si->card_at_location(8)->abbreviation eq '9D',  'card 8' );
ok( $si->card_at_location(9)->abbreviation eq 'QC',  'card 9' );

my $si_shocked = VANAMBURG::SiStebbins->new( suit_order => 'SHoCkeD' );
ok( $si_shocked->card_count == 52, 'si_shocked  card count' );
ok( $si_shocked->card_at_location(1)->abbreviation eq 'AS',  'top card' );
ok( $si_shocked->card_at_location(2)->abbreviation eq '4H',  'card 2' );
ok( $si_shocked->card_at_location(3)->abbreviation eq '7C',  'card 3' );
ok( $si_shocked->card_at_location(4)->abbreviation eq '10D', 'card 4' );
ok( $si_shocked->card_at_location(5)->abbreviation eq 'KS',  'card 5' );
ok( $si_shocked->card_at_location(6)->abbreviation eq '3H',  'card 6' );
ok( $si_shocked->card_at_location(7)->abbreviation eq '6C',  'card 7' );
ok( $si_shocked->card_at_location(8)->abbreviation eq '9D',  'card 8' );
ok( $si_shocked->card_at_location(9)->abbreviation eq 'QS',  'card 9' );

my $si_shocked_4 =
  VANAMBURG::SiStebbins->new( suit_order => 'SHoCkeD', step => 4 )
  ;
ok( $si_shocked_4->card_count == 52, 'si_shocked_4  card count' );
ok( $si_shocked_4->card_at_location(1)->abbreviation eq 'AS', 'top card' );
ok( $si_shocked_4->card_at_location(2)->abbreviation eq '5H', 'card 2' );
ok( $si_shocked_4->card_at_location(3)->abbreviation eq '9C', 'card 3' );
ok( $si_shocked_4->card_at_location(4)->abbreviation eq 'KD', 'card 4' );
ok( $si_shocked_4->card_at_location(5)->abbreviation eq '4S', 'card 5' );
ok( $si_shocked_4->card_at_location(6)->abbreviation eq '8H', 'card 6' );
ok( $si_shocked_4->card_at_location(7)->abbreviation eq 'QC', 'card 7' );
ok( $si_shocked_4->card_at_location(8)->abbreviation eq '3D', 'card 8' );
ok( $si_shocked_4->card_at_location(9)->abbreviation eq '7S', 'card 9' );
