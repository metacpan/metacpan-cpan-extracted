use strict;
use warnings;
use utf8;
use Test::More tests => 2;
use Unicode::Subscript qw(SM TM);

is( SM(), '℠');
is( TM(), '™');

