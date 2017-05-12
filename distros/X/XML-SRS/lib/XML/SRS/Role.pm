
package XML::SRS::Role;
BEGIN {
  $XML::SRS::Role::VERSION = '0.09';
}   # aka "Allowed2LD"

use Moose;
use PRANG::Graph;
use XML::SRS::Types;

has_attr 'RoleName' =>
	is => "rw",
	isa => "XML::SRS::RoleName",
	;

with 'XML::SRS::Node';

1;
