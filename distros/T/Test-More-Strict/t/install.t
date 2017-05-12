use strict;
use warnings;
use Test::More tests => 2;
use Test::More::Strict;

my $tb = Test::More->builder;
isa_ok $tb, 'Test::Builder';
isa_ok $tb, 'Test::More::Strict';
