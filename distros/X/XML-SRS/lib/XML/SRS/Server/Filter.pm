
package XML::SRS::Server::Filter;
BEGIN {
  $XML::SRS::Server::Filter::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use XML::SRS::Types;

use Moose::Util::TypeConstraints;

has_attr 'fqdn' =>
	is => "ro",
	isa => "XML::SRS::DomainName",
	xml_name => "FQDN",
	xml_required => 0,
	;

has_attr 'ipv4_addr' =>
	is => "ro",
	isa => "XML::SRS::IPv4",
	xml_name => "IP4Addr",
	xml_required => 0,
	;

has_attr 'ipv6_addr' =>
	is => "ro",
	isa => "XML::SRS::IPv6",
	xml_name => "IP6Addr",
	xml_required => 0,
	;

with 'XML::SRS::Node';

1;
