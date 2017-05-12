#!/usr/bin/perl 

use Test::More tests => 4;
use FindBin;
use strict;
use warnings;

use lib "$FindBin::Bin/../lib";

BEGIN {
	use_ok('VANAMBURG::FaceValue') || print "Bail out!";
}

my $king = VANAMBURG::FaceValue->new(
	name         => "King",
	value        => 13,
	abbreviation => 'K'
);

ok( $king->name eq "King", 'facevalue name' );
ok( $king->value == 13, 'facevalue value' );
ok( $king->abbreviation eq "K", 'facevalue abbreviation' );
