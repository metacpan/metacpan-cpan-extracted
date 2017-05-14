package YARN::YarnClient;

use strict;
use warnings;

## Create a new instance of YarnClient
sub createYarnClient {
	my ($self, $conf) = @_;
	
	return $self;
}

## This method is a proxy for REST::Client
sub connect {
	my $self = shift;
	
	$self = REST::Client->new();
	
	return $self;
}

## Returns the URL of the API (example: yarn.example.com:8088/ws/v1/cluster/info)
sub api_path {
    my ($self, $conf, $api) = @_;
    
    my $url = $conf->{host} . ":" . $conf->{port} . $conf->{endpoint} . "/" . $api;
    
    return $url;
}

1;