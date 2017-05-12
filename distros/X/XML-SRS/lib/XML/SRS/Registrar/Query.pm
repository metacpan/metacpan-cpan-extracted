
package XML::SRS::Registrar::Query;
BEGIN {
  $XML::SRS::Registrar::Query::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use XML::SRS::Types;

sub root_element {
	"RegistrarDetailsQry";
}

has_attr "registrar_id" =>
	is => "ro",
	isa => "Str",
	xml_name => "RegistrarId",
	xml_required => 0,
	;

has_attr "name_filter" =>
	is => "ro",
	isa => "Str",
	xml_name => "NameFilter",
	xml_required => 0,
	;

has_element "when" =>
	is => "ro",
	isa => "ArrayRef[XML::SRS::Date::Range]",
	xml_nodeName => "ResultDateRange",
	xml_required => 0,
	;

with 'XML::SRS::Query';

1;
