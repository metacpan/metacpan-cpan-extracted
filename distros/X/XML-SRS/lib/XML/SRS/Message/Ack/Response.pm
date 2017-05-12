package XML::SRS::Message::Ack::Response;
BEGIN {
  $XML::SRS::Message::Ack::Response::VERSION = '0.09';
}

# response to a GetMessages QueueMode=1

use Moose;
use PRANG::Graph;

has_attr 'registrar_id' =>
	is => "rw",
	isa => "Str",
	isa => "XML::SRS::UID",
	required => 1,
	xml_name => "OriginatingRegistrarId",
	;

has_attr 'tx_id' =>
	is => "ro",
	isa => "XML::SRS::UID",
	xml_name => "TransId",
	required => 1,
	;

has_attr 'remaining' =>
	is => "ro",
	isa => "Int",
	xml_name => "Remaining",
	;

sub root_element {"AckResponse"}
with 'XML::SRS::ActionResponse', 'XML::SRS::Node';

1;

