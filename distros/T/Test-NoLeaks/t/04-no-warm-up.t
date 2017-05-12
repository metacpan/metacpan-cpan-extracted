use strict;
use warnings;

use Test::More;
use Test::NoLeaks qw/noleaks/;
use Test::Warnings;

my $cache2;
ok !noleaks(
    code => sub { $cache2 = "a" x (10_000_000) unless $cache2; },
    track_memory  => 1,
    track_fds     => 1,
    passes        => 5,
    warmup_passes => 0,
    ),
    "there are leaks, because cache hasn't been warmed up";

done_testing;
