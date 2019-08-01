#!perl

use 5.006;
use strict;
use warnings;

use Test::Builder::Tester;
use Test::Fatal;
use Test::More 0.88;

use Class::Tiny 1;
use Role::Tiny::With;

with 'XT::Files::Role::Logger';

delete $ENV{XT_FILES_DEBUG};

my $prefix = 'PrEfIx';

sub log_prefix {
    return $prefix;
}

note(q{log('hello world')});
{
    my $obj = main->new;

    test_out("# [$prefix] hello world");
    my $result = $obj->log('hello world');
    test_test('log output');
    is( $result, undef, 'log() returns undef' );

    test_out("# [$prefix] hello\n# world");
    $result = $obj->log("hello\nworld");
    test_test('log output');
    is( $result, undef, 'log() returns undef' );
}

note(q{log_debug('hello world')});
{
    my $obj = main->new;

    # no debug output
    test_out();
    my $result = $obj->log_debug('hello world');
    test_test('log_debug output');
    is( $result, undef, 'log_debug() returns undef' );

    # with debug output
    local $ENV{XT_FILES_DEBUG} = 1;

    test_out("# [$prefix] hello world");
    $result = $obj->log_debug('hello world');
    test_test('log_debug output');
    is( $result, undef, 'log_debug() returns undef' );

}

note(q{log_fatal('hello world')});
{
    my $obj = main->new;

    test_out("# [$prefix] hello world");
    my $output = exception { $obj->log_fatal('hello world'); };
    test_test('log_fatal output');

    my $expected_die = "[$prefix] hello world at ";
    like( $output, qr{\Q$expected_die\E}, '... and expected die message' );

}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
