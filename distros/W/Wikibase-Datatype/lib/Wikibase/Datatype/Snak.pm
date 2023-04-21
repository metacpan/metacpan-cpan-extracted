package Wikibase::Datatype::Snak;

use strict;
use warnings;

use Error::Pure qw(err);
use List::MoreUtils qw(none);
use Mo qw(build is);
use Mo::utils qw(check_isa check_required);
use Readonly;
use Wikibase::Datatype::Utils qw(check_property);

# Pairs data type and datatype.
Readonly::Hash our %DATA_TYPES => (
	'commonsMedia' => 'Wikibase::Datatype::Value::String',
	'external-id' => 'Wikibase::Datatype::Value::String',
	'geo-shape' => 'Wikibase::Datatype::Value::String',
	'globe-coordinate' => 'Wikibase::Datatype::Value::Globecoordinate',
	'math' => 'Wikibase::Datatype::Value::String',
	'monolingualtext' => 'Wikibase::Datatype::Value::Monolingual',
	'musical-notation' => 'Wikibase::Datatype::Value::String',
	'quantity' => 'Wikibase::Datatype::Value::Quantity',
	'string' => 'Wikibase::Datatype::Value::String',
	'tabular-data' => 'Wikibase::Datatype::Value::String',
	'time' => 'Wikibase::Datatype::Value::Time',
	'url' => 'Wikibase::Datatype::Value::String',
	'wikibase-item' => 'Wikibase::Datatype::Value::Item',
	'wikibase-property' => 'Wikibase::Datatype::Value::Property',
);
Readonly::Array our @SNAK_TYPES => qw(
	novalue
	somevalue
	value
);

our $VERSION = 0.26;

has datatype => (
	is => 'ro',
);

has datavalue => (
	is => 'ro',
);

has property => (
	is => 'ro',
);

has snaktype => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check snak type.
	if (defined $self->{'snaktype'}) {
		if (none { $self->{'snaktype'} eq $_ } @SNAK_TYPES) {
			err "Parameter 'snaktype' = '$self->{'snaktype'}' isn't supported.";
		}
	} else {
		$self->{'snaktype'} = 'value';
	}

	# Requirements.
	if ($self->{'snaktype'} eq 'value') {
		check_required($self, 'datavalue');
	}
	check_required($self, 'datatype');
	check_required($self, 'property');

	# Check data type.
	if (none { $self->{'datatype'} eq $_ } keys %DATA_TYPES) {
		err "Parameter 'datatype' = '$self->{'datatype'}' isn't supported.";
	}

	# Check data value.
	if ($self->{'snaktype'} eq 'value') {
		check_isa($self, 'datavalue', $DATA_TYPES{$self->{'datatype'}});
	}

	# Check property.
	check_property($self, 'property');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Snak - Wikibase snak datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::Snak;

 my $obj = Wikibase::Datatype::Snak->new(%params);
 my $datatype = $obj->datatype;
 my $datavalue = $obj->datavalue;
 my $property = $obj->property;
 my $snaktype = $obj->snaktype;

=head1 DESCRIPTION

This datatype is snak class for representing relation between property and value.

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Snak->new(%params);

Constructor.

Retruns instance of object.

=over 8

=item * C<datatype>

Type of data.
Parameter is required.

 Possible datatypes are (datavalue instance in parenthesis):
 - commonsMedia (Wikibase::Datatype::Value::String)
 - external-id (Wikibase::Datatype::Value::String)
 - geo-shape (Wikibase::Datatype::Value::String)
 - globe-coordinate (Wikibase::Datatype::Value::Globecoordinate)
 - math (Wikibase::Datatype::Value::String)
 - monolingualtext (Wikibase::Datatype::Value::Monolingual)
 - musical-notation (Wikibase::Datatype::Value::String)
 - quantity (Wikibase::Datatype::Value::Quantity)
 - string (Wikibase::Datatype::Value::String)
 - tabular-data (Wikibase::Datatype::Value::String)
 - time (Wikibase::Datatype::Value::Time)
 - url (Wikibase::Datatype::Value::String)
 - wikibase-item (Wikibase::Datatype::Value::Item)
 - wikibase-property (Wikibase::Datatype::Value::Property)

=item * C<datavalue>

Value of data in form of Wikibase::Datatype::Value instance for concrete datatype.
Parameter is required in situation when snaktype = 'value'.

=item * C<property>

Property name (like /^P\d+$/).
Parameter is required.

=item * C<snaktype>

Snak type.
Parameter is string with these possible values: novalue somevalue value
Parameter is optional.
Default value is 'value'.

=back

=head2 C<datatype>

 my $datatype = $obj->datatype;

Get data type.

Returns string.

=head2 C<datavalue>

 my $datavalue = $obj->datavalue;

Get data value.

Returns instance of Wikibase::Datatype::Value.

=head2 C<property>

 my $property = $obj->property;

Get property name.

Returns string.

=head2 C<snaktype>

 my $snaktype = $obj->snaktype;

Get snak type.

Returns string.

=head1 ERRORS

 new():
         From Mo::utils::check_required():
                 Parameter 'datatype' is required.
                 Parameter 'datavalue' is required.
                 Parameter 'property' is required.
         From Mo::utils::check_isa():
                 Parameter 'datavalue' must be a 'Wikibase::Datatype::Value::%s' object.
         From Wikibase::Datatype::Utils::check_property():
                 Parameter 'property' must begin with 'P' and number after it.
         Parameter 'datatype' = '%s' isn't supported.
         Parameter 'snaktype' = '%s' isn't supported.

=head1 EXAMPLE

=for comment filename=create_and_print_snak.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Snak;
 use Wikibase::Datatype::Value::Item;

 # Object.
 my $obj = Wikibase::Datatype::Snak->new(
         'datatype' => 'wikibase-item',
         'datavalue' => Wikibase::Datatype::Value::Item->new(
                 'value' => 'Q5',
         ),
         'property' => 'P31',
 );

 # Get value.
 my $datavalue = $obj->datavalue->value;

 # Get datatype.
 my $datatype = $obj->datatype;

 # Get property.
 my $property = $obj->property;

 # Get snak type.
 my $snaktype = $obj->snaktype;

 # Print out.
 print "Property: $property\n";
 print "Type: $datatype\n";
 print "Value: $datavalue\n";
 print "Snak type: $snaktype\n";

 # Output:
 # Property: P31
 # Type: wikibase-item
 # Value: Q5
 # Snak type: value

=head1 DEPENDENCIES

L<Error::Pure>,
L<List::MoreUtils>,
L<Mo>,
L<Mo::utils>,
L<Readonly>,
L<Wikibase::Datatype::Utils>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.26

=cut
