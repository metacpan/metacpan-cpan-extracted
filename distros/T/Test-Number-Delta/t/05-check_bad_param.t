use strict;
use Test::More tests => 6;

require_ok("Test::Number::Delta");

eval { Test::Number::Delta->import( within => 0.1, relative => 0.01 ) };
like(
    $@,
    "/Can't specify more than one of 'within' or 'relative'/",
    "Import dies with both parameters"
);

for my $p (qw/within relative/) {
    eval { Test::Number::Delta->import( $p => 0 ) };
    like(
        $@,
        "/'$p' parameter must be non-zero/",
        "Import dies if '$p' parameter is zero"
    );
}

eval { Test::Number::Delta::delta_within( 0.1, 0.3, 0, "foo" ) };
like(
    $@,
    "/Value of epsilon to delta_within must be non-zero/",
    "delta_within dies if epsilon is zero"
);
eval { Test::Number::Delta::delta_not_within( 0.1, 0.3, 0, "foo" ) };
like(
    $@,
    "/Value of epsilon to delta_not_within must be non-zero/",
    "delta_not_within dies if epsilon is zero"
);
