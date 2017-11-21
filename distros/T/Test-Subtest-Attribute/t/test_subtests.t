#!/usr/bin/env perl

use strict;
use warnings;

use English qw( -no_match_vars $EVAL_ERROR );
use TAP::Parser qw();
use Test::More;

my $module_name = 'Test::Subtest::Attribute';
my @coverage_exceptions = qw( run );


if ( $ENV{AUTHOR_TESTING} ) {
    eval {
        require Test::TestCoverage;
        1;
    } or die "Can't run author tests. Test::TestCoverage couldn't load. Error: '$EVAL_ERROR'\n";

    Test::TestCoverage::test_coverage( $module_name );
    Test::TestCoverage::test_coverage_except( $module_name, @coverage_exceptions );
}


subtest 'perl ver' => sub {
    ok( $^V, "Got a valid perl version: $^V" )
        or die;

    return;
};

subtest 'use' => sub {
    use_ok( $module_name, 'subtests' );

    return;
};

subtest 'Saw expected TAP from fixture: simple_subtest_script.pl' => sub {
    return script_ok(
        't/fixtures/bin/simple_subtest_script.pl',
        [
            '# Subtest: foo',
            'ok 1 - Dummy subtest foo',
            '1..1',
            'ok 1 - foo',
            '# Subtest: name for bar',
            'ok 1 - Dummy subtest bar',
            '1..1',
            'ok 2 - name for bar',
            '1..2',
        ]
    );
};

subtest 'Saw expected TAP from fixture: no_imports.pl' => sub {
    return script_ok(
        't/fixtures/bin/no_imports.pl',
        [
            '# Subtest: foo',
            'ok 1 - Dummy subtest foo',
            '1..1',
            'ok 1 - foo',
            '# Subtest: name for bar',
            'ok 1 - Dummy subtest bar',
            '1..1',
            'ok 2 - name for bar',
            '1..2',
        ]
    );
};

subtest 'Saw expected TAP from fixture: test_class.pl' => sub {
    return script_ok(
        't/fixtures/bin/test_class.pl',
        [
            '# Subtest: require_ok',
            'ok 1 - require Test::Subtest::Attribute;',
            '1..1',
            'ok 1 - require_ok',
            '# Subtest: foo',
            'ok 1 - Dummy subtest foo',
            '1..1',
            'ok 2 - foo',
            '# Subtest: name for bar',
            'ok 1 - Dummy subtest bar',
            '1..1',
            'ok 3 - name for bar',
            '1..3',
        ]
    );
};

subtest 'append(), prepend(), remove()' => sub {
    my @tests_before = subtests()->get_all();
    is( scalar @tests_before, 0, 'Initially have no subtests defined' );

    my $foo_coderef = sub {
        ok( 1, 'Dummy subtest foo' );
        return 1;
    };
    my $bar_coderef = sub {
        ok( 1, 'Dummy subtest bar' );
        return 1;
    };

    ok( subtests()->append( name => 'foo', coderef => $foo_coderef ), 'append() returned true' );
    my @tests_after_append = subtests()->get_all();
    is( scalar @tests_after_append, 1, 'Now have one subtest queued up' );
    is( $tests_after_append[0]->{name}, 'foo', 'First subtest after append has a name of foo' );
    is( $tests_after_append[0]->{coderef}, $foo_coderef, 'First subtest after append has expected coderef' );

    ok( subtests()->prepend( name => 'bar', coderef => $bar_coderef ), 'prepend() returned true' );
    my @tests_after_prepend = subtests()->get_all();
    is( scalar @tests_after_prepend, 2, 'Now have two subtests queued up' );
    is( $tests_after_prepend[0]->{name}, 'bar', 'First subtest after prepend has a name of bar' );
    is( $tests_after_prepend[0]->{coderef}, $bar_coderef, 'First subtest after prepend has expected coderef' );
    is( $tests_after_prepend[1]->{name}, 'foo', 'Second subtest after prepend has a name of foo' );
    is( $tests_after_prepend[1]->{coderef}, $foo_coderef, 'Second subtest after prepend has expected coderef' );

    ok( subtests()->remove( 'foo' ), q{remove('foo') returned true value} );
    my @tests_after_remove_foo = subtests()->get_all();
    is( scalar @tests_after_remove_foo, 1, 'Back to only 1 subtest queued up' );
    is( $tests_after_remove_foo[0]->{name}, 'bar', 'First subtest after remove has a name of bar' );
    is( $tests_after_remove_foo[0]->{coderef}, $bar_coderef, 'First subtest after remove has expected coderef' );

    ok( subtests()->remove( $bar_coderef ), q{remove(<bar_coderef>) returned true value} );
    my @tests_after_remove_bar = subtests()->get_all();
    is( scalar @tests_after_remove_bar, 0, 'Back to no subtests defined.' );

    return;
};

if ( $ENV{AUTHOR_TESTING} ) {
    subtest 'test coverage' => sub {
        return Test::TestCoverage::ok_test_coverage( $module_name );
    };
}

sub script_ok {
    my ( $script, $expected ) = @_;

    return if ! $script;
    $expected ||= [];

    my $parser = TAP::Parser->new( { source => $script } );
    if ( ! $parser ) {
        fail( "Couldn't create TAP::Parser for test script: $script" );
        return;
    }

    my $line_num = 0;
    my $all_ok   = 1;
    while ( my $result = $parser->next() ) {
        $line_num++;

        my $actual   = defined $result ? $result->as_string() : undef;
        my $expected = $expected->[ $line_num - 1 ];
        if ( ! $expected ) {
            fail( "Saw unexpected line of output: $actual" );
            $all_ok = 0;
            last;
        }

        $all_ok &= like( $actual, qr/\Q$expected\E/msx, "Line $line_num of test output has expected content: $expected" );
    }

    return $all_ok;
}

done_testing();
