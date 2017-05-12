package WebService::Class::AbstractHTTPandXMLRPCRequestClass;
use warnings;
use strict;
use base qw(WebService::Class::AbstractClass);
use WebService::RequestAPI::HTTPRequestAPI;
use WebService::RequestAPI::XMLRPCRequestAPI;
__PACKAGE__->mk_classdata('request_api_http');
__PACKAGE__->mk_classdata('request_api_xmlrpc');

sub init{
	my $self = shift;
	$self->SUPER::init(@_);
	$self->request_api_http(new WebService::RequestAPI::HTTPRequestAPI(@_));
	$self->request_api_xmlrpc(new WebService::RequestAPI::XMLRPCRequestAPI(@_));
}





1; 
