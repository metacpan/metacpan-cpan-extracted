#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Scalar::Util 'weaken';
use Symbol qw 'gensym geniosym';

BEGIN { use_ok("Tie::RefHash::Weak") };

tie my %hash, "Tie::RefHash::Weak";

{ package overloaded;
	use overload fallback => 1,
	'${}' => sub { \my $v },
	'@{}' => sub { [] },
	'%{}' => sub { +{} },
	'&{}' => sub { my $v; sub { $v } },
	'*{}' => sub { Symbol::gensym },
}

my @types = (
	sub { \my $v },                # SCALAR
	sub { \\my $v },               # REF
	sub { \substr my $v = '', 0 }, # LVALUE
	sub { [] },                    # ARRAY
	sub { +{} },                   # HASH
	sub { gensym },                # GLOB
	sub { geniosym },              # IO
	sub { my $v; sub { $v } },     # CODE
);

my @refs = map { &$_, bless &$_, "overloaded"} @types;

@hash{@refs} = (1) x @refs;

is_deeply
	[sort(map Tie::RefHash::refaddr($_), keys %hash)],
	[sort(map Tie::RefHash::refaddr($_), @refs     )],
	'elements with overloaded keys can be created';


@refs = map { &$_, bless &$_, "overloaded"} @types;

# we'll make sure these are freed:
weaken $_ for my @copies = @refs;
my $value = [];

%hash = (); # start from scratch
@hash{@refs} = ($value) x @refs;
weaken $value;

is scalar keys %hash, @refs, 'number of keys to begin with';

@refs = ();

is grep(defined, @copies), 0, 'the keys were freed';
is $value, undef, 'the value was freed';

is scalar keys %hash, 0, 'elements with overloaded keys are freed';
