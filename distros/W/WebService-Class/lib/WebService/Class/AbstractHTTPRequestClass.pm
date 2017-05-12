package WebService::Class::AbstractHTTPRequestClass;
use warnings;
use strict;
use base qw(WebService::Class::AbstractClass);
use WebService::RequestAPI::HTTPRequestAPI;

sub init{
	my $self = shift;
	$self->SUPER::init(@_);
	$self->request_api(new WebService::RequestAPI::HTTPRequestAPI(@_));
}


1; 
