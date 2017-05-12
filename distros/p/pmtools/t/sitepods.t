# sitepods testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 1;

# ------ define variable
my $output = undef;	# output from sitepods

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/sitepods 2>&1`;
};

is($?, 0, "sitepods runs");
# No more tests because we might not have any site-specific PODS
