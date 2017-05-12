use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use Test::Builder::Tester;
use TAP::SimpleOutput 0.009 'counters', ':subtest';

{ package A; use Moose }

subtest checking => sub {
    validate_class A => (-subtest => 1);
    local $Test::Moose::More::THING_NAME = 'hi guys!';
    validate_class A => (-subtest => 1);
};


note '-subtest => 1 (TBT)';
{
    my ($_ok, $_nok, $_skip, $_plan, $_todo, $_freeform) = counters();

    my $subtest_name = 'A';
    test_out $_ok->('argh TBT');
    test_out subtest_header $_freeform => $subtest_name
        if subtest_header_needed;
    do {
        my ($_ok, $_nok, $_skip, $_plan, $_todo, $_freeform) = counters(1);
        test_out $_ok->('A has a metaclass');
        test_out $_ok->('A is a Moose class');
        test_out $_plan->();
    };
    test_out $_ok->($subtest_name);
    pass 'argh TBT';
    validate_class A => (-subtest => 1);
    test_test 'test w/-subtest';
}

done_testing;
