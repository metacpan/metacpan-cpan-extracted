
package XML::SRS::Server::List;
BEGIN {
  $XML::SRS::Server::List::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use XML::SRS::Zone;

use Moose::Util::TypeConstraints;

use XML::SRS::Server;
has_element 'nameservers' =>
	is => "rw",
	isa => "ArrayRef[XML::SRS::Server]",
	xml_nodeName => "Server",
	required => 1,
	;

coerce __PACKAGE__
	=> from 'ArrayRef[Str]'
	=> via {
	__PACKAGE__->new(
		nameservers => [
			map {
				XML::SRS::Server->new( fqdn => $_ );
				} @$_
		],
	);
};

coerce __PACKAGE__
	=> from 'ArrayRef[HashRef]'
	=> via {
	__PACKAGE__->new(
		nameservers => [
			map {
				XML::SRS::Server->new($_);
				} @$_
		],
	);
};

with 'XML::SRS::Node';

1;

__END__

=head1 NAME

XML::SRS::Server::List - Class representing an SRS name server list

=head1 DESCRIPTION

This class represents an SRS name server list

=head1 ATTRIBUTES

Each attribute of this class has an accessor/mutator of the same name as
the attribute. Additionally, they can be passed as parameters to the
constructor.

=head2 nameservers

Required. Returns an ArrayRef of XML::SRS::Server objects.
Maps to the XML element 'Server'.

=head1 METHODS

=head2 new(%params)

Construct a new XML::SRS::Request object. %params specifies the initial
values of the attributes.

=head1 COMPOSED OF

L<XML::SRS::Node>
