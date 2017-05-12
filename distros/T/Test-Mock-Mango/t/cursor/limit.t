#!/usr/bin/env perl

use Test::More;
use Mango;

use Test::Mock::Mango;
use Test::Mock::Mango::Cursor;

my $cursor = Test::Mock::Mango::Cursor->new;

plan tests => 2;

can_ok $cursor, qw|limit|;

isa_ok $cursor->limit(10), 'Test::Mock::Mango::Cursor';

done_testing();

