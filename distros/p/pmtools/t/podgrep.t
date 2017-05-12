# podgrep testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 2;

# ------ define variable
my $output = undef;	# output from podgrep

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/podgrep DESC bin/podgrep 2>&1`;
};

is($?, 0, "podgrep runs");
like($output, qr/^\=head1 DESCRIPTION/ms, "found DESCRIPTION");
