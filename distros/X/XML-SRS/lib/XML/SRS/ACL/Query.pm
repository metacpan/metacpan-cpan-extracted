
package XML::SRS::ACL::Query;
BEGIN {
  $XML::SRS::ACL::Query::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use Moose::Util::TypeConstraints;

sub root_element {
	"AccessControlListQry";
}

has_attr "Resource" =>
	is => "ro",
	isa => "Str",
	;

has_attr "List" =>
	is => "ro",
	isa => "Str",
	;

has_attr "Type" =>
	is => "ro",
	isa => "Str",
	;

has_attr "FullResult" =>
	is => "ro",
	isa => "Bool",
	coerce => 1,
	default => 0,
	;

has "filter_types" =>
	is => "ro",
	isa => "ArrayRef[Str]",
	default => sub { [] },
	;

has_element "filter" =>
	is => "ro",
	isa => "ArrayRef[Str]",
	xml_nodeName => {
	DomainNameFilter => "Str",
	RegistrarIdFilter => "Str",
	AddressFilter => "Str",
	},
	xml_nodeName_attr => "filter_types",
	;

with 'XML::SRS::Query';

1;
