package Wikibase::Datatype::Value::Globecoordinate;

use strict;
use warnings;

use Error::Pure qw(err);
use Mo qw(build is);
use Wikibase::Datatype::Utils qw(check_entity);

our $VERSION = 0.34;

extends 'Wikibase::Datatype::Value';

has altitude => (
	'is' => 'ro',
);

has globe => (
	'is' => 'ro',
);

sub latitude {
	my $self = shift;

	return $self->{'value'}->[0];
}

sub longitude {
	my $self = shift;

	return $self->{'value'}->[1];
}

has precision => (
	'is' => 'ro',
);

sub type {
	return 'globecoordinate';
}

sub BUILD {
	my $self = shift;

	if (ref $self->{'value'} ne 'ARRAY') {
		err "Parameter 'value' must be a array.";
	}
	if (@{$self->{'value'}} != 2) {
		err "Parameter 'value' array must have two fields ".
			"(latitude and longitude).";
	}
	my ($lat, $lon) = @{$self->{'value'}};
	if ($lat !~ m/^\-?\d+\.?\d*$/ms) {
		err "Parameter 'value' has bad first parameter (latitude).";
	}
	if ($lon !~ m/^\-?\d+\.?\d*$/ms) {
		err "Parameter 'value' has bad first parameter (longitude).";
	}

	if (! defined $self->{'globe'}) {
		$self->{'globe'} = 'Q2',
	}
	check_entity($self, 'globe');

	if (! defined $self->{'precision'}) {
		$self->{'precision'} = '1e-07',
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Value::Globecoordinate - Wikibase globe coordinate value datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::Value::Globecoordinate;

 my $obj = Wikibase::Datatype::Value::Globecoordinate->new(%params);
 my $altitude = $obj->altitude;
 my $globe = $obj->globe;
 my $latitude = $obj->latitude;
 my $longitude = $obj->longitude;
 my $precision = $obj->precision;
 my $type = $obj->type;
 my $value = $obj->value;

=head1 DESCRIPTION

This datatype is globecoordinate class for representation of coordinate.

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Value::Globecoordinate->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<altitude>

Altitude.
Parameter is optional.
Default value is undef.

=item * C<globe>

Globe entity.
Parameter is optional.
Default value is 'Q2'.

=item * C<precision>

Coordinate precision.
Parameter is optional.
Default value is '1e-07'.

=item * C<value>

Value of instance.
Parameter is required.

=back

=head2 C<altitude>

 my $altitude = $obj->altitude;

Get altitude.

Returns TODO

=head2 C<globe>

 my $globe = $obj->globe;

Get globe. Unit is entity (e.g. /^Q\d+$/).

Returns string.

=head2 C<latitude>

 my $latitude = $obj->latitude;

Get latitude.

Returns number.

=head2 C<longitude>

 my $longitude = $obj->longitude;

Get longitude.

Returns number.

=head2 C<precision>

 my $precision = $obj->precision;

Get precision.

Returns number.

=head2 C<type>

 my $type = $obj->type;

Get type. This is constant 'string'.

Returns string.

=head2 C<value>

 my $value = $obj->value;

Get value.

Returns string.

=head1 ERRORS

 new():
         From Wikibase::Datatype::Utils::check_entity():
                 Parameter 'globe' must begin with 'Q' and number after it.
         From Wikibase::Datatype::Value::new():
                 Parameter 'value' is required.
         Parameter 'value' array must have two fields (latitude and longitude).
         Parameter 'value' has bad first parameter (latitude).
         Parameter 'value' has bad first parameter (longitude).
         Parameter 'value' must be a array.

=head1 EXAMPLE

=for comment filename=create_and_print_value_globecoordinate.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Value::Globecoordinate;

 # Object.
 my $obj = Wikibase::Datatype::Value::Globecoordinate->new(
         'value' => [49.6398383, 18.1484031],
 );

 # Get globe.
 my $globe = $obj->globe;

 # Get longitude.
 my $longitude = $obj->longitude;

 # Get latitude.
 my $latitude = $obj->latitude;

 # Get precision.
 my $precision = $obj->precision;

 # Get type.
 my $type = $obj->type;

 # Get value.
 my $value_ar = $obj->value;

 # Print out.
 print "Globe: $globe\n";
 print "Latitude: $latitude\n";
 print "Longitude: $longitude\n";
 print "Precision: $precision\n";
 print "Type: $type\n";
 print 'Value: '.(join ', ', @{$value_ar})."\n";

 # Output:
 # Globe: Q2
 # Latitude: 49.6398383
 # Longitude: 18.1484031
 # Precision: 1e-07
 # Type: globecoordinate
 # Value: 49.6398383, 18.1484031

=head1 DEPENDENCIES

L<Error::Pure>,
L<Mo>,
L<Wikibase::Datatype::Utils>,
L<Wikibase::Datatype::Value>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Value>

Wikibase datatypes.

=item L<Wikibase::Datatype::Print::Value::Globecoordinate>

Wikibase globe coordinate value pretty print helpers.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.34

=cut
