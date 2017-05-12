#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 18;

my $join = sub {
    my ($array, $delimiter) = @_;
    join ($delimiter, @$array);
};

sub split {
    my ($string, $pattern) = @_;
    [ CORE::split ($pattern, $string) ]
}

sub SCALAR::to_upper { uc $_[0] }

my $array = [ 1, 2, 3 ];
my $string = 'Hello';
my $split = \&split;

# make sure autobox isn't on
eval { 'hello'->to_upper };
like($@, qr{^Can't locate object method "to_upper" via package "hello"}, 'autobox is not enabled'); 

# This has always worked, regardless of whether autobox is used or not
is ([ 1, 2, 3 ]->$join(' >> '), '1 >> 2 >> 3', q{no autobox: [ 1, 2, 3 ]->$join(' >> ') eq '1 >> 2 >> 3'});
is ([ 1, 2, 3 ]->$join(', '), '1, 2, 3', q{no autobox: [ 1, 2, 3 ]->$join(', ') eq '1, 2, 3'});
is ($array->$join(' >> '), '1 >> 2 >> 3', q{no autobox: $array->$join(' >> ') eq '1 >> 2 >> 3'});
is ($array->$join(', '), '1, 2, 3', q{no autobox: $array->$join(', ') eq '1, 2, 3'});

is_deeply('Hello'->$split(''), [ qw(H e l l o) ], q{no autobox: 'Hello'->$split('') == [ 'H', 'e', 'l', 'l', 'o' ]});
is_deeply('Hello'->$split(qr{e}), [ 'H', 'llo' ], q{no autobox: 'Hello'->$split(qr{e}) == [ 'H', 'llo' ]});
is_deeply($string->$split(''), [ qw(H e l l o) ], q{no autobox: $string->$split('') == [ 'H', 'e', 'l', 'l', 'o' ]});
is_deeply($string->$split(qr{e}), [ 'H', 'llo' ], q{no autobox: $string->$split(qr{e}) == [ 'H', 'llo' ]});

# but "use autobox" shouldn't break it
{
    use autobox;

    # make sure autobox is on

    is('hello'->to_upper, 'HELLO', 'autobox is enabled');
    is ([ 1, 2, 3 ]->$join(' >> '), '1 >> 2 >> 3', q{use autobox: [ 1, 2, 3 ]->$join(' >> ') eq '1 >> 2 >> 3'});
    is ([ 1, 2, 3 ]->$join(', '), '1, 2, 3', q{use autobox: [ 1, 2, 3 ]->$join(', ') eq '1, 2, 3'});
    is ($array->$join(' >> '), '1 >> 2 >> 3', q{use autobox: $array->$join(' >> ') eq '1 >> 2 >> 3'});
    is ($array->$join(', '), '1, 2, 3', q{use autobox: $array->$join(', ') eq '1, 2, 3'});

    is_deeply('Hello'->$split(''), [ qw(H e l l o) ], q{use autobox: 'Hello'->$split('') == [ 'H', 'e', 'l', 'l', 'o' ]});
    is_deeply('Hello'->$split(qr{e}), [ 'H', 'llo' ], q{use autobox: 'Hello'->$split(qr{e}) == [ 'H', 'llo' ]});
    is_deeply($string->$split(''), [ qw(H e l l o) ], q{use autobox: $string->$split('') == [ 'H', 'e', 'l', 'l', 'o' ]});
    is_deeply($string->$split(qr{e}), [ 'H', 'llo' ], q{use autobox: $string->$split(qr{e}) == [ 'H', 'llo' ]});
}
