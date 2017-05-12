#!perl

use strict;
use warnings FATAL => 'all';
use Test::Most qw(!code);
use Tie::Symbol;

plan tests => 1;

isa_ok( Tie::Symbol->new() => 'Tie::Symbol' ) or BAIL_OUT('');

done_testing;
