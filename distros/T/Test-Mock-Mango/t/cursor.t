#!/usr/bin/env perl

use Test::More;
use Mango;

use_ok 'Test::Mock::Mango::Cursor';

my $cursor = Test::Mock::Mango::Cursor->new;

can_ok( $cursor, qw|all next count|);

done_testing();
