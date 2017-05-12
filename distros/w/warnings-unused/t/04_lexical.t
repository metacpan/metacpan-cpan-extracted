#!perl -w

# to resolve RT 39508

use strict;
use Test::More tests => 1;
use Test::Warn;

use File::Spec;
use FindBin qw($Bin);
use lib File::Spec->join($Bin, 'tlib');

use warnings::unused -lexical; # it's lexical by default

warning_is{
	require Foo;
} [], '-lexical (RT 39508)';
