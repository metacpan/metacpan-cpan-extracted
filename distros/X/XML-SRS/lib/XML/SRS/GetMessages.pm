
package XML::SRS::GetMessages;
BEGIN {
  $XML::SRS::GetMessages::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use XML::SRS::Types;

sub root_element {
	"GetMessages";
}

has_attr 'originating_registrar' =>
	is => "ro",
	isa => "Str",
	xml_name => "OriginatingRegistrarId",
	;

has_attr 'recipient_registrar' =>
	is => "ro",
	isa => "Str",
	xml_name => "RecipientRegistrarId",
	;

has_attr 'queue' =>
	is => "ro",
	isa => "Bool",
	xml_name => "QueueMode",
	;

has_element "when" =>
	is => "ro",
	isa => "ArrayRef[XML::SRS::Date::Range]",
	xml_nodeName => "TransDateRange",
	xml_required => 0,
	;

has_attr 'max_results' =>
	is => 'ro',
	isa => 'XML::SRS::Number',
	xml_name => 'MaxResults',
	xml_required => 0,
	;

use XML::SRS::GetMessages::TypeFilter;
use Moose::Util::TypeConstraints;

# For some reason, we have to create this subtype
#  Supposedly, it should work without it if we define the coercion
#  after the 'has_element', but that generated a warning. Possible Moose bug?
subtype 'TypeFilterArrayRef' =>
    as 'ArrayRef[XML::SRS::GetMessages::TypeFilter]';

coerce 'TypeFilterArrayRef'
	=> from "ArrayRef[Str]"
	=> via {
	[   map {
			XML::SRS::GetMessages::TypeFilter->new(
				Type => $_,
			);
			} @$_
	];
};

has_element "type_filter" =>
	is => "ro",
	isa => "TypeFilterArrayRef",
	xml_min => 0,
	xml_nodeName => "TypeFilter",
	coerce => 1,
	;

with 'XML::SRS::Query';
1;
