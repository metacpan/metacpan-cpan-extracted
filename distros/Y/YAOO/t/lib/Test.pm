package Test;

use strict;
use warnings;

use YAOO;

auto_build;

require_has qw/six seven/;

has one => ro, isa(hash(a => "b", c => "d", e => [qw/1 2 3/], f => { 1 => { 2 => { 3 => 4 } } }));

has two => rw, isa(array(qw/a b c d/));

has three => rw, isa(integer);	

has four => rw, isa(boolean);

has five => rw, isa(ordered_hash(
	first => 1,
	second => 2,
	third => 3
));

sub before_method {
	return 'testing';
}

sub around_method {
	return 'changed';
}

sub after_method {
	return 'tester';
}

1;
