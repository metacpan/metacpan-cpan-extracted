#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 17;

sub ARRAY::join {
    my ($array, $delimiter) = @_;
    join ($delimiter, @$array);
}

sub SCALAR::split {
    my ($string, $pattern) = @_;
    [ split ($pattern, $string) ]
}

my $join = 'join';
my $split = 'split';
my $array = [ 1, 2, 3 ];
my $string = 'Hello';
my $undef = undef;
my $int = 42;
my $float = 3.1415927;

# make sure they don't work when autobox has not been enabled
eval { 'hello'->$split('') };
like($@, qr{^Can't locate object method "split" via package "hello"}, 'autobox not enabled for scalar'); 

eval { [ 1, 2, 3 ]->$join(' >> ') };
like($@, qr{^Can't call method "join" on unblessed reference\b}, 'autobox not enabled for array'); 

{
    use autobox;

    is ([ 1, 2, 3 ]->$join(' >> '), '1 >> 2 >> 3', q{[ 1, 2, 3 ]->$join(' >> ') eq '1 >> 2 >> 3'});
    is ([ 1, 2, 3 ]->$join(', '), '1, 2, 3', q{[ 1, 2, 3 ]->$join(', ') eq '1, 2, 3'});
    is ($array->$join(' >> '), '1 >> 2 >> 3', q{$array->$join(' >> ') eq '1 >> 2 >> 3'});
    is ($array->$join(', '), '1, 2, 3', q{$array->$join(', ') eq '1, 2, 3'});

    is_deeply('Hello'->$split(''), [ qw(H e l l o) ], q{'Hello'->$split('') == [ 'H', 'e', 'l', 'l', 'o' ]});
    is_deeply('Hello'->$split(qr{e}), [ 'H', 'llo' ], q{'Hello'->$split(qr{e}) == [ 'H', 'llo' ]});
    is_deeply($string->$split(''), [ qw(H e l l o) ], q{$string->$split('') == [ 'H', 'e', 'l', 'l', 'o' ]});
    is_deeply($string->$split(qr{e}), [ 'H', 'llo' ], q{$string->$split(qr{e}) == [ 'H', 'llo' ]});

    # make sure we don't segfault if the method is undef, an integer, a float &c. (see RT #35820)

    eval { no warnings 'uninitialized'; []->$undef };
    like($@, qr{^Can't call method "" on unblessed reference\b}, 'handle undefined method');

    eval { []->$int };
    like($@, qr{^Can't call method "$int" on unblessed reference\b}, 'handle integer method');

    eval { []->$float };
    like($@, qr{^Can't call method "\Q$float\E" on unblessed reference\b}, 'handle float method');

    no autobox;

    # make sure they don't work when autobox has been disabled
    eval { 'hello'->$split('') };
    like($@, qr{^Can't locate object method "split" via package "hello"}, 'autobox disabled for scalar'); 

    eval { [ 1, 2, 3 ]->$join(' >> ') };
    like($@, qr{^Can't call method "join" on unblessed reference}, 'autobox disabled for array'); 
}

# make sure they don't work when autobox is no longer in scope
eval { 'hello'->$split('') };
like($@, qr{^Can't locate object method "split" via package "hello"}, 'autobox not in scope for scalar'); 

eval { [ 1, 2, 3 ]->$join(' >> ') };
like($@, qr{^Can't call method "join" on unblessed reference}, 'autobox not in scope for array'); 
