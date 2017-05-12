
package XML::SRS::Contact::Address;
BEGIN {
  $XML::SRS::Contact::Address::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;

sub address() {
    my $self = shift;
    
	(   $self->address1,
		$self->address2,
		$self->city,
		$self->region,
		$self->postcode,
		$self->cc,
	);
}

has_attr 'address1' =>
	is => "rw",
	isa => "Str",
	xml_required => 0,
	xml_name => "Address1",
	;

has_attr 'address2' =>
	is => "rw",
	isa => "Str",
	xml_required => 0,
	xml_name => "Address2",
	;

has_attr 'city' =>
	is => "rw",
	isa => "Str",
	xml_required => 0,
	xml_name => "City",
	;

has_attr 'region' =>
	is => "rw",
	isa => "Str",
	xml_required => 0,
	xml_name => "Province",
	;

has_attr 'cc' =>
	is => "rw",
	isa => "Str",
	xml_required => 0,
	xml_name => "CountryCode",
	;

has_attr 'postcode' =>
	is => "rw",
	isa => "Str",
	xml_required => 0,
	xml_name => "PostalCode",
	;

with 'XML::SRS::Node';

use Moose::Util::TypeConstraints;

coerce __PACKAGE__
	=> from "HashRef"
	=> via { __PACKAGE__->new(%$_); };

1;

__END__

=head1 NAME

XML::SRS::Contact::Address - Class representing an SRS Address

=head1 DESCRIPTION

This class represents an SRS Phone number object.

=head1 ATTRIBUTES

Each attribute of this class has an accessor/mutator of the same name as
the attribute. Additionally, they can be passed as parameters to the
constructor.

=head2 city

Must be of type Str. Maps to the XML attribute 'City'

=head2 cc

Must be of type Str. Maps to the XML attribute 'CountryCode'

=head2 region

Must be of type Str. Maps to the XML attribute 'Province'

=head2 address1

Must be of type Str. Maps to the XML attribute 'Address1'

=head2 postcode

Must be of type Str. Maps to the XML attribute 'PostalCode'

=head2 address2

Must be of type Str. Maps to the XML attribute 'Address2'

=head1 METHODS

=head2 new(%params)

Construct a new XML::SRS::Request object. %params specifies the initial
values of the attributes.

=head1 COMPOSED OF

L<XML::SRS::Node>
