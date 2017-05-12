#!perl -w

use strict;
use Test::More tests => 18;

use blib '..';
use MyMRO;
use mro ();

{
	package A;
	package B;
	our @ISA = qw(A);
	package C;
	our @ISA = qw(A);
	package D;
	our @ISA = qw(B C);

	package E;
	use mro 'c3';
	our @ISA = qw(B C);

	package F;
	use mro 'dfs';
	our @ISA = qw(B C);
}

foreach my $class (qw(A B C D E F)){
	is_deeply mro_get_linear_isa($class), mro::get_linear_isa($class), "mro_get_linear_isa($class)";
	like mro_get_pkg_gen($class), qr/\A \d+ \z/xms, 'mro_get_pkg_gen';

	ok eval{ mro_method_changed_in($class); 1 }, 'mro_method_changed_in';# How to test this behavior?
}
