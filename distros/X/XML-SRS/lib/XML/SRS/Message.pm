
package XML::SRS::Message;
BEGIN {
  $XML::SRS::Message::VERSION = '0.09';
}

# response to a GetMessages QueueMode=1

use Moose;
use PRANG::Graph;

has_attr 'unacked' =>
	is => "rw",
	isa => "Int",
	required => 0,
	xml_name => "Remaining",
	;

has_element 'result' =>
	is => "rw",
	isa => "XML::SRS::Result",
	xml_nodeName => "Response",
	required => 1,
	;

sub root_element {"Message"}
with 'XML::SRS::ActionResponse', 'XML::SRS::Node';

1;
