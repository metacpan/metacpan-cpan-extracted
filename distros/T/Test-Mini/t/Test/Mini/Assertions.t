package t::Test::Mini::Assertions;
use base 'Test::Mini::TestCase';
use strict;
use warnings;

use Test::Mini::Assertions;

{
    package Mock::Dummy;

    sub new {
        my ($class, %args) = @_;
        return bless \%args, $class;
    }
}

{
    package Mock::Collection;

    sub new {
        my ($class, %args) = @_;
        return bless \%args, $class;
    }

    sub is_empty { shift->{is_empty} }
    sub equals   { shift->{equals}   }
    sub contains { shift->{contains} }
}

{
    package Mock::Bag;
    use base 'Mock::Collection';
}

sub assert_passes (&;$) {
    my ($code, $msg) = @_;
    $msg .= "\n" if $msg;

    my $failures = 0;
    no strict 'refs';
    no warnings 'redefine';

    local *Test::Mini::Assertions::assert = sub ($;$) {
        my ($test, $msg) = @_;
        $failures += !$test;
    };

    $code->();
    assert(!$failures, ($msg || '') . 'test should have passed');
}

sub assert_fails (&;$) {
    my ($code, $msg) = @_;
    $msg .= "\n" if $msg;

    my $failures = 0;
    no strict 'refs';
    no warnings 'redefine';

    local *Test::Mini::Assertions::assert = sub ($;$) {
        my ($test, $msg) = @_;
        $failures += !$test;
    };

    $code->();
    assert($failures, ($msg || '') . 'test should have failed');
}

sub assert_error (&;$) {
    my ($code, $msg) = @_;
    $msg .= "\n" if $msg;
    no strict 'refs';
    no warnings 'redefine';
    local *Test::Mini::Assertions::assert = sub ($;$) {};
    eval { $code->() };
    assert(Exception::Class->caught(), ($msg || '') . "test should have raised error");
}

{
    # #assert is tested in t/01-Test-Mini.t

    sub test_refute {
        assert_passes {
            Test::Mini::Assertions::refute(0);
        } '$false_value';

        assert_passes {
            Test::Mini::Assertions::refute(undef, 'Undef is a falsey value');
        } '$false_value, $msg';

        assert_fails {
            Test::Mini::Assertions::refute(1);
        } '$true_value';

        assert_fails {
            Test::Mini::Assertions::refute('truthy', '"truthy" is truthy');
        } '$true_value, $msg';
    }
}

{
    sub true_block  { 1 }
    sub false_block { 0 }
    sub error_block { die }

    sub test_assert_block {
        assert_passes {
            Test::Mini::Assertions::assert_block { 1 } 'assert_block';
        } '$true_sub, $msg';
        assert_passes {
            Test::Mini::Assertions::assert_block \&true_block, 'assert_block';
        } '\&true_sub, $msg';

        assert_fails {
            Test::Mini::Assertions::assert_block { 0 } 'assert_block';
        } '$false_sub, $msg';
        assert_fails {
            Test::Mini::Assertions::assert_block \&false_block, 'assert_block';
        } '\&false_sub, $msg';

        assert_error {
            Test::Mini::Assertions::assert_block { die } 'assert_block';
        } '$die_sub, $msg';
        assert_error {
            Test::Mini::Assertions::assert_block \&error_block, 'assert_block';
        } '\&error_sub, $msg';
    }

    sub test_refute_block {
        assert_passes {
            Test::Mini::Assertions::refute_block { 0 } 'assert_block';
        } '$true_sub, $msg';
        assert_passes {
            Test::Mini::Assertions::refute_block \&false_block, 'assert_block';
        } '\&true_sub, $msg';

        assert_fails {
            Test::Mini::Assertions::refute_block { 1 } 'assert_block';
        } '$false_sub, $msg';
        assert_fails {
            Test::Mini::Assertions::refute_block \&true_block, 'assert_block';
        } '\&false_sub, $msg';

        assert_error {
            Test::Mini::Assertions::refute_block { die } 'assert_block';
        } '$die_sub, $msg';
        assert_error {
            Test::Mini::Assertions::refute_block \&error_block, 'assert_block';
        } '\&error_sub, $msg';
    }
}

{
    sub test_assert_can {
        assert_passes {
            Test::Mini::Assertions::assert_can(Mock::Bag->new(), 'equals');
        } 'Mock::Bag->can("equals")';

        assert_fails {
            Test::Mini::Assertions::assert_can(Mock::Dummy->new(), 'equals');
        } 'Mock::Dummy->can("equals")';
    }

    sub test_assert_responds_to {
        assert_passes {
            Test::Mini::Assertions::assert_responds_to(Mock::Bag->new(), 'equals');
        } 'Mock::Bag->can("equals")';

        assert_fails {
            Test::Mini::Assertions::assert_responds_to(Mock::Dummy->new(), 'equals');
        } 'Mock::Dummy->can("equals")';
    }

    sub test_refute_can {
        assert_passes {
            Test::Mini::Assertions::refute_can(Mock::Dummy->new(), 'equals');
        } 'Mock::Dummy->can("equals")';

        assert_fails {
            Test::Mini::Assertions::refute_can(Mock::Bag->new(), 'equals');
        } 'Mock::Bag->can("equals")';
    }

    sub test_refute_responds_to {
        assert_passes {
            Test::Mini::Assertions::refute_responds_to(Mock::Dummy->new(), 'equals');
        } 'Mock::Dummy->can("equals")';

        assert_fails {
            Test::Mini::Assertions::refute_responds_to(Mock::Bag->new(), 'equals');
        } 'Mock::Bag->can("equals")';
    }
}

{
    sub test_assert_contains {
        assert_passes {
            Test::Mini::Assertions::assert_contains([qw/ 1 2 3 /], 2);
        } '[qw/ 1 2 3 /] contains 2';
        assert_passes {
            Test::Mini::Assertions::assert_contains('the quick brown fox', 'ick');
        } '"the quick brown fox" contains "ick"';
        assert_passes {
            Test::Mini::Assertions::assert_contains({ key => 'value' }, 'key');
        } '{ key => "value" } contains "key"';
        assert_passes {
            Test::Mini::Assertions::assert_contains({ key => 'value' }, 'value');
        } '{ key => "value" } contains "value"';
        assert_passes {
            Test::Mini::Assertions::assert_contains(Mock::Bag->new(contains => 1), 'x');
        } 'Mock::Bag->new(contains => 1)';

        assert_fails {
            Test::Mini::Assertions::assert_contains([qw/ 1 2 3 /], 0);
        } '[qw/ 1 2 3 /] contains 0';
        assert_fails {
            Test::Mini::Assertions::assert_contains('the quick brown fox', 'selfish');
        } '"this quick brown fox" contains "selfish"';
        assert_fails {
            Test::Mini::Assertions::assert_contains({ key => 'value' }, 'peanuts');
        } '{ key => "value" } contains "peanuts"';
        assert_fails {
            Test::Mini::Assertions::assert_contains(Mock::Bag->new(contains => 0), 'x');
        } 'Mock::Bag->new(contains => 0)';

        assert_error {
            Test::Mini::Assertions::assert_contains(Mock::Dummy->new(), 'x')
        } 'Mock::Dummy->new() contains "x"';
    }

    sub test_assert_includes {
        assert_passes {
            Test::Mini::Assertions::assert_includes([qw/ 1 2 3 /], 2);
        } '[qw/ 1 2 3 /] contains 2';
        assert_passes {
            Test::Mini::Assertions::assert_includes('the quick brown fox', 'ick');
        } '"the quick brown fox" contains "ick"';
        assert_passes {
            Test::Mini::Assertions::assert_includes({ key => 'value' }, 'key');
        } '{ key => "value" } contains "key"';
        assert_passes {
            Test::Mini::Assertions::assert_includes({ key => 'value' }, 'value');
        } '{ key => "value" } contains "value"';
        assert_passes {
            Test::Mini::Assertions::assert_includes(Mock::Bag->new(contains => 1), 'x');
        } 'Mock::Bag->new(contains => 1)';

        assert_fails {
            Test::Mini::Assertions::assert_includes([qw/ 1 2 3 /], 0);
        } '[qw/ 1 2 3 /] contains 0';
        assert_fails {
            Test::Mini::Assertions::assert_includes('the quick brown fox', 'selfish');
        } '"this quick brown fox" contains "selfish"';
        assert_fails {
            Test::Mini::Assertions::assert_includes({ key => 'value' }, 'peanuts');
        } '{ key => "value" } contains "peanuts"';
        assert_fails {
            Test::Mini::Assertions::assert_includes(Mock::Bag->new(contains => 0), 'x');
        } 'Mock::Bag->new(contains => 0)';

        assert_error {
            Test::Mini::Assertions::assert_includes(Mock::Dummy->new(), 'x')
        } 'Mock::Dummy->new() contains "x"';
    }

    sub test_refute_contains {
        assert_passes {
            Test::Mini::Assertions::refute_contains([qw/ 1 2 3 /], 0);
        } '[qw/ 1 2 3 /] contains 0';
        assert_passes {
            Test::Mini::Assertions::refute_contains('the quick brown fox', 'selfish');
        } '"this quick brown fox" contains "selfish"';
        assert_passes {
            Test::Mini::Assertions::refute_contains({ key => 'value' }, 'peanuts');
        } '{ key => "value" } contains "peanuts"';
        assert_passes {
            Test::Mini::Assertions::refute_contains(Mock::Bag->new(contains => 0), 'x');
        } 'Mock::Bag->new(contains => 0)';

        assert_fails {
            Test::Mini::Assertions::refute_contains([qw/ 1 2 3 /], 2);
        } '[qw/ 1 2 3 /] contains 2';
        assert_fails {
            Test::Mini::Assertions::refute_contains('the quick brown fox', 'ick');
        } '"the quick brown fox" contains "ick"';
        assert_fails {
            Test::Mini::Assertions::refute_contains({ key => 'value' }, 'key');
        } '{ key => "value" } contains "key"';
        assert_fails {
            Test::Mini::Assertions::refute_contains({ key => 'value' }, 'value');
        } '{ key => "value" } contains "value"';
        assert_fails {
            Test::Mini::Assertions::refute_contains(Mock::Bag->new(contains => 1), 'x');
        } 'Mock::Bag->new(contains => 1)';

        assert_error {
            Test::Mini::Assertions::refute_contains(Mock::Dummy->new(), 'x')
        } 'Mock::Dummy->new() contains "x"';
    }

    sub test_refute_includes {
        assert_passes {
            Test::Mini::Assertions::refute_includes([qw/ 1 2 3 /], 0);
        } '[qw/ 1 2 3 /] contains 0';
        assert_passes {
            Test::Mini::Assertions::refute_includes('the quick brown fox', 'selfish');
        } '"this quick brown fox" contains "selfish"';
        assert_passes {
            Test::Mini::Assertions::refute_includes({ key => 'value' }, 'peanuts');
        } '{ key => "value" } contains "peanuts"';
        assert_passes {
            Test::Mini::Assertions::refute_includes(Mock::Bag->new(contains => 0), 'x');
        } 'Mock::Bag->new(contains => 0)';

        assert_fails {
            Test::Mini::Assertions::refute_includes([qw/ 1 2 3 /], 2);
        } '[qw/ 1 2 3 /] contains 2';
        assert_fails {
            Test::Mini::Assertions::refute_includes('the quick brown fox', 'ick');
        } '"the quick brown fox" contains "ick"';
        assert_fails {
            Test::Mini::Assertions::refute_includes({ key => 'value' }, 'key');
        } '{ key => "value" } contains "key"';
        assert_fails {
            Test::Mini::Assertions::refute_includes({ key => 'value' }, 'value');
        } '{ key => "value" } contains "value"';
        assert_fails {
            Test::Mini::Assertions::refute_includes(Mock::Bag->new(contains => 1), 'x');
        } 'Mock::Bag->new(contains => 1)';

        assert_error {
            Test::Mini::Assertions::refute_includes(Mock::Dummy->new(), 'x')
        } 'Mock::Dummy->new() contains "x"';
    }
}

{
    sub test_assert_dies {
        assert_passes {
            Test::Mini::Assertions::assert_dies(sub { die 'OMG!' });
        } "sub { die 'OMG!' } dies";
        assert_passes {
            Test::Mini::Assertions::assert_dies(sub { die 'Error on line 26!' }, 'line');
        } "sub { die 'Error on line 26!' } does not die with substring 'line'";

        assert_fails {
            Test::Mini::Assertions::assert_dies(sub { 'Pretty flowers...' });
        } "sub { 'Pretty flowers...' } doesn't die";
        assert_fails {
            Test::Mini::Assertions::assert_dies(sub { 0 });
        } "sub { 0 } doesn't die";
        assert_fails {
            Test::Mini::Assertions::assert_dies(sub { die 'Error on line 26!' }, 'grob');
        } "sub { die 'Error on line 26!' } dies with substring 'grob'";
    }
}

{
    sub test_assert_empty {
        assert_passes {
            Test::Mini::Assertions::assert_empty([]);
        } '[]';
        assert_passes {
            Test::Mini::Assertions::assert_empty({});
        } '{}';
        assert_passes {
            Test::Mini::Assertions::assert_empty('');
        } '""';
        assert_passes {
            Test::Mini::Assertions::assert_empty(Mock::Bag->new(is_empty => 1));
        } 'Mock::Bag->new(is_empty => 1)';

        assert_fails {
            Test::Mini::Assertions::assert_empty([ 0 ]);
        } '[ 0 ]';
        assert_fails {
            Test::Mini::Assertions::assert_empty({ 0 => undef });
        } '{ 0 => undef }';
        assert_fails {
            Test::Mini::Assertions::assert_empty('NONEMPTY');
        } '"NONEMPTY"';
        assert_fails {
            Test::Mini::Assertions::assert_empty(Mock::Bag->new(is_empty => 0));
        } 'Mock::Bag->new(is_empty => 0)';

        assert_error {
            Test::Mini::Assertions::assert_empty(qr//);
        } 'qr//';
        assert_error {
            Test::Mini::Assertions::assert_empty(Mock::Dummy->new());
        } 'Mock::Dummy->new()';
    }

    sub test_refute_empty {
        assert_fails {
            Test::Mini::Assertions::refute_empty([]);
        } '[]';
        assert_fails {
            Test::Mini::Assertions::refute_empty({});
        } '{}';
        assert_fails {
            Test::Mini::Assertions::refute_empty('');
        } '""';
        assert_fails {
            Test::Mini::Assertions::refute_empty(Mock::Bag->new(is_empty => 1));
        } 'Mock::Bag->new(is_empty => 1)';

        assert_passes {
            Test::Mini::Assertions::refute_empty([ 0 ]);
        } '[ 0 ]';
        assert_passes {
            Test::Mini::Assertions::refute_empty({ 0 => undef });
        } '{ 0 => undef }';
        assert_passes {
            Test::Mini::Assertions::refute_empty('NONEMPTY');
        } '"NONEMPTY"';
        assert_passes {
            Test::Mini::Assertions::refute_empty(Mock::Bag->new(is_empty => 0));
        } 'Mock::Bag->new(is_empty => 0)';

        assert_error {
            Test::Mini::Assertions::refute_empty(qr//);
        } 'qr//';
        assert_error {
            Test::Mini::Assertions::refute_empty(Mock::Dummy->new());
        } 'Mock::Dummy->new()';
    }
}

{
    sub test_assert_equal {
        assert_passes {
            Test::Mini::Assertions::assert_equal(3.00, 3);
        } '3.00 equals 3';
        assert_passes {
            Test::Mini::Assertions::assert_equal(lc('FOO'), 'foo');
        } 'lc("FOO") equals "foo"';
        assert_passes {
            Test::Mini::Assertions::assert_equal('INFINITY', 'inf');
        } '"INFINITY" equals "inf"';
        assert_passes {
            Test::Mini::Assertions::assert_equal([ qw/ 1 2 / ], [ 1, 2 ]);
        } '[qw/ 1 2 /] equals [ 1, 2 ]';
        assert_passes {
            Test::Mini::Assertions::assert_equal({ a => 1 }, { 'a', 1 });
        } '{ a => 1} equals { "a", 1 }';
        assert_passes {
            Test::Mini::Assertions::assert_equal(
                { (1..1000) },
                { (501..1000), (1..500) }
            );
        } "key order in hashes mustn't matter";
        assert_passes {
            Test::Mini::Assertions::assert_equal(Mock::Dummy->new(), Mock::Dummy->new());
        } 'Mock::Dummy->new()';
        assert_passes {
            Test::Mini::Assertions::assert_equal(
                bless([1, 2, 3], 'Mock::Dummy'),
                bless([1, 2, 3], 'Mock::Dummy'),
            );
        } 'blessed [1, 2, 3] equals blessed [1, 2, 3]';
        assert_passes {
            Test::Mini::Assertions::assert_equal(anything => Mock::Bag->new(equals => 1));
        } 'Mock::Bag->new(equals => 1)';
        assert_passes {
            Test::Mini::Assertions::assert_equal([]->[0], undef);
        } '[]->[0] equals undef';
        assert_passes {
            my $c = {};
            $c->{loop} = $c;
            Test::Mini::Assertions::assert_equal($c, $c);
        } '<circular reference> equals <circular reference>';
        assert_passes {
            my $thing = "THING";
            Test::Mini::Assertions::assert_equal(\\\$thing, \\\$thing);
        } '<deep reference> equals <deep reference>';
        assert_passes {
            my $c = {};
            $c->{loop} = $c;

            Test::Mini::Assertions::assert_equal(
                [ { a => undef, b => Mock::Bag->new()           , c => \$c }, 'abcde' ],
                [ { a => undef, b => Mock::Bag->new(equals => 1), c => \$c }, 'abcde' ],
            );
        } '<complex nested object> equals <complex nested object>';

        assert_fails {
            Test::Mini::Assertions::assert_equal(3.001, 3);
        } '3.001 equals 3';
        assert_fails {
            Test::Mini::Assertions::assert_equal(lc('FO0'), 'foo');
        } 'lc("FO0") equals "foo"';
        assert_fails {
            Test::Mini::Assertions::assert_equal('INFINITY', 'information');
        } '"INFINITY" equals "information"';
        assert_fails {
            Test::Mini::Assertions::assert_equal([ qw/ 1 b / ], [ 1, 2 ]);
        } '[ qw/ 1 b / ] equals [ 1, 2 ]';
        assert_fails {
            Test::Mini::Assertions::assert_equal({ 'a', 2 }, { a => 1 });
        } '{ "a", 2 } equals { a => 1 }';
        assert_fails {
            Test::Mini::Assertions::assert_equal(nothing => Mock::Bag->new(equals => 0));
        } 'Mock::Bag->new(equals => 0)';
        assert_fails {
            my $dummy = Mock::Dummy->new();
            $dummy->{key} = "value";
            Test::Mini::Assertions::assert_equal($dummy, Mock::Dummy->new());
        } 'Mock::Dummy->new()';
        assert_fails {
            Test::Mini::Assertions::assert_equal(
                bless([1, 2, 3], 'Mock::Dummy'),
                bless([1, 2, 4], 'Mock::Dummy'),
            );
        } 'blessed [1, 2, 3] equals blessed [1, 2, 4]';
        assert_fails {
            Test::Mini::Assertions::assert_equal(
                bless([1, 2, 3], 'X'),
                bless([1, 2, 3], 'Y'),
            );
        } 'Dummy [1, 2, 3] equals Bag [1, 2, 4]';
        assert_fails {
            Test::Mini::Assertions::assert_equal(0, undef);
        } '0 equals undef';
        assert_fails {
            my $c = {};
            $c->{loop} = $c;

            Test::Mini::Assertions::assert_equal(
                [ { a => undef, b => Mock::Bag->new()           , c => $c }, 'abcde' ],
                [ { a => undef, b => Mock::Bag->new(equals => 0), c => $c }, 'abcde' ],
            );
        } '<complex nested object> equals <different complex nested object>';
        assert_fails {
            Test::Mini::Assertions::assert_equal(
                [ 1, 'abcde',         ],
                [ 1, 'abcde', 3.14159 ],
            );
        } '[ 1, "abcde" ] equals [ 1, "abcde", 3.14159 ]';
        assert_fails {
            my $thing = "THING";
            Test::Mini::Assertions::assert_equal(\\$thing, \\\$thing);
        } '<deep reference> equals <deeper reference>';
    }

    sub test_assert_eq {
        assert_passes {
            Test::Mini::Assertions::assert_eq(3.00, 3);
        } '3.00 equals 3';
        assert_passes {
            Test::Mini::Assertions::assert_eq(lc('FOO'), 'foo');
        } 'lc("FOO") equals "foo"';
        assert_passes {
            Test::Mini::Assertions::assert_eq('INFINITY', 'inf');
        } '"INFINITY" equals "inf"';
        assert_passes {
            Test::Mini::Assertions::assert_eq([ qw/ 1 2 / ], [ 1, 2 ]);
        } '[qw/ 1 2 /] equals [ 1, 2 ]';
        assert_passes {
            Test::Mini::Assertions::assert_eq({ a => 1 }, { 'a', 1 });
        } '{ a => 1} equals { "a", 1 }';
        assert_passes {
            Test::Mini::Assertions::assert_eq(Mock::Dummy->new(), Mock::Dummy->new());
        } 'Mock::Dummy->new()';
        assert_passes {
            Test::Mini::Assertions::assert_eq(
                bless([1, 2, 3], 'Mock::Dummy'),
                bless([1, 2, 3], 'Mock::Dummy'),
            );
        } 'blessed [1, 2, 3] equals blessed [1, 2, 3]';
        assert_passes {
            Test::Mini::Assertions::assert_eq(anything => Mock::Bag->new(equals => 1));
        } 'Mock::Bag->new(equals => 1)';
        assert_passes {
            Test::Mini::Assertions::assert_eq([]->[0], undef);
        } '[]->[0] equals undef';
        assert_passes {
            my $c = {};
            $c->{loop} = $c;
            Test::Mini::Assertions::assert_eq($c, $c);
        } '<circular reference> equals <circular reference>';
        assert_passes {
            my $thing = "THING";
            Test::Mini::Assertions::assert_eq(\\\$thing, \\\$thing);
        } '<deep reference> equals <deep reference>';
        assert_passes {
            my $c = {};
            $c->{loop} = $c;

            Test::Mini::Assertions::assert_eq(
                [ { a => undef, b => Mock::Bag->new()           , c => \$c }, 'abcde' ],
                [ { a => undef, b => Mock::Bag->new(equals => 1), c => \$c }, 'abcde' ],
            );
        } '<complex nested object> equals <complex nested object>';

        assert_fails {
            Test::Mini::Assertions::assert_eq(3.001, 3);
        } '3.001 equals 3';
        assert_fails {
            Test::Mini::Assertions::assert_eq(lc('FO0'), 'foo');
        } 'lc("FO0") equals "foo"';
        assert_fails {
            Test::Mini::Assertions::assert_eq('INFINITY', 'information');
        } '"INFINITY" equals "information"';
        assert_fails {
            Test::Mini::Assertions::assert_eq([ qw/ 1 b / ], [ 1, 2 ]);
        } '[ qw/ 1 b / ] equals [ 1, 2 ]';
        assert_fails {
            Test::Mini::Assertions::assert_eq({ 'a', 2 }, { a => 1 });
        } '{ "a", 2 } equals { a => 1 }';
        assert_fails {
            Test::Mini::Assertions::assert_eq(nothing => Mock::Bag->new(equals => 0));
        } 'Mock::Bag->new(equals => 0)';
        assert_fails {
            my $dummy = Mock::Dummy->new();
            $dummy->{key} = "value";
            Test::Mini::Assertions::assert_eq($dummy, Mock::Dummy->new());
        } 'Mock::Dummy->new()';
        assert_fails {
            Test::Mini::Assertions::assert_eq(
                bless([1, 2, 3], 'Mock::Dummy'),
                bless([1, 2, 4], 'Mock::Dummy'),
            );
        } 'blessed [1, 2, 3] equals blessed [1, 2, 4]';
        assert_fails {
            Test::Mini::Assertions::assert_eq(
                bless([1, 2, 3], 'X'),
                bless([1, 2, 3], 'Y'),
            );
        } 'Dummy [1, 2, 3] equals Bag [1, 2, 4]';
        assert_fails {
            Test::Mini::Assertions::assert_eq(0, undef);
        } '0 equals undef';
        assert_fails {
            my $c = {};
            $c->{loop} = $c;

            Test::Mini::Assertions::assert_eq(
                [ { a => undef, b => Mock::Bag->new()           , c => $c }, 'abcde' ],
                [ { a => undef, b => Mock::Bag->new(equals => 0), c => $c }, 'abcde' ],
            );
        } '<complex nested object> equals <different complex nested object>';
        assert_fails {
            Test::Mini::Assertions::assert_eq(
                [ 1, 'abcde',         ],
                [ 1, 'abcde', 3.14159 ],
            );
        } '[ 1, "abcde" ] equals [ 1, "abcde", 3.14159 ]';
        assert_fails {
            my $thing = "THING";
            Test::Mini::Assertions::assert_eq(\\$thing, \\\$thing);
        } '<deep reference> equals <deeper reference>';
    }

    sub test_refute_equal {
        assert_passes {
            Test::Mini::Assertions::refute_equal(3.001, 3);
        } '3.001 equals 3';
        assert_passes {
            Test::Mini::Assertions::refute_equal(lc('FO0'), 'foo');
        } 'lc("FO0") equals "foo"';
        assert_passes {
            Test::Mini::Assertions::refute_equal('INFINITY', 'information');
        } '"INFINITY" equals "information"';
        assert_passes {
            Test::Mini::Assertions::refute_equal([ qw/ 1 b / ], [ 1, 2 ]);
        } '[ qw/ 1 b / ] equals [ 1, 2 ]';
        assert_passes {
            Test::Mini::Assertions::refute_equal({ 'a', 2 }, { a => 1 });
        } '{ "a", 2 } equals { a => 1 }';
        assert_passes {
            Test::Mini::Assertions::refute_equal(nothing => Mock::Bag->new(equals => 0));
        } 'Mock::Bag->new(equals => 0)';
        assert_passes {
            my $dummy = Mock::Dummy->new();
            $dummy->{key} = "value";
            Test::Mini::Assertions::refute_equal($dummy, Mock::Dummy->new());
        } 'Mock::Dummy->new()';
        assert_passes {
            Test::Mini::Assertions::refute_equal(
                bless([1, 2, 3], 'Mock::Dummy'),
                bless([1, 2, 4], 'Mock::Dummy'),
            );
        } 'blessed [1, 2, 3] equals blessed [1, 2, 4]';
        assert_passes {
            Test::Mini::Assertions::refute_equal(
                bless([1, 2, 3], 'X'),
                bless([1, 2, 3], 'Y'),
            );
        } 'Dummy [1, 2, 3] equals Bag [1, 2, 4]';
        assert_passes {
            Test::Mini::Assertions::refute_equal(0, undef);
        } '0 equals undef';
        assert_passes {
            my $c = {};
            $c->{loop} = $c;

            Test::Mini::Assertions::refute_equal(
                [ { a => undef, b => Mock::Bag->new()           , c => $c }, 'abcde' ],
                [ { a => undef, b => Mock::Bag->new(equals => 0), c => $c }, 'abcde' ],
            );
        } '<complex nested object> equals <different complex nested object>';
        assert_passes {
            Test::Mini::Assertions::refute_equal(
                [ 1, 'abcde',         ],
                [ 1, 'abcde', 3.14159 ],
            );
        } '[ 1, "abcde" ] equals [ 1, "abcde", 3.14159 ]';
        assert_passes {
            my $thing = "THING";
            Test::Mini::Assertions::refute_equal(\\$thing, \\\$thing);
        } '<deep reference> equals <deeper reference>';

        assert_fails {
            Test::Mini::Assertions::refute_equal(3.00, 3);
        } '3.00 equals 3';
        assert_fails {
            Test::Mini::Assertions::refute_equal(lc('FOO'), 'foo');
        } 'lc("FOO") equals "foo"';
        assert_fails {
            Test::Mini::Assertions::refute_equal('INFINITY', 'inf');
        } '"INFINITY" equals "inf"';
        assert_fails {
            Test::Mini::Assertions::refute_equal([ qw/ 1 2 / ], [ 1, 2 ]);
        } '[qw/ 1 2 /] equals [ 1, 2 ]';
        assert_fails {
            Test::Mini::Assertions::refute_equal({ a => 1 }, { 'a', 1 });
        } '{ a => 1} equals { "a", 1 }';
        assert_fails {
            Test::Mini::Assertions::refute_equal(Mock::Dummy->new(), Mock::Dummy->new());
        } 'Mock::Dummy->new()';
        assert_fails {
            Test::Mini::Assertions::refute_equal(
                bless([1, 2, 3], 'Mock::Dummy'),
                bless([1, 2, 3], 'Mock::Dummy'),
            );
        } 'blessed [1, 2, 3] equals blessed [1, 2, 3]';
        assert_fails {
            Test::Mini::Assertions::refute_equal(anything => Mock::Bag->new(equals => 1));
        } 'Mock::Bag->new(equals => 1)';
        assert_fails {
            Test::Mini::Assertions::refute_equal([]->[0], undef);
        } '[]->[0] equals undef';
        assert_fails {
            my $c = {};
            $c->{loop} = $c;
            Test::Mini::Assertions::refute_equal($c, $c);
        } '<circular reference> equals <circular reference>';
        assert_fails {
            my $thing = "THING";
            Test::Mini::Assertions::refute_equal(\\\$thing, \\\$thing);
        } '<deep reference> equals <deep reference>';
        assert_fails {
            my $c = {};
            $c->{loop} = $c;

            Test::Mini::Assertions::refute_equal(
                [ { a => undef, b => Mock::Bag->new()           , c => \$c }, 'abcde' ],
                [ { a => undef, b => Mock::Bag->new(equals => 1), c => \$c }, 'abcde' ],
            );
        } '<complex nested object> equals <complex nested object>';
    }

    sub test_refute_eq {
        assert_passes {
            Test::Mini::Assertions::refute_eq(3.001, 3);
        } '3.001 equals 3';
        assert_passes {
            Test::Mini::Assertions::refute_eq(lc('FO0'), 'foo');
        } 'lc("FO0") equals "foo"';
        assert_passes {
            Test::Mini::Assertions::refute_eq('INFINITY', 'information');
        } '"INFINITY" equals "information"';
        assert_passes {
            Test::Mini::Assertions::refute_eq([ qw/ 1 b / ], [ 1, 2 ]);
        } '[ qw/ 1 b / ] equals [ 1, 2 ]';
        assert_passes {
            Test::Mini::Assertions::refute_eq({ 'a', 2 }, { a => 1 });
        } '{ "a", 2 } equals { a => 1 }';
        assert_passes {
            Test::Mini::Assertions::refute_eq(nothing => Mock::Bag->new(equals => 0));
        } 'Mock::Bag->new(equals => 0)';
        assert_passes {
            my $dummy = Mock::Dummy->new();
            $dummy->{key} = "value";
            Test::Mini::Assertions::refute_eq($dummy, Mock::Dummy->new());
        } 'Mock::Dummy->new()';
        assert_passes {
            Test::Mini::Assertions::refute_eq(
                bless([1, 2, 3], 'Mock::Dummy'),
                bless([1, 2, 4], 'Mock::Dummy'),
            );
        } 'blessed [1, 2, 3] equals blessed [1, 2, 4]';
        assert_passes {
            Test::Mini::Assertions::refute_eq(
                bless([1, 2, 3], 'X'),
                bless([1, 2, 3], 'Y'),
            );
        } 'Dummy [1, 2, 3] equals Bag [1, 2, 4]';
        assert_passes {
            Test::Mini::Assertions::refute_eq(0, undef);
        } '0 equals undef';
        assert_passes {
            my $c = {};
            $c->{loop} = $c;

            Test::Mini::Assertions::refute_eq(
                [ { a => undef, b => Mock::Bag->new()           , c => $c }, 'abcde' ],
                [ { a => undef, b => Mock::Bag->new(equals => 0), c => $c }, 'abcde' ],
            );
        } '<complex nested object> equals <different complex nested object>';
        assert_passes {
            Test::Mini::Assertions::refute_eq(
                [ 1, 'abcde',         ],
                [ 1, 'abcde', 3.14159 ],
            );
        } '[ 1, "abcde" ] equals [ 1, "abcde", 3.14159 ]';
        assert_passes {
            my $thing = "THING";
            Test::Mini::Assertions::refute_eq(\\$thing, \\\$thing);
        } '<deep reference> equals <deeper reference>';

        assert_fails {
            Test::Mini::Assertions::refute_eq(3.00, 3);
        } '3.00 equals 3';
        assert_fails {
            Test::Mini::Assertions::refute_eq(lc('FOO'), 'foo');
        } 'lc("FOO") equals "foo"';
        assert_fails {
            Test::Mini::Assertions::refute_eq('INFINITY', 'inf');
        } '"INFINITY" equals "inf"';
        assert_fails {
            Test::Mini::Assertions::refute_eq([ qw/ 1 2 / ], [ 1, 2 ]);
        } '[qw/ 1 2 /] equals [ 1, 2 ]';
        assert_fails {
            Test::Mini::Assertions::refute_eq({ a => 1 }, { 'a', 1 });
        } '{ a => 1} equals { "a", 1 }';
        assert_fails {
            Test::Mini::Assertions::refute_eq(Mock::Dummy->new(), Mock::Dummy->new());
        } 'Mock::Dummy->new()';
        assert_fails {
            Test::Mini::Assertions::refute_eq(
                bless([1, 2, 3], 'Mock::Dummy'),
                bless([1, 2, 3], 'Mock::Dummy'),
            );
        } 'blessed [1, 2, 3] equals blessed [1, 2, 3]';
        assert_fails {
            Test::Mini::Assertions::refute_eq(anything => Mock::Bag->new(equals => 1));
        } 'Mock::Bag->new(equals => 1)';
        assert_fails {
            Test::Mini::Assertions::refute_eq([]->[0], undef);
        } '[]->[0] equals undef';
        assert_fails {
            my $c = {};
            $c->{loop} = $c;
            Test::Mini::Assertions::refute_eq($c, $c);
        } '<circular reference> equals <circular reference>';
        assert_fails {
            my $thing = "THING";
            Test::Mini::Assertions::refute_eq(\\\$thing, \\\$thing);
        } '<deep reference> equals <deep reference>';
        assert_fails {
            my $c = {};
            $c->{loop} = $c;

            Test::Mini::Assertions::refute_eq(
                [ { a => undef, b => Mock::Bag->new()           , c => \$c }, 'abcde' ],
                [ { a => undef, b => Mock::Bag->new(equals => 1), c => \$c }, 'abcde' ],
            );
        } '<complex nested object> equals <complex nested object>';
    }
}

{
    sub test_assert_in_delta {
        assert_passes {
            Test::Mini::Assertions::assert_in_delta(-1, 1, 2);
        } '(-1) - 1 <= 2';
        assert_passes {
            Test::Mini::Assertions::assert_in_delta(1, -1, 2);
        } '1 - (-1) <= 2';

        assert_fails {
            Test::Mini::Assertions::assert_in_delta(-1, 1, 1.8);
        } '(-1) - 1 <= 1.8';
    }

    sub test_refute_in_delta {
        assert_passes {
            Test::Mini::Assertions::refute_in_delta(-1, 1, 1.8);
        } '(-1) - 1 > 1.8';

        assert_fails {
            Test::Mini::Assertions::refute_in_delta(-1, 1, 2);
        } '(-1) - 1 > 2';
        assert_fails {
            Test::Mini::Assertions::refute_in_delta(1, -1, 2);
        } '1 - (-1) > 2';
    }
}

{
    sub test_assert_in_epsilon {
        assert_passes {
            Test::Mini::Assertions::assert_in_epsilon(9999, 10000);
        } '9999 is within 0.1% of 10000';

        assert_fails {
            Test::Mini::Assertions::assert_in_epsilon(9999, 10000, 0.0001);
        } '9999 is within 0.01% of 10000';
    }

    sub test_refute_in_epsilon {
        assert_passes {
            Test::Mini::Assertions::refute_in_epsilon(9999, 10000, 0.0001);
        } '9999 is within 0.01% of 10000';

        assert_fails {
            Test::Mini::Assertions::refute_in_epsilon(9999, 10000);
        } '9999 is within 0.1% of 10000';
    }
}

{
    sub test_assert_instance_of {
        assert_passes {
            Test::Mini::Assertions::assert_instance_of(Mock::Bag->new(), 'Mock::Bag');
        } 'Mock::Bag->new() is an instance of Mock::Bag';

        assert_fails {
            Test::Mini::Assertions::assert_instance_of(Mock::Bag->new(), 'Mock::Collection');
        } 'Mock::Bag->new() is an instance of Mock::Collection';
    }
}

{
    sub test_assert_is_a {
        assert_passes {
            Test::Mini::Assertions::assert_is_a('Mock::Bag', 'Mock::Bag');
        } 'Mock::Bag is a Mock::Bag';
        assert_passes {
            Test::Mini::Assertions::assert_is_a('Mock::Bag', 'Mock::Collection');
        } 'Mock::Bag is a Mock::Collection';
        assert_passes {
            Test::Mini::Assertions::assert_is_a(Mock::Bag->new(), 'Mock::Bag');
        } 'Mock::Bag->new() is a Mock::Bag';
        assert_passes {
            Test::Mini::Assertions::assert_is_a(Mock::Bag->new(), 'Mock::Collection');
        } 'Mock::Bag->new() is a Mock::Collection';

        assert_fails {
            Test::Mini::Assertions::assert_is_a(Mock::Bag->new(), 'Mock::Enumerable');
        } 'Mock::Bag->new() is a Mock::Enumerable';
        assert_fails {
            Test::Mini::Assertions::assert_is_a(Mock::Bag->new(), 'Mock::Dummy');
        } 'Mock::Bag->new() is a Mock::Dummy';
    }

    sub test_assert_isa {
        assert_passes {
            Test::Mini::Assertions::assert_isa('Mock::Bag', 'Mock::Bag');
        } 'Mock::Bag is a Mock::Bag';
        assert_passes {
            Test::Mini::Assertions::assert_isa('Mock::Bag', 'Mock::Collection');
        } 'Mock::Bag is a Mock::Collection';
        assert_passes {
            Test::Mini::Assertions::assert_isa(Mock::Bag->new(), 'Mock::Bag');
        } 'Mock::Bag->new() is a Mock::Bag';
        assert_passes {
            Test::Mini::Assertions::assert_isa(Mock::Bag->new(), 'Mock::Collection');
        } 'Mock::Bag->new() is a Mock::Collection';

        assert_fails {
            Test::Mini::Assertions::assert_isa(Mock::Bag->new(), 'Mock::Enumerable');
        } 'Mock::Bag->new() is a Mock::Enumerable';
        assert_fails {
            Test::Mini::Assertions::assert_isa(Mock::Bag->new(), 'Mock::Dummy');
        } 'Mock::Bag->new() is a Mock::Dummy';
    }
}

{
    sub test_assert_match {
        assert_passes {
            Test::Mini::Assertions::assert_match('Four score and seven years ago...', qr/score/);
        } '/score/ matches "Four score and seven years ago..."';

        assert_fails {
            Test::Mini::Assertions::assert_match('Four score and seven years ago...', qr/awesome/);
        } '/awesome/ matches "Four score and seven years ago..."';
    }

    sub test_refute_match {
        assert_passes {
            Test::Mini::Assertions::refute_match('Four score and seven years ago...', qr/awesome/);
        } '/awesome/ matches "Four score and seven years ago..."';

        assert_fails {
            Test::Mini::Assertions::refute_match('Four score and seven years ago...', qr/score/);
        } '/score/ matches "Four score and seven years ago..."';
    }
}

{
    sub test_assert_undef {
        assert_passes {
            Test::Mini::Assertions::assert_undef({}->{key});
        } '{}->{key} is undefined';
        assert_passes {
            Test::Mini::Assertions::assert_undef([]->[0]);
        } '[]->[0] is undefined';
        assert_passes {
            Test::Mini::Assertions::assert_undef(undef);
        } 'undef is undefined';

        assert_fails {
            Test::Mini::Assertions::assert_undef(0);
        } '0 is undefined';
        assert_fails {
            Test::Mini::Assertions::assert_undef('');
        } '"" is undefined';
        assert_fails {
            Test::Mini::Assertions::assert_undef('NaN');
        } 'NaN is undefined';
    }

    sub test_refute_defined {
        assert_passes {
            Test::Mini::Assertions::refute_defined({}->{key});
        } '{}->{key} is undefined';
        assert_passes {
            Test::Mini::Assertions::refute_defined([]->[0]);
        } '[]->[0] is undefined';
        assert_passes {
            Test::Mini::Assertions::refute_defined(undef);
        } 'undef is undefined';

        assert_fails {
            Test::Mini::Assertions::refute_defined(0);
        } '0 is undefined';
        assert_fails {
            Test::Mini::Assertions::refute_defined('');
        } '"" is undefined';
        assert_fails {
            Test::Mini::Assertions::refute_defined('NaN');
        } 'NaN is undefined';
    }

    sub test_refute_undef {
        assert_passes {
            Test::Mini::Assertions::refute_undef(0);
        } '0 is undefined';
        assert_passes {
            Test::Mini::Assertions::refute_undef('');
        } '"" is undefined';
        assert_passes {
            Test::Mini::Assertions::refute_undef('NaN');
        } 'NaN is undefined';

        assert_fails {
            Test::Mini::Assertions::refute_undef({}->{key});
        } '{}->{key} is undefined';
        assert_fails {
            Test::Mini::Assertions::refute_undef([]->[0]);
        } '[]->[0] is undefined';
        assert_fails {
            Test::Mini::Assertions::refute_undef(undef);
        } 'undef is undefined';
    }

    sub test_assert_defined {
        assert_passes {
            Test::Mini::Assertions::assert_defined(0);
        } '0 is undefined';
        assert_passes {
            Test::Mini::Assertions::assert_defined('');
        } '"" is undefined';
        assert_passes {
            Test::Mini::Assertions::assert_defined('NaN');
        } 'NaN is undefined';

        assert_fails {
            Test::Mini::Assertions::assert_defined({}->{key});
        } '{}->{key} is undefined';
        assert_fails {
            Test::Mini::Assertions::assert_defined([]->[0]);
        } '[]->[0] is undefined';
        assert_fails {
            Test::Mini::Assertions::assert_defined(undef);
        } 'undef is undefined';
    }
}

1;
