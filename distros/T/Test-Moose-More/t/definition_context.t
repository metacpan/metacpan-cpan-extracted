use strict;
use warnings;

use Test::More;
use Test::Moose::More ':all';
use Test::Builder::Tester;
use TAP::SimpleOutput 0.009 'counters';

{
    package AAA;
    use Moose;

    has foo => (
        is => 'ro',
    );

    sub bar { }
}

subtest 'plain - method' => sub {
    definition_context_ok(AAA->meta->get_method('foo'), {
        context     => 'has declaration',
        description => 'reader AAA::foo',
        line        => 13,
        package     => 'AAA',
        type        => 'class',
        file        => __FILE__,
    });
};

subtest 'plain - attribute' => sub {
    definition_context_ok(AAA->meta->get_attribute('foo'), {
        context => 'has declaration',
        file    => __FILE__,
        line    => 13,
        package => 'AAA',
        type    => 'class'
    });
};

# NOTE begin Test::Builder::Tester tests

{
    my ($_ok, $_nok) = counters;

    test_out $_ok->('foo can definition_context()');
    test_out $_ok->('foo definition context is strictly correct');
    definition_context_ok(AAA->meta->get_attribute('foo'), {
        context => 'has declaration',
        file    => __FILE__,
        line    => 13,
        package => 'AAA',
        type    => 'class'
    });
    test_test 'output as expected';
}

{
    my ($_ok, $_nok) = counters;

    test_out $_ok->('foo can definition_context()');
    test_out $_nok->('foo definition context is strictly correct');
    test_err
        q{#   Failed test 'foo definition context is strictly correct'},
        qr{#   at .* line 69.\n},
        q{#     Structures begin differing at:},
        q{#          $got->{package} = 'AAA'},
        q{#     $expected->{package} = 'BBB'};
    definition_context_ok(AAA->meta->get_attribute('foo'), {
        context => 'has declaration',
        file    => __FILE__,
        line    => 13,
        package => 'BBB',
        type    => 'class'
    });
    test_test 'fail output as expected';
}
{
    my ($_ok, $_nok) = counters;

    test_out $_nok->('bar can definition_context()');
    test_fail 1;
    definition_context_ok(AAA->meta->get_method('bar'), {
        context => 'has declaration',
        file    => '-',
        line    => 13,
        package => 'AAA',
        type    => 'class'
    });
    test_test 'handles no definition_context()';
}

done_testing;
