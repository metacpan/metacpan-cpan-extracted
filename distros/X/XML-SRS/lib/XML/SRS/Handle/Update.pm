package XML::SRS::Handle::Update;
BEGIN {
  $XML::SRS::Handle::Update::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use XML::SRS::Types;
use XML::SRS::Server::List;
use PRANG::XMLSchema::Types;

# attributes
has_attr 'handle_id' =>
	is => "ro",
	isa => "Str",
	xml_name => "HandleId",
	predicate => "has_handle_id",
	;

has_attr 'name' =>
	is => "ro",
	isa => "Str",
	xml_name => "Name",
	xml_required => 0,
	predicate => "has_name",
	;

has_attr 'email' =>
	is => "ro",
	isa => "Str",
	xml_name => "Email",
	xml_required => 0,
	predicate => "has_email",
	;

has_attr 'delete' =>
	is => 'rw',
	isa => 'PRANG::XMLSchema::boolean',
	xml_name => 'Delete',
	xml_required => 0,
	;

# elements
has_element 'address' =>
	is => "ro",
	isa => "XML::SRS::Contact::Address",
	xml_nodeName => "PostalAddress",
	predicate => "has_address",
	xml_required => 0,
	coerce => 1,
	;

has_element 'phone' =>
	is => "ro",
	isa => "XML::SRS::Contact::PSTN",
	predicate => "has_phone",
	xml_nodeName => "Phone",
	xml_required => 0,
	coerce => 1,
	;

has_element 'fax' =>
	is => "ro",
	isa => "XML::SRS::Contact::PSTN",
	predicate => "has_fax",
	xml_nodeName => "Fax",
	xml_required => 0,
	coerce => 1,
	;

has_element 'audit' =>
	is => "rw",
	isa => "XML::SRS::AuditDetails",
	xml_nodeName => "AuditDetails",
	xml_required => 0,
	predicate => "has_audit",
	;

with 'XML::SRS::Audit';

sub root_element {'HandleUpdate'}
with 'XML::SRS::Action';

1;
