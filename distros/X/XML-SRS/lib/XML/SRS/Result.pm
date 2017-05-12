
# this is called 'Response' in the XML, but we call it 'Result' to not clash
# with 'Response', which is actually 'NZSRSResponse'
package XML::SRS::Result;
BEGIN {
  $XML::SRS::Result::VERSION = '0.09';
}

use Carp;
use Moose;
use PRANG::Graph;
use XML::SRS::Types;
use Moose::Util::TypeConstraints;

has_attr 'action' =>
	is => "ro",
	isa => "XML::SRS::ActionEtc",
	required => 1,
	xml_name => "Action",
	;

has_attr 'fe_id' =>
	is => "ro",
	isa => "XML::SRS::Number",
	required => 1,
	xml_name => "FeId",
	;

has_attr 'unique_id' =>
	is => "ro",
	isa => "XML::SRS::Number",
	required => 1,
	xml_name => "FeSeq",
	;

# for identifying a result within a unique transaction
has 'part' =>
	is => "rw",
	isa => "Int",
	;

sub result_id {
	my $self = shift;
	$self->fe_id.",".$self->unique_id
		.($self->part ? ("[".$self->part."]") : "");
}

has_attr 'by_id' =>
	is => "ro",
	isa => "XML::SRS::RegistrarId",
	required => 1,
	xml_name => "OrigRegistrarId",
	;

has_attr 'for_id' =>
	is => "ro",
	isa => "XML::SRS::RegistrarId",
	xml_required => 0,
	xml_name => "RecipientRegistrarId",
	;

has_attr 'client_id' =>
	is => "ro",
	isa => "XML::SRS::UID",
	xml_required => 0,
	xml_name => "TransId",
	;

has_attr 'rows' =>
	is => "ro",
	isa => "XML::SRS::Number",
	xml_required => 0,
	xml_name => "Rows",
	;

has_attr 'has_more_rows' =>
	is => "ro",
	isa => "XML::SRS::Boolean",
	coerce => 1,
	xml_required => 0,
	xml_name => "MoreRowsAvailable",
	;

has_attr 'count' =>
	is => "ro",
	isa => "XML::SRS::Number",
	xml_required => 0,
	xml_name => "Count",
	;

subtype 'XML::SRS::timeStampType'
	=> as "XML::SRS::TimeStamp",
	;

coerce "XML::SRS::timeStampType"
	=> from TimestampTZ
	=> via {
	XML::SRS::TimeStamp->new(timestamptz => $_);
	};

has_element 'server_time' =>
	is => "ro",
	isa => "XML::SRS::timeStampType",
	coerce => 1,
	xml_nodeName => "FeTimeStamp",
	required => 1,
	;

use MooseX::Timestamp;
use MooseX::TimestampTZ;



# this is for GetMessages responses, so let's call it messages
has_element 'messages' =>
	is => "ro",
	isa => "ArrayRef[XML::SRS::Result]",
	xml_nodeName => "Response",
	xml_min => 0,
	;

has_element 'responses' =>
	is => "ro",
	isa => "ArrayRef[XML::SRS::ActionResponse]",
	xml_required => 0,
	lazy => 1,
	default => sub {
	my $self = shift;
	($self->has_response and defined $self->response)
		? [ $self->response ] : [];
	},
	;

has 'response' =>
	is => "ro",
	isa => "Maybe[XML::SRS::ActionResponse]",
	predicate => "has_response",
	lazy => 1,
	default => sub {
	my $self = shift;
	my $rs_a = $self->responses;
	if ( $rs_a and @$rs_a ) {
		if ( @$rs_a > 1 ) {
			confess "result has multiple responses";
		}
		else {
			$rs_a->[0];
		}
	}
	else {
		undef;
	}
	},
	;

with 'XML::SRS::Node';

1;

__END__

=head1 NAME

XML::SRS::Result - Represents the result of an individual SRS query or action

=head1 SYNOPSIS

  my $response = XML::SRS->parse($xml);
  
  my $results = $response->results;
  
  # If the response was for a transaction involving domains, get the
  #  list of domain records returned in the response (as an array ref)
  my $domains = $results->responses;

=head1 DESCRIPTION

This class represents the response to an individual transaction in an
SRS request. Each response may have its own list of 'responses'. For
example, a DomainDetailsQry might return multiple domains. These domains
can be obtained via the 'responses' attribute of this class (see below).

The root XML element of this class is 'Response' XML element. However, as
this clashes with the top level 'Response' (i.e. 'NZSRSResponse' XML element),
it has been renamed 'Result'. 

=head1 ATTRIBUTES

Each attribute of this class has an accessor/mutator of the same name as
the attribute. Additionally, they can be passed as parameters to the
constructor.

=head2 responses

An array ref of objects that compose the L<XML::SRS::ActionResponse> role.
This corresponds to the responses to the indvidual transactions of a request.
The objects returned here will be in a class dependent on the response type,
for example, a DomainDetailsQry will return 0 or more L<XML::SRS::Domain>
objects, while a HandleDetailsQry will return 0 or more L<XML::SRS::Handle>
objects. See the POD for each individual transaction for details on what type
of response to expect.

=head2 response

Returns the first response in the list, or undef if there are none. It's a
fairly common case to only expect one response, so this attribute is often
useful.

=head2 messages

The GetMessages transaction is somewhat different, in that it returns a list
of results (i.e. XML::SRS::Result objects), rather than responses. This
attribute contains those result objects.

=head2 action

The name of the 'action' this result relates to. For example 'Whois'
if this is the result of a 'Whois' request. Maps to the 'Action' XML
attribute.

=head2 fe_id

The front end service id of the request. Maps to the 'FeId' XML attribute.

=head2 unique_id

The front end sequence number of the request. Maps to the 'FeSeq' XML 
attribute.

=head2 by_id

Maps to the 'OrigRegistrarId' XML attribute

=head2 for_id

Maps to the 'RecipientRegistrarId' XML attribute

=head2 client_id

Maps to the 'TransId' XML attribute

=head2 rows

Maps to the 'Rows' XML attribute

=head2 has_more_rows

Maps to the 'MoreRowsAvailable' XML attribute

=head2 count

Maps to the 'Count' XML attribute

=head1 METHODS

=head2 new(%params)

Construct a new XML::SRS::Request object. %params specifies the initial
values of the attributes.

=head1 COMPOSED OF

L<XML::SRS::Node>
