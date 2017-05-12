
package XML::SRS::Zone;
BEGIN {
  $XML::SRS::Zone::VERSION = '0.09';
}   # aka "Allowed2LD"

use Moose;
use PRANG::Graph;
use XML::SRS::Types;

has_attr 'DomainName' =>
	is => "rw",
	isa => "XML::SRS::DomainName",
	;

with 'XML::SRS::Node';

1;
