# plxload testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 1;

# ------ define variable
my $output = undef;	# output from plxload

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/plxload bin/plxload 2>&1`;
};

is($output, "", "modules loaded");

# TODO: Add tests after I get plxload working again
#is($?,        0,                "plxload runs");
#like($output, qr/Tie.*Hash.pm/, "listed loaded modules");
