#!perl -T
use strict;
use warnings;
use Data::Dumper;

use Test::More;
use Test::Proto::CodeRef;

my $frob = sub {
	if (defined wantarray) {
		return qw (list context), @_ if (wantarray);
		return 'scalar';
	}
	die ('Set up to die on empty void call') unless $_[0];
};

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


sub pCode { Test::Proto::CodeRef->new(); }

is_a_good_pass(pCode->call([], [qw(list context)])->validate($frob), 'call passes ok');
is_a_good_fail(pCode->call([], [qw(not correct)])->validate($frob), 'call fails ok');
is_a_good_pass(pCode->call(['foo'], [qw(list context foo)])->validate($frob), 'call passes ok, uses args');
is_a_good_pass(pCode->call_list_context([], [qw(list context)])->validate($frob), 'call_list_context passes ok');
is_a_good_pass(pCode->call_list_context(['foo'], [qw(list context foo)])->validate($frob), 'call_list_context passes ok, uses args');
is_a_good_pass(pCode->call_scalar_context([], 'scalar')->validate($frob), 'call_scalar_context passes ok');
is_a_good_pass(pCode->call_void_context(['foo'])->validate($frob), 'call_void_context passes ok');



done_testing;

