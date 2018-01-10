package WebService::Cryptopia;
# ABSTRACT: Interface to Cryptopia
use JSON::MaybeXS;
use LWP::UserAgent;
use Log::Log4perl;
use Moose;
use MooseX::Params::Validate;
use Try::Tiny;
use YAML;
BEGIN { Log::Log4perl->easy_init() };
our $VERSION = 0.016;

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
        function        => { isa    => 'Str' },
        parameters      => { isa    => 'Array', optional => 1 },
    );

    my $url = $self->base_url . $params{function} .
        ( $params{parameters} ? join( '/', @{ $params{paramters} } ) : '' );
    $self->log->debug( "Getting: $url" );
    my $response = $self->user_agent->get( $url );
    $self->log->trace( Dump( $response ) ) if $self->log->is_trace;

    return decode_json( $response->decoded_content );
}



1;


=back 

=head1 COPYRIGHT

Copyright 2018, Robin Clarke, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>

