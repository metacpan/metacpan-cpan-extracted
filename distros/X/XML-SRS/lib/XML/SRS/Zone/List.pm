
package XML::SRS::Zone::List;
BEGIN {
  $XML::SRS::Zone::List::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use XML::SRS::Zone;

has_element 'zones' =>
	is => "rw",
	isa => "ArrayRef[XML::SRS::Zone]",
	xml_nodeName => "SecondLD",
	required => 1,
	;

with 'XML::SRS::Node';

1;
