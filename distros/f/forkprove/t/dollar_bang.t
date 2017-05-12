# Run this with forkprove
use strict;
use Test::More;

open my $x, "/probablynonexistent"; # this sets $!

ok 1;
done_testing;
