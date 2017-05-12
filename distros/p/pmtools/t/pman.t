# pman testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 2;

# ------ define variable
my $output = undef;	# output from pman

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/pman Carp 2>&1`;
};

is($?, 0, 'pman runs');

like($output, qr/NAME.*[Cc]arp - \w.*SYNOPSIS.*DESCRIPTION/ms, 'found Carp');
