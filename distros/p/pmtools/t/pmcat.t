# pmcat testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 2;

# ------ define variable
my $output = undef;	# output from pmcat

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/pmcat Carp 2>&1`;
};

is($?,        0,                                        "pmcat runs");
like($output, qr/.*package Carp\;.*\=head1 SYNOPSIS/ms, "catted Carp");
