
package XML::SRS::Date::Range;
BEGIN {
  $XML::SRS::Date::Range::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use Moose::Util::TypeConstraints;

use XML::SRS::TimeStamp;

has_element 'begin' =>
	is => "ro",
	isa => "XML::SRS::TimeStamp",
	xml_nodeName => "From",
	xml_required => 0,
	coerce => 1,
	;

has_element 'end' =>
	is => "ro",
	isa => "XML::SRS::TimeStamp",
	xml_nodeName => "To",
	xml_required => 0,
	coerce => 1,
	;

coerce __PACKAGE__
	=> from "HashRef"
	=> via { __PACKAGE__->new(%$_); };

with 'XML::SRS::Node';

1;
