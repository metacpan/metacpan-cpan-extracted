use strict;
use warnings;

use Test::More 'tests' => 1;
use Config;

SKIP: {
    skip "Threads not available", 1 unless $Config{useithreads};
    my $out = `$^X -Mblib t/threads.p 2>&1`;
    is($out, ''     => 'No destruct error');
}

# EOF
