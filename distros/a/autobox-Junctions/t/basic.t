use strict;
use warnings;

use Test::More;
use autobox::Junctions;

# we really only need to test the autoboxification sticks; the junctions
# themselves have (presumably) been tested in their own test suites.

my @one = ( 'a', 1, 2 );

subtest 'check with @array' => sub {

    ok @one->any   eq 2, 'any OK';
    ok @one->none  eq 'ten', 'none OK';
    ok !(@one->all eq 1), 'all OK';
    ok @one->one   eq 1, 'one OK';

    return;
};

my $two = [ @one ];

subtest 'check with @array' => sub {

    ok $two->any   eq 2, 'any OK';
    ok $two->none  eq 'ten', 'none OK';
    ok !($two->all eq 1), 'all OK';
    ok $two->one   eq 1, 'one OK';

    return;
};

done_testing;
