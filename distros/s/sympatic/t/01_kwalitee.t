use Test::More;
use Test::Kwalitee qw< kwalitee_ok >;
use strict;
use warnings;

$ENV{RELEASE_TESTING} or
    plan skip_all => q{no $RELEASE_TESTING (Author tests not required for installation)};

kwalitee_ok -use_strict;
done_testing;
