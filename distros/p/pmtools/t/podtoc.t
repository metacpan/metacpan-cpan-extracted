# podtoc testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 2;

# ------ define variable
my $output = undef;	# output from podtoc

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/podtoc bin/podtoc 2>&1`;
};

is($?, 0, "podtoc runs");
like(
    $output,
    qr/NAME.*DESCRIPTION.*EXAMPLES.*SEE ALSO.*AUTHORS and COPYRIGHTS.*LICENSE/ms,
    "found Table of Contents"
);
