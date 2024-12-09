#!perl

use strict;
use warnings;
use lib 'lib';
use Test::More tests => 1;
use YAGL;

my $g = YAGL->new;

my $is = $g->isa('YAGL');

isa_ok( $g, 'YAGL' );
