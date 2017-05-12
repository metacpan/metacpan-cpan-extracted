#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 27;

sub ARRAY::join {
    my ($array, $delimiter) = @_;
    join($delimiter, @$array);
}

sub ARRAY::push {
    my ($array, @args) = @_;
    push(@$array, @args);
}

sub HASH::keys {
    my $hash = shift;
    [ sort keys(%$hash) ]
}

sub HASH::set {
    my ($hash, $key, $value) = @_;
    $hash->{$key} = $value;
}

our @ISA = ();
my @array  = (1 .. 3);
my $array = \@array;
my %hash = (qw(alpha beta gamma vlissides));
my $hash = \%hash;
my $ejoin = qr{Can't (call|locate object) method "join" (without a|via) package\b};
my $ekeys = qr{Can't (call|locate object) method "keys" (without a|via) package\b};

# make sure it doesn't work before autobox is enabled
eval { @array->join(', ') };
like ($@, $ejoin, '@array->join fails before autobox is enabled');

eval { %hash->keys };
like ($@, $ekeys, '%hash->keys fails before autobox is enabled');

{
    use autobox;

    # confirm that these work as normal
    is((\@array)->join(', '), '1, 2, 3', q{(\@array)->join(', ') == '1, 2, 3'});
    is_deeply((\%hash)->keys, [ qw(alpha gamma) ], q{(\%hash)->keys == [ 'alpha', 'gamma' ]});

    # now confirm that @array and %hash receivers work
    is(@array->join(', '), '1, 2, 3', q{@array->join(', ') == '1, 2, 3'});
    is_deeply(%hash->keys, [ qw(alpha gamma) ], q{%hash->keys == [ 'alpha', 'gamma' ]});

    # ditto with parens
    is((@array)->join(', '), '1, 2, 3', q{(@array)->join(', ') == '1, 2, 3'});
    is_deeply((%hash)->keys, [ qw(alpha gamma) ], q{(%hash)->keys == [ 'alpha', 'gamma' ]});
    is(((@array))->join(', '), '1, 2, 3', q{((@array))->join(', ') == '1, 2, 3'});
    is_deeply(((%hash))->keys, [ qw(alpha gamma) ], q{((%hash))->keys == [ 'alpha', 'gamma' ]});

    # now confirm that @$array and %$hash receivers work
    is(@$array->join(', '), '1, 2, 3', q{@$array->join(', ') == '1, 2, 3'});
    is_deeply(%$hash->keys, [ qw(alpha gamma) ], q{%$hash->keys == [ 'alpha', 'gamma' ]});

    # ditto with parens
    is((@$array)->join(', '), '1, 2, 3', q{(@$array)->join(', ') == '1, 2, 3'});
    is_deeply((%$hash)->keys, [ qw(alpha gamma) ], q{(%$hash)->keys == [ 'alpha', 'gamma' ]});
    is(((@$array))->join(', '), '1, 2, 3', q{((@$array))->join(', ') == '1, 2, 3'});
    is_deeply(((%$hash))->keys, [ qw(alpha gamma) ], q{((%$hash))->keys == [ 'alpha', 'gamma' ]});

    # now confirm that @array and %hash are passed by reference (and thus can be mutated)
    @array->push(4);
    is_deeply(\@array, [ 1 .. 4 ], q{mutate @array});

    %hash->set('helm', 'johnson');
    is_deeply(\%hash, { qw(alpha beta gamma vlissides helm johnson) }, q{mutate %hash});

    # tied hash
    %ENV->set('autobox_test', 42);
    is ($ENV{autobox_test}, 42, 'tied hash');

    # tied array
    @ISA->push('autobox_test');
    is ($ISA[-1], 'autobox_test', 'tied array');

    # confirm multiple (> 1) args are passed a) as a list (i.e. not an array ref)
    # and b) unreferenced e.g. (1, 2, ...) rather than (\1, \2, ...)
    # XXX I can't reproduce an error with perl 5.14, but could have sworn I spotted this
    # not working on older perls...
    @array = (1 .. 5);
    @array->push(6 .. 10);
    is_deeply(\@array, [ 1 .. 10 ], q{void context: @array->push(qw(multiple values))});

    # same again with different contexts
    @array = (1 .. 5);
    my $scalar = @array->push(6 .. 10);
    is_deeply(\@array, [ 1 .. 10 ], q{scalar context: @array->push(qw(multiple values))});

    @array = (1 .. 5);
    my @list = @array->push(6 .. 10);
    is_deeply(\@array, [ 1 .. 10 ], q{list context: @array->push(qw(multiple values))});

    no autobox;

    # make sure it doesn't work when autobox is disabled
    eval { @array->join(', ') };
    like ($@, $ejoin, '@array->join fails after autobox is disabled');

    eval { %hash->keys };
    like ($@, $ekeys, '%hash->keys fails after autobox is disabled');
}

# make sure it doesn't work when autobox is out of scope
eval { @array->join(', ') };
like ($@, $ejoin, '@array->join fails when autobox is out of scope');

eval { %hash->keys };
like ($@, $ekeys, '%hash->keys fails when autobox is out of scope');
