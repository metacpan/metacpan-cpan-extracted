package Zonemaster::GUI::Dancer::Client;
our $VERSION = '1.0.7';

use strict;
use warnings;
use utf8;
use 5.10.1;

use LWP::UserAgent;
use JSON;
use Time::HiRes qw(gettimeofday);

our $AUTOLOAD;

sub new {
    my ( $type, $params ) = @_;

    my $self = $params;
    bless( $self, $type );

    $self->{lwp} = LWP::UserAgent->new;

    return ( $self );
}

sub AUTOLOAD {
    my $self = shift;

    my $program = $AUTOLOAD;
    $program =~ s/.*:://;

    my ( $s, $usec ) = gettimeofday();
    my $id = $s * 100000 + $usec;

    my ( $method ) = ( $AUTOLOAD =~ /::([^:]+)$/ );
    my $json = encode_json( { "jsonrpc" => "2.0", "method" => $method, "params" => @_, "id" => $id } );

    my $req = HTTP::Request->new( 'POST', $self->{url} );
    $req->header( 'Content-Type' => 'application/json' );
    $req->content( $json );

    my $response = $self->{lwp}->request( $req );

    die "Package:" . __PACKAGE__ . " / Line:" . __LINE__ . " / LWP Error: ", $response->status_line
      unless $response->is_success;

    my $json_rpc_response = decode_json( $response->content() );

    die "Package:"
      . __PACKAGE__
      . " / Line:"
      . __LINE__
      . " / JSON::RPC Eror: "
      . $json_rpc_response->{error}->{message}
      if $json_rpc_response->{error};

    return ( $json_rpc_response->{result} );
}

sub DESTROY {
}

1;
