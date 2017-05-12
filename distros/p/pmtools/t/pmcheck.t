# pmcheck testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 2;

# ------ define variable
my $output = undef;	# output from pmcheck

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/pmcheck 2>&1`;
};

isnt($?,             127,  "pmcheck runs");
is(defined($output), 1,    "pmcheck had output");
