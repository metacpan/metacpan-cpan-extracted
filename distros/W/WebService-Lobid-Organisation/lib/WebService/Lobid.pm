package WebService::Lobid;
$WebService::Lobid::VERSION = '0.00421';
use strict;
use warnings;

use HTTP::Tiny;
use Moo;

has api_url => ( is => 'rw', default=> 'https://lobid.org/');
has api_status => (is => 'rw');
has use_ssl => ( is => 'rw' );

sub BUILD {
    my $self     = shift;
    my $api_url  = $self->api_url;
    my $response = undef;

    if ( HTTP::Tiny->can_ssl() ) {
        $self->use_ssl("true");
    }
    else {
        $api_url =~ s/https/http/;
        $self->api_url($api_url);
        $self->use_ssl("false");
    }

    $response = HTTP::Tiny->new->get( $self->api_url );

    if ( $response->{success} ) {
        $self->api_status("ok");
    }
    else {
        $self->api_status("error");
        warn sprintf( "API URL %s is not reachable: %s (%s)",
                      $self->api_url, $response->{reason},
                      $response->{status} );
    }
} ## end sub BUILD

1;
