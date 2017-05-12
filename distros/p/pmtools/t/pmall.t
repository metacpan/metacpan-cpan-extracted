# pmall testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 2;

# ------ define variable
my $output = undef;	# output from pmall

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/pmall | t/head.pl 2>&1`;
};

is($?,        0,                               "pmall runs");
like($output, qr/^\w+.* \(\d+\.\d+\) - \w+/ms, "synopsized all modules");
