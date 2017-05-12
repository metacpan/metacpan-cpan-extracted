
package XML::SRS::Server;
BEGIN {
  $XML::SRS::Server::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use XML::SRS::Types;

has_attr 'fqdn' =>
	is => "ro",
	isa => "XML::SRS::DomainName",
	xml_name => "FQDN",
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

__END__

=head1 NAME

XML::SRS::Server - Class representing an SRS name server

=head1 DESCRIPTION

This class represents an SRS name server

=head1 ATTRIBUTES

Each attribute of this class has an accessor/mutator of the same name as
the attribute. Additionally, they can be passed as parameters to the
constructor.

=head2 fqdn

Must be of type XML::SRS::DomainName. Maps to the XML attribute 'FQDN'

=head2 ipv6_addr

Must be of type XML::SRS::IPv6. Maps to the XML attribute 'IP6Addr'

=head2 ipv4_addr

Must be of type XML::SRS::IPv4. Maps to the XML attribute 'IP4Addr'

=head1 METHODS

=head2 new(%params)

Construct a new XML::SRS::Request object. %params specifies the initial
values of the attributes.

=head1 COMPOSED OF

L<XML::SRS::Node>
