#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Test::Pod::Links;

main();

sub main {
    my $class = 'Test::Pod::Links';

    my $obj = $class->new();

    ok( exists $obj->{_ignore_regex}, '_ignore_regex attribute exists' );
    is( $obj->{_ignore_regex}, undef, '... and is initialized to undef' );
    is( $obj->_ignore_regex,   undef, '... and the accessor can read the attribute' );

    is( $obj->_ignore_regex('hello world'), 'hello world', '... and write to it' );
    is( $obj->{_ignore_regex},              'hello world', '... attribute is updated' );

    is( $obj->_ignore_regex( 1, 2, 3 ), 1, '_ignore_regex silently ignores superfluous arguments' );

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
