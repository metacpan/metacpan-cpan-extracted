
package XML::SRS::FieldList;
BEGIN {
  $XML::SRS::FieldList::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;

use Moose::Util::TypeConstraints;

has_attr 'status' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'Status',
	;

has_attr 'name_servers' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'NameServers',
	;
	
has_attr 'dns_sec' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'DNSSEC',
	;

has_attr 'registrant_contact' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'RegistrantContact',
	;

has_attr 'registered_date' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'RegisteredDate',
	;

has_attr 'admin_contact' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'AdminContact',
	;

has_attr 'technical_contact' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'TechnicalContact',
	;

has_attr 'locked_date' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'LockedDate',
	;

has_attr 'delegate' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'Delegate',
	;

has_attr 'registrar_id' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'RegistrarId',
	;

has_attr 'registrar_name' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'RegistrarName',
	;

has_attr 'registrant_ref' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'RegistrantRef',
	;

has_attr 'last_action_id' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'LastActionId',
	;

has_attr 'changed_by_registrar_id' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'ChangedByRegistrarId',
	;

has_attr 'term' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'Term',
	;

has_attr 'billed_until' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'BilledUntil',
	;

has_attr 'cancelled_date' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'CancelledDate',
	;

has_attr 'audit_text' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'AuditText',
	;

has_attr 'effective_from' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'EffectiveFrom',
	;

has_attr 'default_contacts' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_required => 0,
	xml_name => 'DefaultContacts',
	;

with 'XML::SRS::Node';

coerce __PACKAGE__
	=> from 'ArrayRef'
	=> via {
    	my %params = map { $_ => 1 } @{$_[0]}; 

    	__PACKAGE__->new(
    		%params,
    	);
    };

1;
