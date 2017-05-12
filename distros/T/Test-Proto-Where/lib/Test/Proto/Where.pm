package Test::Proto::Where;
use strict;
use warnings;
use Test::Proto::Common();
use base 'Exporter';
our @EXPORT = qw(&test_subject &where &otherwise);

=head1 NAME

Test::Proto::Where - provide case switching using Test::Proto

=head1 VERSION

0.001

=cut

our $VERSION = '0.001';

=head1 SYNOPSIS

	print test_subject {foo=>'bar'} =>
		where [], sub{ 'Empty array' },
		where pHash, sub{ 'A hash' },
		otherwise sub { 'Something else' };

Uses Test::Proto and its upgrading feature to implement a dispatch.

Note: This module is presently B<EXPERIMENTAL>: it is a working proof of concept.

=head1 SYNTAX

=head3 test_subject

Takes as its first argument a prototype, which must not be a list of bare array/hash. It then takes one or more where/otherwise statements, as described below. If it does not get the arguments it requires, it will C<die>. 

If you are taking the first argument from a function or method call, you should use scalar to force scalar context, like this:

	test_subject scalar($obj->method) =>
		where ...

Note also that because test_subject takes where and otherwise as arugments, if you are enclosing the first argument in brackets you must enclose all the arguments in brackets, other wise perl will be confused and think you are only passing the first argument.

=cut

sub test_subject ($$) {
	my $subject = shift;
	my $where   = shift;
	die('Missing where') unless defined $where;
	die('Expected where or otherwise') if ref $where ne 'Test::Proto::Where';
	return $where->{run}->($subject);
}

=head3 where

C<where> is followed by a test, then an instruction. If the test passes, the instruction is carried out and no other 'where' or 'otherwise' statements are executed.

=cut

sub where ($&;$) {
	my $self = {
		proto    => shift,
		code     => shift,
		type     => 'where',
		fallback => shift
	};
	$self->{run} = sub {
		my $subject = shift;
		return $self->{code}->($subject) if Test::Proto::Common::upgrade( $self->{proto} )->validate($subject);
		return unless defined $self->{fallback};
		die('Expected where or otherwise') if ref $self->{fallback} ne 'Test::Proto::Where';
		return $self->{fallback}->{run}->($subject);
	};
	die('where needs code') unless defined $self->{code};
	bless $self, __PACKAGE__;
}

=head3 otherwise

C<otherwise> is followed an instruction. If no preceding where tests have passed, this instruction will be executed.

=cut

sub otherwise (&) {
	my $self = {
		code => shift,
		type => 'otherwise'
	};
	$self->{run} = $self->{code};
	bless $self, __PACKAGE__;
}

# test_subject scalar foo(), where pArray, {}, otherwise {};

