use strict;
use warnings;

use Test::More;
use Test::NoLeaks qw/noleaks/;
use Test::Warnings;

# request large array, that should trigger additional memory alloactions
ok !noleaks(
    code => sub { my $x = "a" x (10_000_000); },
    track_memory  => 1,
    track_fds     => 0,
    passes        => 5,
    warmup_passes => 0,
    ),
    "non-tolerate way might trigger memory false memory leaks report";

done_testing;
