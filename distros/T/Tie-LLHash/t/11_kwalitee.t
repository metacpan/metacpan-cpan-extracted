use strict;
use warnings;

BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        use Test::More;
        plan(skip_all => 'these tests are for release candidate testing');
    }
}

eval {
    require Test::Kwalitee;
    Test::Kwalitee->import();
    1;
} or do {
    plan(skip_all => 'Test::Kwalitee not installed; skipping');
    done_testing();
};
