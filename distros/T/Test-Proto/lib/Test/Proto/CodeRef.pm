package Test::Proto::CodeRef;
use 5.008;
use strict;
use warnings;
use Moo;
extends 'Test::Proto::Base';
with( 'Test::Proto::Role::Value', );
use Test::Proto::Common;

=head1 NAME

Test::Proto::CodeRef - Test a coderef's behaviour

=head1 METHODS

=head3 call

	$p->call(['test.txt','>'], [$fh])->ok($subject);

Takes two arguments: first, the arguments to pass to the code, second the expected return value. Passes the arguments to the test subject, and tests the return value against the expected value. 

The arguments and return value should be arrayrefs; the code is evaluated in list context.

=cut

sub call {
	my ($self) = shift;
	$self->call_list_context(@_);
}

=head3 call_void_context

	$p->call_void_context(['test.txt','>'])->ok($subject);

Takes one argument: the arguments to use with the method, as an arrayref. Calls the method on the test subject, with the arguments. This test will always pass, unless the code dies, or is not code.

=cut

sub call_void_context {
	my ( $self, $args, $reason ) = @_;
	$self->add_test( 'call_void_context', { args => $args, }, $reason );
}

define_test "call_void_context" => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner
	my $args = $data->{args};
	$self->subject->(@$args);
	return $self->pass;                   #~ void context so we pass unless it dies.
};

=head3 call_scalar_context

	$p->call_scalar_context(['test.txt','>'], $true)->ok($subject);

Takes two arguments: first, the arguments to pass to the code, second the expected return value. Passes the arguments to the test subject, and tests the return value against the expected value. 

The arguments should be an arrayref, and the expected value should be a prototype evaluating the returned scalar, as the method is evaluated in scalar context.

=cut

sub call_scalar_context {
	my ( $self, $args, $expected, $reason ) = @_;
	$self->add_test(
		'call_scalar_context',
		{
			args     => $args,
			expected => $expected
		},
		$reason
	);
}

define_test "call_scalar_context" => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner
	my $args     = $data->{args};
	my $expected = upgrade( $data->{expected} );
	my $response = $self->subject->(@$args);
	return $expected->validate( $response, $self );
};

=head3 call_list_context

	$p->call_list_context(['test.txt','>'], [$true])->ok($subject);

Takes two arguments: first, the arguments to pass to the code, second the expected return value. Passes the arguments to the test subject, and tests the return value against the expected value. 

The arguments and return value should be arrayrefs; the code is evaluated in list context.

=cut

sub call_list_context {
	my ( $self, $args, $expected, $reason ) = @_;
	$self->add_test(
		'call_list_context',
		{
			args     => $args,
			expected => $expected
		},
		$reason
	);
}

define_test call_list_context => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner
	my $args     = $data->{args};
	my $expected = upgrade( $data->{expected} );
	my $response = [ $self->subject->(@$args) ];
	return $expected->validate( $response, $self );
};

=head1 OTHER INFORMATION

For author, version, bug reports, support, etc, please see L<Test::Proto>. 

=cut

1;
