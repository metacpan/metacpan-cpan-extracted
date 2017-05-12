# pods testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 2;

# ------ define variable
my $output = undef;	# output from pods

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/pods 2>&1`;
};

is($?, 0, "pods runs");
like($output, qr/Tie.*Hash.pm/, "found Tie::Hash");
