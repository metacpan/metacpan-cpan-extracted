
package XML::SRS::UDAIValid;
BEGIN {
  $XML::SRS::UDAIValid::VERSION = '0.09';
}
use Moose;
use PRANG::Graph;
use XML::SRS::Types;

# attributes
has_attr 'valid' =>
	is => "ro",
	isa => "XML::SRS::Boolean",
	xml_name => "Valid",
	;

# elements
# (none)

sub root_element {'UDAIValid'}

with 'XML::SRS::ActionResponse';

1;
