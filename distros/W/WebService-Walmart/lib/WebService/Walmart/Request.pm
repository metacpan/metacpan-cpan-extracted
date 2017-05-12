package WebService::Walmart::Request;
use strict;
use warnings;

use Moose::Role;
use HTTP::Tiny;
use WebService::Walmart::Exception;
use Data::Dumper;

$Webservice::Walmart::Request::VERSION = "0.01";

has apiurl   => ( is => 'rw', default => 'https://api.walmartlabs.com/v1');
has ua       => ( is => 'rw', default => sub { HTTP::Tiny->new(agent => "WebService-Walmart/$Webservice::Walmart::Request::VERSION"); },);
has api_key  => ( is => 'rw');
has output   => ( is => 'rw', default => 'json');
has debug    => ( is => 'rw', default => 0);


sub _get {
    my ($self, $path) = @_;
    my @caller = caller(1);
    
    my $full_url = $self->apiurl . "$path&format=".$self->output . "&apiKey=" . $self->api_key;
    print "DEBUG: full_url is $full_url\n" if $self->debug;
    
    my $response = $self->ua->request('GET', $full_url);
    
    # build us a an exception if the request was not successful
    # if we were called in an eval block, we need to go higher up the stack
    @caller = caller(2) if $caller[3] eq '(eval)';
    
    if ( $response->{success} != 1) {
        WebService::Walmart::Exception->throw({
            method      => $caller[3],
            message     => "HTTP Request to " . $self->apiurl . " failed",
            code        => $response->{status},
            reason      => $response->{reason},
            filename    => $caller[1],
            linenum     => $caller[2],
        });
    }
    
    print "Response from _get() ", Dumper $response if ($self->debug);
    return($response);
}

1;

=pod


=head1 SYNOPSIS

This module is responsible for the HTTPS requests to the Walmart API. It is a Moose Role and
cannot be instantiated.

You probably shouldn't be calling this directly

=cut