
package XML::SRS::Response;
BEGIN {
  $XML::SRS::Response::VERSION = '0.09';
}

use Moose;
use Moose::Util::TypeConstraints;
use PRANG::Graph;
use XML::SRS::Types;
use XML::SRS::Result;
use XML::SRS::Error;

has_attr "registrar_id" =>
	is => "ro",
	isa => "XML::SRS::RegistrarId",
	xml_required => 0,
	xml_name => "RegistrarId",
	;

has_element "results" =>
	is => "ro",
	isa => "ArrayRef[XML::SRS::Result|XML::SRS::Error]",
	xml_nodeName => {
	Response => "XML::SRS::Result",
	Error => "XML::SRS::Error",
	},
	required => 1,
	;

sub root_element {"NZSRSResponse"}
with 'XML::SRS', 'XML::SRS::Node', 'XML::SRS::Version';

sub BUILDARGS {
	my $inv = shift;
	my %args = @_;
	if ( $args{version} ) {
		%args = (%args, $inv->buildargs_version($args{version}));
	}
	\%args;
}

1;

__END__

=head1 NAME

XML::SRS::Response - Top level SRS response class

=head1 SYNOPSIS

  my $response = XML::SRS->parse($xml);
  
  my $results = $response->results;
  
=head1 DESCRIPTION

This class represents the top level of an SRS response. If you parse an entire
SRS XML response (via XML::SRS->parse()), the object returned will be an 
instance of this class (unless it was a top level error, in which case it will
be an L<XML::SRS::Error>). The root XML element of this class is 'NZSRSResponse'.

=head1 ATTRIBUTES

Each attribute of this class has an accessor/mutator of the same name as
the attribute. Additionally, they can be passed as parameters to the
constructor.

=head2 registrar_id

Optional attribute to containing the effective registrar id of the request.
Maps to the RegistrarId XML attribute.

=head2 results

Required attribute. Accepts an array ref of objects that compose the
XML::SRS::Result or XML::SRS::Error objects. These correspond to
responses to the individual actions of the original request. For example,
if a request containing two Whois transactions was sent, the 'results'
array ref will contain two XML::SRS::Result objects (assuming the requests
were successful).

This maps to the Response XML element. However, as this clashes with the
top level 'Response' (i.e. 'NZSRSResponse' XML element), it has been
renamed 'result'. 

=head1 METHODS

=head2 new(%params)

Construct a new XML::SRS::Request object. %params specifies the initial
values of the attributes.
  
=head1 COMPOSED OF

L<XML::SRS>, L<XML::SRS::Node>, L<XML::SRS::Version>


