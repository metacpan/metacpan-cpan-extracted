use strict;
use warnings;
use src::com::zoho::crm::api::util::Converter;

package XMLConverter;
use Moose;

extends 'Converter';


sub form_request
{
    my ($self,$request_object,$pack,$instance_number)= @_;
}
sub append_to_request
{
    my ($self,$request_base,$request_object) = @_;
}

sub get_wrapped_response
{
    my ($self,$response,$pack)= @_;
}

sub get_response
{
    my ($self,$response,$pack)= @_;
}


=head1 NAME

com::zoho::crm::api::util::XMLConverter - This class processes the API response object to the POJO object and POJO object to an XML object.

=cut

1;
