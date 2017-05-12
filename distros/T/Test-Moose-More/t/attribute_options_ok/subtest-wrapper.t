use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;
use TAP::SimpleOutput 0.009 'counters', ':subtest';

# The sole question this test addresses is: "Does has_attribute_ok()'s
# -subtest option work as expected?"  As such, there are no role vs class
# specific moving parts for us to worry about here.
#
# Role is included in the "sanity" (aka "what it actually looks like") tests
# because the author is lazy, and doesn't really want to have to do it in the
# future ;)  (aka "may be valuable in debugging")

{ package TestRole;  use Moose::Role; has foo => (is => 'ro'); no Moose }
{ package TestClass; use Moose;       has foo => (is => 'ro'); no Moose }

subtest 'sanity run w/subtests' => sub {
    attribute_options_ok $_ => foo => (is => 'ro', -subtest => "$_ w/subtests")
        for qw{ TestClass TestRole };
};

subtest 'sanity run w/o subtests' => sub {
    attribute_options_ok $_ => foo => (is => 'ro')
        for qw{ TestClass TestRole };
};

note 'test w/-subtest';
{
    my ($_ok, $_nok, $_skip, $_plan, $_todo, $_freeform) = counters();

    test_out $_ok->('TestClass has an attribute named foo');
    my $subtest_name = 'TestClass w/subtests';
    test_out subtest_header $_freeform => $subtest_name
        if subtest_header_needed;
    do {
        my ($_ok, $_nok, $_skip, $_plan, $_todo, $_freeform) = counters(1);
        test_out $_ok->('foo has a reader');
        test_out $_ok->('foo option reader correct');
        test_out $_plan->();
    };
    test_out $_ok->($subtest_name);
    attribute_options_ok $_ => foo => (is => 'ro', -subtest => "$_ w/subtests")
        for 'TestClass';
    test_test 'test w/-subtest';
}

note 'test w/o subtest';
{
    my ($_ok, $_nok, $_skip, $_plan, $_todo, $_freeform) = counters();

    test_out $_ok->('TestClass has an attribute named foo');
    test_out $_ok->('foo has a reader');
    test_out $_ok->('foo option reader correct');
    attribute_options_ok $_ => foo => (is => 'ro')
        for 'TestClass';
    test_test 'test w/o subtest';
}

done_testing;
