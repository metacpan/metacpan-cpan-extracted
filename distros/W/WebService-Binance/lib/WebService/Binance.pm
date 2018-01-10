package WebService::Binance;
# ABSTRACT: Interface to Binance
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

Query the Binance API

https://www.binance.com/restapipub.html

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

Optional.  The base URL at binance.  I don't see any likely reason to overwrite this...

=cut

has 'base_url' => (
    is		=> 'ro',
    isa		=> 'Str',
    required	=> 1,
    default     => 'https://api.binance.com',
    );


=item api_version

Optional.  Default: 1

=cut

has 'api_version' => (
    is		=> 'ro',
    isa		=> 'Str',
    required	=> 1,
    default     => '1',
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

    my $url = $self->base_url . '/api/v' . $self->api_version . '/' . $params{function};
    if( $params{parameters} ){
        $self->log->error( "parameters passed, but not implemented yet" );
    }

    $self->log->debug( "Getting: $url" );
    my $response = $self->user_agent->get( $url );
    $self->log->trace( Dump( $response ) ) if $self->log->is_trace;

    return decode_json( $response->decoded_content );
}


=item lookup_symbol

Binance works with symbols which represent the exchange rate between a pair of currencies.
e.g. BTCETH represents exchnage rate from Bitcoin (BTC) -> Etherium (ETH).
This method does a best-guess at what the two currencies are from a given symbol.
Usage:

    my( $from, $to ) = $binance->lookup_symbol( 'BTCETH' );

=cut

sub lookup_symbol {
    my $self = shift;
    my $symbol = shift;

    my $from = undef;
    my $to = undef;
    if( length( $symbol ) == 6 ){
        $from = substr( $symbol, 0, 3 );
        $to = substr( $symbol, 3, 3 );
    }elsif( $symbol =~ m/^(USDT|BNB|BTC|ETH)(.*)$/ ){
        $from = $1;
        $to = $2;
    }elsif( $symbol =~ m/^(.*)(USDT|BNB|BTC|ETH)$/ ){
        $from = $1;
        $to = $2;
    }
    return $from, $to;
}



1;


=back 

=head1 COPYRIGHT

Copyright 2018, Robin Clarke, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>

