
package XML::SRS::Registrar::Update;
BEGIN {
  $XML::SRS::Registrar::Update::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;

has_attr 'name' =>
	is => "ro",
	isa => "Str",
	xml_name => "Name",
	xml_required => 0,
	;

has_attr 'account_reference' =>
	is => "ro",
	isa => "Str",
	xml_name => "AccRef",
	xml_required => 0,
	;

has_attr 'url' =>
	is => "ro",
	isa => "Str",
	xml_name => "URL",
	xml_required => 0,
	;

has_element 'contact_public' =>
	is => "rw",
	isa => "XML::SRS::Contact",
	xml_nodeName => "RegistrarPublicContact",
	coerce => 1,
	xml_required => 0,
	;

has_element 'contact_private' =>
	is => "rw",
	isa => "XML::SRS::Contact",
	xml_nodeName => "RegistrarSRSContact",
	coerce => 1,
	xml_required => 0,
	;

has_element 'contact_technical' =>
	is => "rw",
	isa => "XML::SRS::Contact",
	xml_nodeName => "DefaultTechnicalContact",
	coerce => 1,
	xml_required => 0,
	;

has_element 'keyring' =>
	is => "rw",
	isa => "XML::SRS::Keyring",
	xml_nodeName => "EncryptKeys",
	xml_required => 0,
	;

use XML::SRS::Password;
has_element 'epp_auth' =>
	is => "rw",
	isa => "XML::SRS::Password",
	xml_nodeName => "EPPAuth",
	coerce => 1,
	predicate => "has_epp_auth",
	xml_required => 0,
	;

has_element 'allowed_zones' =>
	is => "rw",
	isa => "XML::SRS::Zone::List",
	xml_nodeName => "Allowed2LDs",
	predicate => "has_allowed_zones",
	xml_required => 0,
	;

has_element 'roles' =>
	is => "rw",
	isa => "XML::SRS::Role::List",
	xml_nodeName => "Roles",
	predicate => "has_roles",
	xml_required => 0,
	;

has_element 'audit' =>
	is => "rw",
	isa => "XML::SRS::AuditDetails",
	xml_nodeName => "AuditDetails",
	predicate => "has_audit",
	xml_required => 0,
	;

sub root_element {"RegistrarUpdate"}
with 'XML::SRS::Action';

1;
