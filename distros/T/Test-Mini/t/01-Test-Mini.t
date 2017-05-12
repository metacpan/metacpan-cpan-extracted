use Test::More tests => 15;
use strict;
use warnings;

require Test::Mini::Assertions;
require Test::Mini::Runner;

my $END;

{ package Mock::TestCase }

sub run_tests { Test::Mini::Runner->new(logger => 'Test::Mini::Logger')->run() }

{
    note 'Test: when run with no test modules, exits with 255';

    is run_tests(), 255, 'Exit code';
}

{
    note 'Test: when run with an empty test module, exits with 127';

    @Mock::TestCase::ISA = qw/ Test::Mini::TestCase /;

    is run_tests(), 127, 'Exit code';
}

{
    note 'Test: when run with an empty (no assertions) test, exits with 1';

    my $tests_called = 0;

    {
        no strict 'refs';
        no warnings 'redefine';
        *{'Mock::TestCase::test_method'} = sub { $tests_called++ };
    }

    is run_tests(), 1, 'Exit code';
    is $tests_called, 1, 'test_method called';
}

{
    note 'Test: when run with an erroneous test, exits with 1';

    my $tests_called = 0;

    {
        no strict 'refs';
        no warnings 'redefine';
        *{'Mock::TestCase::test_method'} = sub {
            $tests_called++;
            die 'oops';
        };
    }

    is run_tests(), 1, 'Exit code';
    is $tests_called, 1, 'test_method called';
}

{
    note 'Test: when run with an failing test, exits with 1';

    my $tests_called = 0;

    {
        no strict 'refs';
        no warnings 'redefine';
        *{'Mock::TestCase::test_method'} = sub {
            $tests_called++;
            Test::Mini::Assertions::assert(0);
        };
    }

    is run_tests(), 1, 'Exit code';
    is $tests_called, 1, 'test_method called';
}

{
    note 'Test: when run with a passing test, exits with 0';

    my $tests_called = 0;

    {
        no strict 'refs';
        no warnings 'redefine';
        *{'Mock::TestCase::test_method'} = sub {
            $tests_called++;
            Test::Mini::Assertions::assert(1);
        };
    }

    is run_tests(), 0, 'Exit code';
    is $tests_called, 1, 'test_method called';
}

{
    note 'Test: when run with a skipped test, exits with 0';

    my $tests_called = 0;

    {
        no strict 'refs';
        no warnings 'redefine';
        *{'Mock::TestCase::test_method'} = sub {
            $tests_called++;
            Test::Mini::Assertions::skip();
            $tests_called++;
        };
    }

    is run_tests(), 0, 'Exit code';
    is $tests_called, 1, 'test_method called';
}

{
    note 'Test: installed END block exits with result from MT::U::Runner#run';

    {
        no strict 'refs';
        no warnings 'redefine';
        *{'Test::Mini::Runner::run'} = sub { return 42; };
    }

    $END->();
    is $?, 42, 'Checking $?';
}

BEGIN {
    use_ok 'Test::Mini';
    use List::Util qw/ first /;
    use B qw/ end_av /;

    my $index = first {
        my $cv = end_av->ARRAYelt($_);
        ref $cv eq 'B::CV' && $cv->STASH->NAME eq 'Test::Mini';
    } 0..(end_av->MAX);

    ok defined($index), 'END hook installed';

    $END = end_av->ARRAYelt($index)->object_2svref();
    splice(@{ end_av()->object_2svref() }, $index, 1);
}

END {
    # Cleanup, so that others aren't polluted if run in the same process.
    @Mock::TestCase::ISA = ();
}
