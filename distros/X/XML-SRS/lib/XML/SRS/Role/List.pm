
package XML::SRS::Role::List;
BEGIN {
  $XML::SRS::Role::List::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use XML::SRS::Role;

has_element 'roles' =>
	is => "rw",
	isa => "ArrayRef[XML::SRS::Role]",
	xml_nodeName => "Role",
	required => 1,
	;

with 'XML::SRS::Node';

1;
