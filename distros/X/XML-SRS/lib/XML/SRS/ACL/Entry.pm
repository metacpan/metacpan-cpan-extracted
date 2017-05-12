
package XML::SRS::ACL::Entry;
BEGIN {
  $XML::SRS::ACL::Entry::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;

has_attr 'Address' =>
	is => "ro",
	isa => "Str",   # actually an IPv4/IPv6 address/network
	xml_required => 0,
	;

has_attr 'DomainName' =>
	is => "ro",
	isa => "Str",   # actually an valid domain name
	xml_required => 0,
	;

has_attr 'RegistrarId' =>
	is => "ro",
	isa => "XML::SRS::RegistrarId",
	xml_required => 0,
	;

has_attr 'Comment' =>
	is => "ro",
	isa => "Str",
	xml_required => 0,
	;

has_element 'effective' =>
	is => "ro",
	isa => "XML::SRS::TimeStamp",
	xml_nodeName => "EffectiveDate",
	predicate => "has_effective",
	;

with 'XML::SRS::Node';

1;
