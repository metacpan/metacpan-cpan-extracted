
package XML::SRS::Request;
BEGIN {
  $XML::SRS::Request::VERSION = '0.09';
}

use Moose;
use Moose::Util::TypeConstraints;
use PRANG::Graph;

use XML::SRS::Types;

use XML::SRS::Query;
use XML::SRS::Action;
use XML::SRS::ActionResponse;

has_attr "registrar_id" =>
	is => "ro",
	isa => "XML::SRS::RegistrarId",
	xml_name => "RegistrarId",
	xml_required => 0,
	;

role_type 'XML::SRS::Action';
role_type 'XML::SRS::Query';

has_element "requests" =>
	is => "ro",
	isa => "ArrayRef[XML::SRS::Action|XML::SRS::Query]",
	required => 1,
	;

sub root_element {"NZSRSRequest"}
with 'XML::SRS', "XML::SRS::Version";

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

XML::SRS::Request - Top level SRS request class

=head1 SYNOPSIS

  my $request = XML::SRS::Request->new(
      registrar_id => 555,
      requests => \@requests,
  );
  
  $request->to_xml();


=head1 DESCRIPTION

This class represents the top level of an SRS request. It can be used to
construct an XML document suitable for sending to an SRS server (such as
the .nz Domain registry system). The root XML element of this
class is 'NZSRSRequest'.

=head1 ATTRIBUTES

Each attribute of this class has an accessor/mutator of the same name as
the attribute. Additionally, they can be passed as parameters to the
constructor.

=head2 registrar_id

Optional attribute to specify the effective registrar id of the request.
Maps to the RegistrarId XML attribute.

=head2 requests

Required attribute. Accepts an array ref of objects that compose the
XML::SRS::Action or XML::SRS::Query roles. This equates to a list of
SRS transaction objects, i.e. objects representing Whois, DomainCreate,
etc.

=head1 METHODS

=head2 new(%params)

Construct a new XML::SRS::Request object. %params specifies the initial
values of the attributes.

=head1 COMPOSED OF

L<XML::SRS>, L<XML::SRS::Version>