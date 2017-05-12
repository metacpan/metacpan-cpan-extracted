# pmls testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 2;

# ------ define variable
my $output = undef;	# output from pmls

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/pmls Tie::Hash 2>&1`;
};

is($?, 0, "pmls runs");
like($output, qr/Tie.*Hash.pm/, "found Tie::Hash");
