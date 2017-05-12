
package XML::SRS::Domain;
BEGIN {
  $XML::SRS::Domain::VERSION = '0.09';
}
use Moose;
use PRANG::Graph;
use XML::SRS::Types;

has_attr 'name' =>
	is => "ro",
	isa => "XML::SRS::DomainName",
	xml_name => "DomainName",
	;

has_attr 'name_unicode' =>
	is => "ro",
	isa => "Str",
	xml_name => "DomainNameUnicode",
	xml_required => 0,	
	;
	
has_attr 'name_unicode_hex' =>
	is => "ro",
	isa => "Str",
	xml_name => "DomainNameUnicodeHex",
	xml_required => 0,
	;
	
has_attr 'name_language' =>
	is => "ro",
	isa => "Str",
	xml_name => "DomainNameLanguage",
	xml_required => 0,
	;

has_attr 'registrant_ref' =>
	is => "ro",
	isa => "XML::SRS::UID",
	xml_name => "RegistrantRef",
	xml_required => 0,
	;

has_attr 'registrar_name' =>
	is => "ro",
	isa => "Str",
	xml_name => "RegistrarName",
	xml_required => 0,
	;

has_attr 'status' =>
	is => "ro",
	isa => "Str",
	xml_name => "Status",
	xml_required => 0,
	;

sub is_available {
	my $self = shift;
	$self->status eq "Available" ? 1 : 0;
}

has_attr 'delegate' =>
	is => "ro",
	isa => "XML::SRS::Boolean",
	xml_name => "Delegate",
	xml_required => 0,
	;

has_attr 'term' =>
	is => "ro",
	isa => "XML::SRS::Term",
	xml_name => "Term",
	xml_required => 0,
	;

has_attr 'registrar_id' =>
	is => "ro",
	isa => "XML::SRS::Number",
	xml_name => "RegistrarId",
	xml_required => 0,
	;

has_attr 'UDAI' =>
	is => "ro",
	isa => 'Str',
	xml_name => "UDAI",
	xml_required => 0,
	;

# elements
has_element 'nameservers' =>
	is => 'ro',
	isa => 'XML::SRS::Server::List',
	xml_nodeName => 'NameServers',
	xml_required => 0,
	;
	
has_element "dns_sec" =>
	is => "rw",
	isa => "XML::SRS::DS::List",
	xml_nodeName => "DNSSEC",
	xml_required => 0,
	;

has_element 'contact_registrant' =>
	is => 'ro',
	isa => 'XML::SRS::Contact',
	xml_nodeName => 'RegistrantContact',
	xml_required => 0,
	coerce => 1,
	;

has_element 'contact_registrar_public' =>
	is => 'ro',
	isa => 'XML::SRS::Contact',
	xml_nodeName => 'RegistrarPublicContact',
	xml_required => 0,
	coerce => 1,
	;

has_element 'contact_admin' =>
	is => 'ro',
	isa => 'XML::SRS::Contact',
	xml_nodeName => 'AdminContact',
	xml_required => 0,
	coerce => 1,
	;

has_element 'contact_technical' =>
	is => 'ro',
	isa => 'XML::SRS::Contact',
	xml_nodeName => 'TechnicalContact',
	xml_required => 0,
	coerce => 1,
	;

has_element 'billed_until' =>
	is => 'ro',
	isa => 'XML::SRS::TimeStamp',
	xml_required => 0,
	xml_nodeName => 'BilledUntil',
	;

has_element 'registered_date' =>
	is => 'ro',
	isa => 'XML::SRS::TimeStamp',
	xml_required => 0,
	xml_nodeName => 'RegisteredDate',
	;

has_element 'cancelled_date' =>
	is => 'ro',
	isa => 'XML::SRS::TimeStamp',
	xml_required => 0,
	xml_nodeName => 'CancelledDate',
	;

has_element 'locked_date' =>
	is => 'ro',
	isa => 'XML::SRS::TimeStamp',
	xml_required => 0,
	xml_nodeName => 'LockedDate',
	;

has_element 'default_contacts' =>
	is => 'ro',
	isa => 'XML::SRS::DefaultContacts',
	xml_required => 0,
	xml_nodeName => 'DefaultContacts',
	;

has_element 'audit' =>
	is => "rw",
	isa => "XML::SRS::AuditDetails",
	xml_nodeName => "AuditDetails",
	predicate => "has_audit",
	;

sub root_element {
	"Domain";
}
with 'XML::SRS::ActionResponse';

1;

__END__

=head1 NAME

XML::SRS::Domain - Class representing an SRS Domain response object

=head1 DESCRIPTION

This class represents an SRS Domain object, i.e. objects returned from
a request involving domains, such as 'Whois'. The root XML element of this
class is 'Domain'.

=head1 ATTRIBUTES

Each attribute of this class has an accessor/mutator of the same name as
the attribute. Additionally, they can be passed as parameters to the
constructor.

=head2 default_contacts

Must be of type XML::SRS::DefaultContacts. Maps to the XML element 'DefaultContacts'

=head2 locked_date

Must be of type XML::SRS::TimeStamp. Maps to the XML element 'LockedDate'

=head2 contact_technical

Must be of type XML::SRS::Contact. Maps to the XML element 'TechnicalContact'

=head2 dns_sec

Must be of type XML::SRS::DS::List. Maps to the XML element 'DNSSEC'

=head2 status

Must be of type Str. Maps to the XML attribute 'Status'

=head2 name_unicode

Must be of type Str. Maps to the XML attribute 'DomainNameUnicode'

=head2 name_language

Must be of type Str. Maps to the XML attribute 'DomainNameLanguage'

=head2 term

Must be of type XML::SRS::Term. Maps to the XML attribute 'Term'

=head2 UDAI

Must be of type Str. Maps to the XML attribute 'UDAI'

=head2 registrar_name

Must be of type Str. Maps to the XML attribute 'RegistrarName'

=head2 delegate

Must be of type XML::SRS::Boolean. Maps to the XML attribute 'Delegate'

=head2 registrant_ref

Must be of type XML::SRS::UID. Maps to the XML attribute 'RegistrantRef'

=head2 contact_registrar_public

Must be of type XML::SRS::Contact. Maps to the XML element 'RegistrarPublicContact'

=head2 contact_admin

Must be of type XML::SRS::Contact. Maps to the XML element 'AdminContact'

=head2 name_unicode_hex

Must be of type Str. Maps to the XML attribute 'DomainNameUnicodeHex'

=head2 contact_registrant

Must be of type XML::SRS::Contact. Maps to the XML element 'RegistrantContact'

=head2 name

Must be of type XML::SRS::DomainName. Maps to the XML attribute 'DomainName'

=head2 nameservers

Must be of type XML::SRS::Server::List. Maps to the XML element 'NameServers'

=head2 registered_date

Must be of type XML::SRS::TimeStamp. Maps to the XML element 'RegisteredDate'

=head2 registrar_id

Must be of type XML::SRS::Number. Maps to the XML attribute 'RegistrarId'

=head2 audit

Must be of type XML::SRS::AuditDetails. Maps to the XML element 'AuditDetails'

=head2 billed_until

Must be of type XML::SRS::TimeStamp. Maps to the XML element 'BilledUntil'

=head2 cancelled_date

Must be of type XML::SRS::TimeStamp. Maps to the XML element 'CancelledDate'

=head1 METHODS

=head2 new(%params)

Construct a new XML::SRS::Request object. %params specifies the initial
values of the attributes.

=head1 COMPOSED OF

L<XML::SRS::ActionResponse>

