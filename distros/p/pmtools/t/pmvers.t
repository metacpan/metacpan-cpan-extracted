# pmvers testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 2;

# ------ define variable
my $output = undef;	# output from pmvers

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/pmvers Tie::Hash 2>&1`;
};

is($?,        0,            "pmvers runs");
like($output, qr/^\d+\.\d/, "found version of Tie::Hash");
