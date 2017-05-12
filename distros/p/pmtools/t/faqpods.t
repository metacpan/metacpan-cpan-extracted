# faqpods testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 2;

# ------ define variable
my $output = undef;	# output from faqpods

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/faqpods 2>&1`;
};

is($?,        0,                    "faqpods runs");
like($output, qr/perlfaq[0-9].pod/, "found a Perl FAQ POD");
