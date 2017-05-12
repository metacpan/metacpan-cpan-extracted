use strict;
use warnings;


{
    package TestRole;
    use Moose::Role;
}
{
    package TestClass;
    use Moose;
}
{
    package TestClass::Fail;
}

use Test::Builder::Tester; # tests => 1;
use Test::More;
use Test::Moose::More;

use TAP::SimpleOutput 'counters';

my $ROLE = 'TestRole::Role';

for my $thing (qw{ TestClass TestRole }) {
    # role - OK
    my ($_ok, $_nok) = counters();
    test_out $_ok->("$thing has a meta");
    meta_ok $thing;
    test_test "$thing is found to have a metaclass correctly";
}

for my $thing (qw{ TestClass::Fail }) {
    # role - NOT OK
    my ($_ok, $_nok) = counters();
    test_out $_nok->("$thing has a meta");
    test_fail 1;
    meta_ok $thing;
    test_test "$thing is found to not have a metaclass correctly";
}

done_testing;
