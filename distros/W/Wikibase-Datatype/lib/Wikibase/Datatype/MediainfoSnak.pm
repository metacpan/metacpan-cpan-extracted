package Wikibase::Datatype::MediainfoSnak;

use strict;
use warnings;

use Error::Pure qw(err);
use List::MoreUtils qw(none);
use Mo qw(build is);
use Mo::utils qw(check_isa check_required);
use Readonly;
use Wikibase::Datatype::Utils qw(check_property);

Readonly::Array our @SNAK_TYPES => qw(
	novalue
	somevalue
	value
);

our $VERSION = 0.31;

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
	check_required($self, 'property');

	# Check data value.
	if ($self->{'snaktype'} eq 'value') {
		check_isa($self, 'datavalue', 'Wikibase::Datatype::Value');
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

Wikibase::Datatype::MediainfoSnak - Wikibase mediainfo snak datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::MediainfoSnak;

 my $obj = Wikibase::Datatype::MediainfoSnak->new(%params);
 my $datavalue = $obj->datavalue;
 my $property = $obj->property;
 my $snaktype = $obj->snaktype;

=head1 DESCRIPTION

This datatype is snak class for representing relation between property and value.
This datatype is used in statements in Commons structured data instead of snak
datatype.

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::MediainfoSnak->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<datavalue>

Value of data.
Parameter is required.

=item * C<property>

Property name (like /^P\d+$/).
Parameter is required.

=item * C<snaktype>

Snak type.
Parameter is string with these possible values: novalue somevalue value
Parameter is optional.
Default value is 'value'.

=back

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
                 Parameter 'datavalue' is required.
                 Parameter 'property' is required.
         From Mo::utils::check_isa():
                 Parameter 'datavalue' must be a 'Wikibase::Datatype::Value' object.
         From Wikibase::Datatype::Utils::check_property():
                 Parameter 'property' must begin with 'P' and number after it.
         Parameter 'snaktype' = '%s' isn't supported.

=head1 EXAMPLE

=for comment filename=create_and_print_mediainfosnak.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::MediainfoSnak;
 use Wikibase::Datatype::Value::Item;

 # Object.
 my $obj = Wikibase::Datatype::MediainfoSnak->new(
         'datavalue' => Wikibase::Datatype::Value::Item->new(
                 'value' => 'Q14946043',
         ),
         'property' => 'P275',
 );

 # Get value.
 my $datavalue = $obj->datavalue->value;

 # Get property.
 my $property = $obj->property;

 # Get snak type.
 my $snaktype = $obj->snaktype;

 # Print out.
 print "Property: $property\n";
 print "Value: $datavalue\n";
 print "Snak type: $snaktype\n";

 # Output:
 # Property: P275
 # Value: Q14946043
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

=item L<Wikibase::Datatype::Snak>

Wikibase snak datatype.

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

0.31

=cut
