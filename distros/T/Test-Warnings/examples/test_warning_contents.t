use strict;
use warnings;

# this test demonstrates that warnings can be captured and tested, and other
# expected warnings can be whitelisted, to allow the had-no-warnings test not
# to fail

use Test::More tests => 2;
use Test::Warnings ':all';
use Test::Deep;

my @lines;
my @warnings = warnings {
    warn 'testing 1 2 3';   push @lines, __LINE__;
    warn 'another warning'; push @lines, __LINE__;
};

my $file = __FILE__;
cmp_deeply(
    \@warnings,
    [
        "testing 1 2 3 at $file line $lines[0].\n",
        "another warning at $file line $lines[1].\n",
    ],
    'successfully captured all warnings',
);

# make these warnings visible
allow_warnings;
warn $_ foreach @warnings;
allow_warnings(0);
