
BEGIN {
    use Test::More;
    unless ($ENV{RELEASE_TESTING}) {
        plan skip_all => 'Release test. Set $ENV{RELEASE_TESTING} to a true value to run.';
    }
}

use strict;
use warnings;

eval "use Test::Kwalitee 'kwalitee_ok'";
plan skip_all => "Test::Kwalitee required for testing kwalitee" if $@;

kwalitee_ok();
done_testing;
