package Test::Method;
use 5.006;
use strict;
use warnings;

our $VERSION = '0.001002'; # VERSION

use parent 'Exporter';
use Scalar::Util 'blessed';
use Test::Builder;
use Test::Deep::NoTest qw(
	cmp_details
	methods
	deep_diag
);

our @EXPORT ## no critic ( AutomaticExportation )
	= ( qw( method_ok ) );

sub method_ok { ## no critic ( ArgUnpacking )
	# first 2 args
	my ( $obj, $method, $args, $want, $name ) = @_;

	my $params = [ $method ];

	if ( defined $args && ref $args eq 'ARRAY' ) {
		push @{ $params }, @{ $args };
	}

	# padding
	$name .= ' ' if defined $name;

	$name .= blessed( $obj )
		. '->' . $method . '('
		. _get_printable_value( $args )
		. ') is '
		. _get_printable_value( $want )
		;

	my ( $ok, $stack ) = cmp_details( $obj, methods( $params, $want ) );

	my $test = Test::Builder->new;
	unless ( $test->ok( $ok, $name ) ) {
		my $diag = deep_diag( $stack );
		$test->diag( $diag );
	}
	return;
}

sub _get_printable_value {
	my ( $args ) = @_;

	return '' unless defined $args;
	if ( ref $args && ref $args eq 'ARRAY' ) {
		if ( scalar @{ $args } > 1 ) {
			return '...';
		}
		if ( scalar @{ $args } == 1 && ! defined @{ $args }[0] ) {
			return 'undef';
		}
		return &_get_printable_value( @{$args}[0] );
	}
	return ref $args if ref $args;

	return '"' . $args . '"';
}

1;

# ABSTRACT: test sugar for methods

__END__

=pod

=head1 NAME

Test::Method - test sugar for methods

=head1 VERSION

version 0.001002

=head1 SYNOPSIS

	use Test::More;
	use Test::Method;

	my $obj = Class->new; # blessed reference

	method_ok( $obj, 'method', [], 'value' ); # Class->method() is value

	method_ok( $obj, 'method', undef, 'value' ); # Class->method() is value

	method_ok( $obj, 'method', ['arg1', 'arg2'], 'expected', 'testname' );
	# testname Class->method(...) is 'expected'

	use Test::Deep;
	method_ok( $obj, 'method', [], re('^foo'), );
	# Test->method() is Test::Deep::Regexp

	done_testing;

=head1 DESCRIPTION

The reason for creating L<Test::Method> is to provide an easy way of testing
methods without writing a test name which could equate to Object, method
name, arguments, expected return. I found my test names suffered from lack of
appropriate details simply due to lack of desire for repetitive typing. This
module should help reduce this. The ultimate goal of this module is to make
testing methods on objects easier and less repetitive.

We're using L<Test::Deep> under the hood so you may use it's comparison
functions in place of expected.

=head1 FUNCTIONS

=head2 method_ok

	method_ok( $obj, 'method', \@method_args, 'expected', 'testname' );

use for testing a single method in an object, if not passing args use undef or
an empty arrayref will work. Unlike most testing modules specifying test name
will not replace all of the default test name, instead it is simply prepended.
This feature was desirable due to some object names not really being obvious
as to what I was looking at, so it allows me to give a hint to the parent
object or maybe a grander purpose.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/xenoterracide/test-method/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
