#!perl -T
use strict;
use warnings;
use Data::Dumper;

use Test::More;
use Test::Proto::Object;

{
	package MyDummyClass;
	sub new(){
		my $class = shift;
		bless {@_}, $class;
	}
	sub frob {
		my $self = shift;
		if (defined wantarray) {
			return @_ if $self->{parrot};
			return qw (list context) if (wantarray);
			return 'scalar';
		}
		die ('Set up to die on void call') if $self->{dies};
	}
}

ok (1, 'ok is ok');

sub is_a_good_pass {
	# Todo: test this more
	ok($_[0]?1:0, , $_[1]) or diag Dumper $_[0];
}

sub is_a_good_fail {
	# Todo: test this more
	ok($_[0]?0:1, $_[1]) or diag Dumper $_[0];
	ok(!$_[0]->is_exception, '... and not be an exception') or diag Dumper $_[0];
}

sub is_a_good_exception {
	# Todo: test this more
	ok($_[0]?0:1, $_[1]);
	ok($_[0]->is_exception, '... and be an exception');
}


sub pOb { Test::Proto::Object->new(); }

my $s = MyDummyClass->new();
my $parrot = MyDummyClass->new(parrot=>1);
my $dies = MyDummyClass->new(dies=>1);

is_a_good_pass(pOb->method('frob', [], [qw(list context)])->validate($s), '->method passes ok');
is_a_good_pass(pOb->method('frob')->validate($s), '->method passes ok as method_exists');
is_a_good_pass(pOb->method('frob', 'Because')->validate($s), '->method passes ok as method_exists with an explanation');
is_a_good_fail(pOb->method('click')->validate($s), '->method fails correctly as method_exists');
is_a_good_pass(pOb->method_list_context('frob', [], [qw(list context)])->validate($s), '->method_list_context passes ok');
is_a_good_pass(pOb->method_scalar_context('frob', [], 'scalar')->validate($s), '->method_scalar_context passes ok');
is_a_good_pass(pOb->method_void_context('frob', [])->validate($s), '->method_void_context passes ok');
is_a_good_exception(pOb->method_void_context('frob', [])->validate($dies), '->method_void_context throws exception ok');
is_a_good_pass(pOb->method_exists('frob')->validate($s), '->method_exists passes ok');
is_a_good_fail(pOb->method_exists('click')->validate($s), '->method_exists fails correctly');



done_testing;

