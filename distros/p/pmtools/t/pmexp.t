# pmexp testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 2;

# ------ define variable
my $output = undef;	# output from pmexp

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/pmexp Carp 2>&1`;
};

is($?,        0,                                      "pmexp runs");
like($output, qr/Carp automatically exports confess/, "listed module exports");
