# pmload testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 2;

# ------ define variable
my $output = undef;	# output from pmload

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/pmload Tie::Hash 2>&1`;
};

is($?,        0,               "pmload runs");
like($output, qr/strict.pm/ms, "listed loaded modules");
