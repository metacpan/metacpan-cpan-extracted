package WebService::RequestAPI::XMLRPCRequestAPI;
use strict;
use XMLRPC::Lite;
use JSON;
use utf8;
use base qw(WebService::RequestAPI::AbstractRequestAPI);


sub _request{
	my $self = shift;
	my $method = shift;
	my $url = shift;
	my @args = @_;
	$self->result(XMLRPC::Lite->proxy($url)->call($method,@args)->result);

	return $self;
}

1; 
