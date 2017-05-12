# modpods testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 2;

# ------ define variable
my $output = undef;	# output from modpods

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/modpods 2>&1`;
};

is($?,        0,                  "modpods runs");
like($output, qr/Tie.*Hash.pm/, "found Tie::Hash");
