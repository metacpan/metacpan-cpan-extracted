package WebService::Cryptopia;
# ABSTRACT: Interface to Cryptopia
use JSON::MaybeXS;
use LWP::UserAgent;
use Log::Log4perl;
use Digest::MD5;
use MIME::Base64;
use URL::Encode qw/url_encode/;
use Moose;
use MooseX::Params::Validate;
use Try::Tiny;
use Digest::SHA qw/hmac_sha256/;
use YAML;
BEGIN { Log::Log4perl->easy_init() };
our $VERSION = 0.018;

with "MooseX::Log::Log4perl";

=head1 NAME

WebService::Cryptopia


=head1 DESCRIPTION

Query the Cryptopia API

https://www.cryptopia.co.nz/Forum/Thread/255

=head1 ATTRIBUTES

=over 4

=item user_agent

Optional.  A new LWP::UserAgent will be created for you if you don't already have one you'd like to reuse.

=cut

has 'user_agent' => (
    is		=> 'ro',
    isa		=> 'LWP::UserAgent',
    required	=> 1,
    lazy	=> 1,
    builder	=> '_build_user_agent',
    );

=item api_key

Required for private api

=cut
has 'api_key' => (
    is		=> 'ro',
    isa		=> 'Str',
    );

=item api_secret

Required for private api

=cut
has 'api_secret' => (
    is		=> 'ro',
    isa		=> 'Str',
    );

=item base_url

Optional.  Default: https://www.cryptopia.co.nz/api/

=cut
has 'base_url' => (
    is		=> 'ro',
    isa		=> 'Str',
    required	=> 1,
    default     => 'https://www.cryptopia.co.nz/api/',
    );

sub _build_user_agent {
    my $self = shift;
    $self->log->debug( "Building useragent" );
    my $ua = LWP::UserAgent->new(
	keep_alive	=> 1
    );
    $ua->default_header('Accept' => 'application/json' );
    return $ua;
}

=back

=head1 METHODS

=over 4

=item api_public

Query the public API

=cut 


sub api_public {
    my ( $self, %params ) = validated_hash(
        \@_,
        method        => { isa    => 'Str' },
        parameters      => { isa    => 'ArrayRef', optional => 1 },
    );

    my $url = $self->base_url . $params{method} .
        ( $params{parameters} ? '/' . join( '/', @{ $params{parameters} } ) : '' );
    $self->log->debug( "Getting: $url" );
    my $response = $self->user_agent->get( $url );
    $self->log->trace( Dump( $response ) ) if $self->log->is_trace;
    
    if( ! $response->is_success ){
        $self->log->error( "Failed ($url) with status: " . $response->status_line );
        $self->log->logdie( "Response:\n" . $response->decoded_content );
    }
    my $data = decode_json( $response->decoded_content );
    if( not $data->{Success} ){
        $self->log->logdie( $data->{Error} );
    }
    return $data->{Data};
}

sub api_private {
    my ( $self, %params ) = validated_hash(
        \@_,
        method  => { isa    => 'Str' },
        parameters    => { isa    => 'HashRef', optional => 1 },
        nonce   => { isa    => 'Int', optional => 1 },
    );
    $params{parameters} = {}  if( not $params{parameters} );
    if( not $self->api_key or not $self->api_secret ){
        $self->log->logdie( "Cannot use api_private without api_key and api_secret" );
    }
    my $url = $self->base_url . $params{method};
    $self->log->trace( "Url: $url" ) if $self->log->is_trace;
    my $nonce = $params{nonce} || time();
    $self->log->trace( "nonce: $nonce" ) if $self->log->is_trace;
    my $post_data = encode_json( $params{parameters} );
    $self->log->trace( "Post data: $post_data" ) if $self->log->is_trace;
    my $ctx = Digest::MD5->new();
    $ctx->add( $post_data );
    my $request_content_base64_string = encode_base64( $ctx->digest );
    $self->log->trace( "Request_content_base64: $request_content_base64_string" ) if $self->log->is_trace;
    my $signature = $self->api_key . "POST" . lc( url_encode( $url ) ) . $nonce . $request_content_base64_string;
    chomp( $signature );
    $self->log->trace( "Signature: $signature" ) if $self->log->is_trace;
    my $hmac_signature = encode_base64( hmac_sha256( $signature, decode_base64( $self->api_secret ) ) );
    chomp( $hmac_signature );
    $self->log->trace( "HMAC signature: $hmac_signature" ) if $self->log->is_trace;
    my $header_value = "amx " . $self->api_key . ':' . $hmac_signature . ':' . $nonce;
    $self->log->trace( "Authorization: $header_value" ) if $self->log->is_trace;
    my $request = HTTP::Request->new( 'POST' => $url );
    $request->header( 'Authorization', $header_value );
    $request->header( 'Content-Type', 'application/json; charset=utf-8' );
    $request->content( $post_data );
    $self->log->trace( "HTTP::Request: \n" . Dump( $request ) );
    my $response = $self->user_agent->request( $request );
    $self->log->trace( "Response-content: " . $response->decoded_content ) if $self->log->is_trace;
    my $data = decode_json( $response->decoded_content );
    if( not $data->{Success} ){
        $self->log->logdie( $data->{Error} );
    }
    return $data->{Data};
}


1;


=back 

=head1 COPYRIGHT

Copyright 2018, Robin Clarke, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>

