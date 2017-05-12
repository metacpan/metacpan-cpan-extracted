package Test::Proto::Formatter::TestBuilder;
use 5.008;
use strict;
use warnings;
use Moo;
extends 'Test::Builder::Module';
my $CLASS = __PACKAGE__;

=pod

=head1 NAME

Test::Proto::Formatter::TestBuilder - formats RunnerEvents as TestBuilder events.

=head1 SYNOPSIS

	my $formatter = Test::Proto::Formatter->new();
	$formatter->event($testRunner, 'new');
	$formatter->event($testRunner, 'done');

This formatter is only used by the L<Test::Proto::TestRunner> class, and will be created when you use a prototype's C<ok>.


=head1 METHODS

=cut

=head3 event

	$formatter->event($testRunner, 'new');
	$formatter->event($testRunner, 'done');

Used in Test::Proto::TestRunner to inform the formatter of progress. Event types 'new' and 'done' are supported.

=cut

has '_object_id_register',
	is      => 'rw',
	default => sub { {} };

sub _explain_value {
	my $v = shift;
	return 'undef' unless defined $v;
	return $v unless ref $v;
	return 'Arrayref with ' . ( $#$v + 1 ) . ' values' if ref $v eq 'ARRAY';
	return 'Hashref with ' . ( scalar keys %$v ) . ' keys' if ref $v eq 'HASH';
	return ref $v;
}

sub _explain_test_case {
	my $self      = shift;
	my $test_case = shift;
	if ( ref $test_case ) {
		if ( $test_case->isa('Test::Proto::TestCase') ) {
			my $report = '';
			$report .= $test_case->name;
			$report .= "\nexpected: " . _explain_value( $test_case->data->{expected} ) if defined( $test_case->data->{expected} );
			if ( scalar keys %{ $test_case->data } > 1 ) {
				$report .= "\nOther data:";
				foreach my $key ( grep { 'expected' ne $_ } keys %{ $test_case->data } ) {
					$report .= "\n  $key: " . $test_case->data->{$key};
				}
			}
			return $report;
		}
		return '[not a TestCase]';
	}
	else {
		return '[not a TestCase or any other object]';
	}
}

sub event {
	my $self      = shift;
	my $runner    = shift;
	my $eventType = shift;
	if ( 'new' eq $eventType ) {
		my $name =
			  defined( $runner->test_case )
			? $runner->test_case->can('name')
				? $runner->test_case->name
				: ref $runner->test_case
			: undef;
		if ( defined $runner->parent ) {
			$self->_object_id_register->{ $runner->object_id } = $self->_object_id_register->{ $runner->parent->object_id }->child($name);
		}
		else {
			$self->_object_id_register->{ $runner->object_id } = $CLASS->builder->child($name);
		}
	}
	elsif ( 'done' eq $eventType ) {
		if ( my $tb = $self->_object_id_register->{ $runner->object_id } ) {
			$tb->ok( $runner, $runner->status . " - got: " . ( defined $runner->subject ? $runner->subject : '[undefined]' ) . "\n" . $self->_explain_test_case( $runner->test_case ) . ( defined $runner->status_message ? "\n" . $runner->status_message : '' ) );
			$tb->done_testing;
			$tb->finalize;
		}
		else {
			die( 'Have not registered object ' . $runner->object_id );
		}
	}
	return $self;
}

=head3 format

	$formatter->format($runner);

Outputs information from a test runner that is already complete but did not expect to be outputting to Test::Builder.

=cut

sub format {
	my $self   = shift;
	my $runner = shift;
	$self->event( $runner, 'new' );
	$self->event( $runner, 'done' );
	return $self;
}

1;

=head1 OTHER INFORMATION

For author, version, bug reports, support, etc, please see L<Test::Proto>. 

=cut

