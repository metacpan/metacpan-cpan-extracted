
package XML::SRS::AuditDetails;
BEGIN {
  $XML::SRS::AuditDetails::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use XML::SRS::Types;
use XML::SRS::Date::Range;

has_attr 'registrar_id' =>
	is => "ro",
	isa => "XML::SRS::RegistrarId",
	xml_name => "RegistrarId",
	xml_required => 0,
	;

has_attr 'action_id' =>
	is => "ro",
	isa => "XML::SRS::UID",
	xml_name => "ActionId",
	xml_required => 0,
	;

has_element 'when' =>
	is => "ro",
	isa => "XML::SRS::Date::Range",
	xml_required => 0,
	xml_nodeName => "AuditTime",
	;

has_element 'comment' =>
	is => "ro",
	isa => "Str",
	xml_required => 0,
	xml_nodeName => "AuditText",
	;

with 'XML::SRS::Node';
1;
