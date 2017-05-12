#!/usr/bin/perl

use Test::More tests => 29;
use FindBin;
use strict;
use warnings;

use lib "$FindBin::Bin/../lib";

BEGIN {
	use_ok('VANAMBURG::FaceValueSingleton') || print "Bail out!";
}
my $fvs = VANAMBURG::FaceValueSingleton->instance;
isa_ok( $fvs,                      'VANAMBURG::FaceValueSingleton' );
isa_ok( $fvs->ace,                 'VANAMBURG::FaceValue' );
isa_ok( $fvs->two,                 'VANAMBURG::FaceValue' );
isa_ok( $fvs->three,               'VANAMBURG::FaceValue' );
isa_ok( $fvs->four,                'VANAMBURG::FaceValue' );
isa_ok( $fvs->five,                'VANAMBURG::FaceValue' );
isa_ok( $fvs->six,                 'VANAMBURG::FaceValue' );
isa_ok( $fvs->seven,               'VANAMBURG::FaceValue' );
isa_ok( $fvs->eight,               'VANAMBURG::FaceValue' );
isa_ok( $fvs->nine,                'VANAMBURG::FaceValue' );
isa_ok( $fvs->ten,                 'VANAMBURG::FaceValue' );
isa_ok( $fvs->jack,                'VANAMBURG::FaceValue' );
isa_ok( $fvs->queen,               'VANAMBURG::FaceValue' );
isa_ok( $fvs->king,                'VANAMBURG::FaceValue' );
isa_ok( $fvs->default_value_cycle, 'ARRAY' );
ok($fvs->facevalue_by_abbreviation('a')->equals($fvs->ace), 'a by abbrev');
ok($fvs->facevalue_by_abbreviation('2')->equals($fvs->two), '2 by abbrev');
ok($fvs->facevalue_by_abbreviation('3')->equals($fvs->three), '3 by abbrev');
ok($fvs->facevalue_by_abbreviation('4')->equals($fvs->four), '4 by abbrev');
ok($fvs->facevalue_by_abbreviation('5')->equals($fvs->five), '5 by abbrev');
ok($fvs->facevalue_by_abbreviation('6')->equals($fvs->six), '6 by abbrev');
ok($fvs->facevalue_by_abbreviation('7')->equals($fvs->seven), '7 by abbrev');
ok($fvs->facevalue_by_abbreviation('8')->equals($fvs->eight), '8 by abbrev');
ok($fvs->facevalue_by_abbreviation('9')->equals($fvs->nine), '9 by abbrev');
ok($fvs->facevalue_by_abbreviation('10')->equals($fvs->ten), '10 by abbrev');
ok($fvs->facevalue_by_abbreviation('j')->equals($fvs->jack), 'h by abbrev');
ok($fvs->facevalue_by_abbreviation('q')->equals($fvs->queen), 'q by abbrev');
ok($fvs->facevalue_by_abbreviation('k')->equals($fvs->king), 'k by abbrev');
1;
