package Test::Type;

use strict;
use warnings;

use Carp qw();
use Data::Validate::Type;
use Exporter 'import';
use Test::More qw();


=head1 NAME

Test::Type - Functions to validate data types in test files.


=head1 VERSION

Version 1.3.0

=cut

our $VERSION = '1.3.0';


=head1 SYNOPSIS

	use Test::Type;

	# Test strings.
	ok_string( $variable );
	ok_string(
		$variable,
		name => 'My variable',
	);

	# Test arrayrefs.
	ok_arrayref( $variable );
	ok_arrayref(
		$variable,
		name => 'My variable',
	);

	# Test hashrefs.
	ok_hashref( $variable );
	ok_hashref(
		$variable,
		name => 'Test variable',
	);

	# Test coderefs.
	ok_coderef( $variable );
	ok_coderef(
		$variable,
		name => 'Test variable',
	);

	# Test numbers.
	ok_number( $variable );
	ok_number(
		$variable,
		name => 'Test variable',
	);

	# Test instances.
	ok_instance(
		$variable,
		class => $class,
	);
	ok_instance(
		$variable,
		name  => 'Test variable',
		class => $class,
	);

	# Test regular expressions.
	ok_regex( $variable );
	ok_regex(
		$variable,
		name => 'Test regular expression',
	);

=cut

our @EXPORT = ## no critic (Modules::ProhibitAutomaticExportation)
(
	'ok_arrayref',
	'ok_coderef',
	'ok_hashref',
	'ok_instance',
	'ok_number',
	'ok_string',
	'ok_regex',
);


=head1 FUNCTIONS

=head2 ok_string()

Test if the variable passed is a string.

	ok_string(
		$variable,
	);

	ok_string(
		$variable,
		name => 'My variable',
	);

	ok_string(
		$variable,
		name        => 'My variable',
		allow_empty => 1,
	);

Parameters:

=over 4

=item * name

Optional, the name of the variable being tested.

=item * allow_empty

Boolean, default 1. Allow the string to be empty or not.

=back

=cut

sub ok_string
{
	my ( $variable, %args ) = @_;

	# Verify arguments and set defaults.
	my $name = delete( $args{'name'} );
	$name = 'Variable' if !defined( $name );
	my $allow_empty = delete( $args{'allow_empty'} );
	$allow_empty = 1 if !defined( $allow_empty );
	Carp::croak( 'Unknown parameter(s): ' . join( ', ', keys %args ) . '.' )
		if scalar( keys %args ) != 0;

	my @test_properties = ();
	push( @test_properties, $allow_empty ? 'allow empty' : 'non-empty' );
	my $test_properties = scalar( @test_properties ) == 0
		? ''
		: ' (' . join( ', ', @test_properties ) . ')';

	return Test::More::ok(
		Data::Validate::Type::is_string(
			$variable,
			allow_empty => $allow_empty,
		),
		$name . ' is a string' . $test_properties . '.',
	);
}


=head2 ok_arrayref()

Test if the variable passed is an arrayref that can be dereferenced into an
array.

	ok_arrayref( $variable );

	ok_arrayref(
		$variable,
		name => 'My variable',
	);

	ok_arrayref(
		$variable,
		allow_empty => 1,
		no_blessing => 0,
	);

	# Check if the variable is an arrayref of hashrefs.
	ok_arrayref(
		$variable,
		allow_empty           => 1,
		no_blessing           => 0,
		element_validate_type =>
			sub
			{
				return Data::Validate::Type::is_hashref( $_[0] );
			},
	);

Parameters:

=over 4

=item * name

Optional, the name of the variable being tested.

=item * allow_empty

Boolean, default 1. Allow the array to be empty or not.

=item * no_blessing

Boolean, default 0. Require that the variable is not blessed.

=item * element_validate_type

None by default. Set it to a coderef to validate the elements in the array.
The coderef will be passed the element to validate as first parameter, and it
must return a boolean indicating whether the element was valid or not.

=back

=cut

sub ok_arrayref
{
	my ( $variable, %args ) = @_;

	# Verify arguments and set defaults.
	my $name = delete( $args{'name'} );
	$name = 'Variable' if !defined( $name );
	my $allow_empty = delete( $args{'allow_empty'} );
	$allow_empty = 1 if !defined( $allow_empty );
	my $no_blessing = delete( $args{'no_blessing'} );
	$no_blessing = 0 if !defined( $no_blessing );
	my $element_validate_type = delete( $args{'element_validate_type'} );
	Carp::croak( 'Unknown parameter(s): ' . join( ', ', keys %args ) . '.' )
		if scalar( keys %args ) != 0;

	my @test_properties = ();
	push( @test_properties, $allow_empty ? 'allow empty' : 'non-empty' );
	push( @test_properties, $no_blessing ? 'no blessing' : 'allow blessed' );
	push( @test_properties, 'validate elements' )
		if $element_validate_type;
	my $test_properties = scalar( @test_properties ) == 0
		? ''
		: ' (' . join( ', ', @test_properties ) . ')';

	return Test::More::ok(
		Data::Validate::Type::is_arrayref(
			$variable,
			allow_empty           => $allow_empty,
			no_blessing           => $no_blessing,
			element_validate_type => $element_validate_type,
		),
		$name . ' is an arrayref' . $test_properties . '.',
	);
}


=head2 ok_hashref()

Test if the variable passed is a hashref that can be dereferenced into a hash.

	ok_hashref( $variable );

	ok_hashref(
		$variable,
		name => 'Test variable',
	);

	ok_hashref(
		$variable,
		allow_empty => 1,
		no_blessing => 0,
	);

Parameters:

=over 4

=item * name

Optional, the name of the variable being tested.

=item * allow_empty

Boolean, default 1. Allow the array to be empty or not.

=item * no_blessing

Boolean, default 0. Require that the variable is not blessed.

=back

=cut

sub ok_hashref
{
	my ( $variable, %args ) = @_;

	# Verify arguments and set defaults.
	my $name = delete( $args{'name'} );
	$name = 'Variable' if !defined( $name );
	my $allow_empty = delete( $args{'allow_empty'} );
	$allow_empty = 1 if !defined( $allow_empty );
	my $no_blessing = delete( $args{'no_blessing'} );
	$no_blessing =  0 if !defined( $no_blessing );
	Carp::croak( 'Unknown parameter(s): ' . join( ', ', keys %args ) . '.' )
		if scalar( keys %args ) != 0;

	my @test_properties = ();
	push( @test_properties, $allow_empty ? 'allow empty' : 'non-empty' );
	push( @test_properties, $no_blessing ? 'no blessing' : 'allow blessed' );
	my $test_properties = scalar( @test_properties ) == 0
		? ''
		: ' (' . join( ', ', @test_properties ) . ')';

	return Test::More::ok(
		Data::Validate::Type::is_hashref(
			$variable,
			allow_empty           => $allow_empty,
			no_blessing           => $no_blessing,
		),
		$name . ' is a hashref' . $test_properties . '.',
	);
}


=head2 ok_coderef()

Test if the variable passed is an coderef that can be dereferenced into a block
of code.

	ok_coderef( $variable );

	ok_coderef(
		$variable,
		name => 'Test variable',
	);

Parameters:

=over 4

=item * name

Optional, the name of the variable being tested.

=back

=cut

sub ok_coderef
{
	my ( $variable, %args ) = @_;

	# Verify arguments and set defaults.
	my $name = delete( $args{'name'} );
	$name = 'Variable' if !defined( $name );
	Carp::croak( 'Unknown parameter(s): ' . join( ', ', keys %args ) . '.' )
		if scalar( keys %args ) != 0;

	return Test::More::ok(
		Data::Validate::Type::is_coderef(
			$variable,
		),
		$name . ' is a coderef.',
	);
}


=head2 ok_number()

Test if the variable passed is a number.

	ok_number( $variable );

	ok_number(
		$variable,
		name => 'Test variable',
	);

	ok_number(
		$variable,
		positive => 1,
	);

	ok_number(
		$variable,
		strictly_positive => 1,
	);

Parameters:

=over 4

=item * name

Optional, the name of the variable being tested.

=item * strictly_positive

Boolean, default 0. Set to 1 to check for a strictly positive number.

=item * positive

Boolean, default 0. Set to 1 to check for a positive number.

=back

=cut

sub ok_number
{
	my ( $variable, %args ) = @_;

	# Verify arguments and set defaults.
	my $name = delete( $args{'name'} );
	$name = 'Variable' if !defined( $name );
	my $strictly_positive = delete( $args{'strictly_positive'} );
	$strictly_positive = 0 if !defined( $strictly_positive );
	my $positive = delete( $args{'positive'} );
	$positive = 0 if !defined( $positive );
	Carp::croak( 'Unknown parameter(s): ' . join( ', ', keys %args ) . '.' )
		if scalar( keys %args ) != 0;

	my @test_properties = ();
	push( @test_properties, 'strictly positive' )
		if $strictly_positive;
	push( @test_properties, 'positive' )
		if $positive;
	my $test_properties = scalar( @test_properties ) == 0
		? ''
		: ' (' . join( ', ', @test_properties ) . ')';

	return Test::More::ok(
		Data::Validate::Type::is_number(
			$variable,
			strictly_positive => $strictly_positive,
			positive          => $positive,
		),
		$name . ' is a number' . $test_properties . '.',
	);
}


=head2 ok_instance()

Test if the variable is an instance of the given class.

Note that this handles inheritance properly, so it will succeed if the
variable is an instance of a subclass of the class given.

	ok_instance(
		$variable,
		class => $class,
	);

	ok_instance(
		$variable,
		name  => 'Test variable',
		class => $class,
	);

Parameters:

=over 4

=item * name

Optional, the name of the variable being tested.

=item * class

Required, the name of the class to check the variable against.

=back

=cut

sub ok_instance
{
	my ( $variable, %args ) = @_;

	# Verify arguments and set defaults.
	my $name = delete( $args{'name'} );
	$name = 'Variable' if !defined( $name );
	my $class = delete( $args{'class'} );
	Carp::croak( 'Unknown parameter(s): ' . join( ', ', keys %args ) . '.' )
		if scalar( keys %args ) != 0;

	return Test::More::ok(
		Data::Validate::Type::is_instance(
			$variable,
			class => $class,
		),
		$name . ' is an instance of ' . $class . '.',
	);
}


=head2 ok_regex()

Test if the variable is a regular expression.

	ok_regex( $variable );

=cut

sub ok_regex
{
	my ( $variable, %args ) = @_;

	# Verify arguments and set defaults.
	my $name = delete( $args{'name'} );
	$name = 'Variable' if !defined( $name );
	Carp::croak( 'Unknown parameter(s): ' . join( ', ', keys %args ) . '.' )
		if scalar( keys %args ) != 0;

	return Test::More::ok(
		Data::Validate::Type::is_regex( $variable ),
		$name . ' is a regular expression.',
	);
}


=head1 BUGS

Please report any bugs or feature requests to C<bug-test-dist-versionsync at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=test-type>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Test::Type


You can also look for information at:

=over

=item *

GitHub (report bugs there)

L<https://github.com/guillaumeaubert/Test-Type/issues>

=item *

AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/test-type>

=item *

CPAN Ratings

L<http://cpanratings.perl.org/d/test-type>

=item *

Search CPAN

L<https://metacpan.org/release/Test-Type>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2012-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
