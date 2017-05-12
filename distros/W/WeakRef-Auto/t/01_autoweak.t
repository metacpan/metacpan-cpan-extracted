#!perl -w

use strict;
use Test::More tests => 22;

use WeakRef::Auto;
#use Devel::Peek;

my $destroyed = 0;
{
	package T;
	sub new{ bless {}, shift }
	sub DESTROY{ $destroyed++ }
}

autoweaken my $ref;
{
	my $t = {};
	$ref = $t;
	is $ref, $t;
}
is $ref, undef, 'weak ref is released';

{
	my $t1 = T->new;
	my $t2 = $t1;

	$ref = $t1;

	is $destroyed, 0;
	is $ref, $t2;

	$t1 = [];
	is $ref, $t2;
}
is $destroyed, 1;
is $ref, undef;

$ref = T->new;
is $destroyed, 2;
is $ref, undef;

undef $ref;
is $ref, undef;

$ref = [];
is $ref, undef;

$ref = *WeakRef::Auto::VERSION{SCALAR};
is $$ref, $WeakRef::Auto::VERSION;

my $a = 42;
autoweaken our $gref;
$gref = \$a;

{
	local $gref;

	is $gref, undef, 'localize';
	$gref = T->new;
	is $gref, undef;

	is $destroyed, 3;
}

is $$gref, 42, 'retrieve after localized';

my $var = [42];
is_deeply $var, [42];
autoweaken $var;
is_deeply $var, undef;

# Expectional cases

autoweaken $ref;
$ref = [];
is $ref, undef, 'double autoweaken()';

$ref = $gref;
$ref = undef;
is $ref, undef, 'set undef';

# FATAL cases

eval{
	$ref = 1;
};
like $@, qr/Can't weaken a nonreference/;

eval{
	&autoweaken(10);
};
like $@, qr/not a reference/;
