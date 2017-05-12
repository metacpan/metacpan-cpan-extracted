use strict;
use warnings;

use Test::More;
use Test::NoLeaks qw/noleaks/;
use Test::Warnings;

ok !noleaks(
    code => sub {
        my @array = map { "a" x (1000) } (1 .. 25);
        push @array, \@array for (1 .. 25_0000);
    },
    track_memory  => 1,
    track_fds     => 1,
    passes        => 5,
    warmup_passes => 0,
    ),
    "this is surely is a leak";

done_testing;
