our @calls;

{
    package ExtraAssertions;
    BEGIN { $INC{'ExtraAssertions.pm'} = __FILE__ }

    use Test::Mini::Assertions;

    sub import {
        no strict 'refs';
        my $caller = caller;
        *{"$caller\::assert_not_appearing_in_the_standard_assertions"} = sub {
             push @calls, __PACKAGE__ . '::nonstandard';
        };
    }
}

use Test::Mini::Unit::Sugar::Shared with => 'ExtraAssertions';

shared Reusable {
    setup            { push @calls, __PACKAGE__ . '::setup' }
    test something   { push @calls, __PACKAGE__ . '::test_something' }
    test nonstandard { assert_not_appearing_in_the_standard_assertions() }
    teardown         { push @calls, __PACKAGE__ . '::teardown' }
}

{
    package TestPackage;
    Reusable->import();
}

use Test::Mini::Unit;

case t::Test::Mini::Unit::Sugar::Shared::Include {
    setup { @calls = () }

    test packge_now_contains_shared_test_methods {
        assert_can('TestPackage' => 'test_something');
    }

    test methods_make_appropriate_advice_calls {
        TestPackage->test_something();
        assert_equal(\@calls, [
            'Reusable::setup',
            'Reusable::test_something',
            'Reusable::teardown',
        ]);
    }

    test import_argument_with_is_imported {
        TestPackage->test_nonstandard();
        assert_equal(\@calls, [
            'Reusable::setup',
            'ExtraAssertions::nonstandard',
            'Reusable::teardown',
        ]);
    }
}

1;
