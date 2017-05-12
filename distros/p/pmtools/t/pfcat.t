# pfcat testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 2;

# ------ define variable
my $output = undef;	# output from pfcat

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/pfcat seek 2>&1`;
};

is($?,        0,                                                     "pfcat runs");
like($output, qr/There is no .*systell.* function.\s+Use .*sysseek/, "catted module function");
