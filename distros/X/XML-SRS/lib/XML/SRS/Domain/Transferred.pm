
package XML::SRS::Domain::Transferred;
BEGIN {
  $XML::SRS::Domain::Transferred::VERSION = '0.09';
}
use Moose;
use PRANG::Graph;
use XML::SRS::Types;

has_attr "registrar_name" =>
	is => "ro",
	isa => "Str",
	xml_name => "RegistrarName",
	;

with "XML::SRS::TimeStamp::Role";

sub root_element {
	"DomainTransfer";
}

has_element "TransferredDomain" =>
	is => "ro",
	isa => "XML::SRS::DomainName",
	;

with 'XML::SRS::ActionResponse';

1;
