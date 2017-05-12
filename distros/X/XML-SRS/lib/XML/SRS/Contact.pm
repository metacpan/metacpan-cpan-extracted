
package XML::SRS::Contact;
BEGIN {
  $XML::SRS::Contact::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use XML::SRS::Contact::Address;
use XML::SRS::Contact::PSTN;
use XML::SRS::Types;

# handles
has_attr 'handle_id' =>
	is => "ro",
	isa => "XML::SRS::HandleId",
	xml_name => "HandleId",
	predicate => "has_handle_id",
	;

has_attr 'action_id' =>
	is => "rw",
	isa => "XML::SRS::UID",
	xml_name => 'ActionId',
	xml_required => 0,
	predicate => "has_action_id",
	;

# attributes
has_attr 'name' =>
	is => "ro",
	isa => "Str",
	xml_name => "Name",
	predicate => "has_name",
	;

has_attr 'email' =>
	is => "ro",
	isa => "XML::SRS::Email",
	xml_name => "Email",
	predicate => "has_email",
	;

# elements
has_element 'address' =>
	is => "ro",
	isa => "XML::SRS::Contact::Address",
	xml_nodeName => "PostalAddress",
	predicate => "has_address",
	coerce => 1,
	xml_required => 0,
	;

has_element 'phone' =>
	is => "ro",
	isa => "XML::SRS::Contact::PSTN",
	predicate => "has_phone",
	xml_nodeName => "Phone",
	coerce => 1,
	xml_required => 0,
	;

has_element 'fax' =>
	is => "ro",
	isa => "XML::SRS::Contact::PSTN",
	predicate => "has_fax",
	xml_nodeName => "Fax",
	coerce => 1,
	xml_required => 0,
	;

with 'XML::SRS::Node';

use Moose::Util::TypeConstraints;
coerce __PACKAGE__
	=> from "HashRef"
	=> via { __PACKAGE__->new(%$_); };
		
1;

__END__

=head1 NAME

XML::SRS::Contact - Class representing an SRS Contact object

=head1 DESCRIPTION

This class represents an SRS Contact object.

=head1 ATTRIBUTES

Each attribute of this class has an accessor/mutator of the same name as
the attribute. Additionally, they can be passed as parameters to the
constructor.

=head2 email

Must be of type XML::SRS::Email. Maps to the XML attribute 'Email'

=head2 handle_id

Must be of type XML::SRS::HandleId. Maps to the XML attribute 'HandleId'

=head2 fax

Must be of type XML::SRS::Contact::PSTN. Maps to the XML element 'Fax'

=head2 name

Must be of type Str. Maps to the XML attribute 'Name'

=head2 address

Must be of type XML::SRS::Contact::Address. Maps to the XML element 'PostalAddress'

=head2 action_id

Must be of type XML::SRS::UID. Maps to the XML attribute 'ActionId'

=head2 phone

Must be of type XML::SRS::Contact::PSTN. Maps to the XML element 'Phone'

=head1 METHODS

=head2 new(%params)

Construct a new XML::SRS::Request object. %params specifies the initial
values of the attributes.
  
=head1 COMPOSED OF

L<XML::SRS::Node>


