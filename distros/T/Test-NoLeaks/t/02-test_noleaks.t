use strict;
use warnings;

use Test::More;
use Test::NoLeaks;
use Test::Warnings;

test_noleaks(
    code          => sub { },
    track_memory  => 1,
    track_fds     => 1,
    passes        => 2,
    warmup_passes => 1,
);

#my @leaked;
#test_noleaks (
#code          => sub{ my $x; push @leaked, $x; },
#track_memory  => 1,
#track_fds     => 0,
#passes        => 150000,
#warmup_passes => 0,
#);

done_testing;
