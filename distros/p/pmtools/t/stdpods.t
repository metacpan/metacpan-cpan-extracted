# stdpods testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 2;

# ------ define variable
my $output = undef;	# output from stdpods

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/stdpods 2>&1`;
};

is($?, 0, "stdpods runs");
like($output, qr/Tie.*Hash.pm/, "found Tie::Hash");
