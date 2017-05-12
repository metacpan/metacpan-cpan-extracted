use strict;
use warnings;
use MRO::Compat 'c3';

package WebService::Shippo::Resource;
require WebService::Shippo::Request;
use URI::Encode ( 'uri_encode' );
use MIME::Base64;
use base ( 'WebService::Shippo::Object' );
use constant DEFAULT_API_SCHEME  => 'https';
use constant DEFAULT_API_HOST    => 'api.goshippo.com';
use constant DEFAULT_API_PORT    => '443';
use constant DEFAULT_API_VERSION => 'v1';

{
    my $value = undef;

    sub api_private_token
    {
        my ( $class, $new_value ) = @_;
        return $value unless @_ > 1;
        $value = $new_value;
        return $class;
    }
}

{
    my $value = undef;

    sub api_public_token
    {
        my ( $class, $new_value ) = @_;
        return $value unless @_ > 1;
        $value = $new_value;
        return $class;
    }
}

{
    my $value = undef;

    sub api_key
    {
        my ( $class, $new_value ) = @_;
        return $value unless @_ > 1;
        $value = $new_value;
        Shippo::Request->headers->{Authorization} = "ShippoToken $value"
            if $value;
        return $class;
    }
}

{
    my @value = ();

    sub api_credentials
    {
        my ( $class, $user, $pass ) = @_;
        return @value unless @_ > 1;
        @value = ( $user, $pass );
        if ( @value ) {
            my $header = 'Basic ' . encode_base64( join ':', @value );
            Shippo::Request->headers->{Authorization} = $header;
        }
        return $class;
    }
}

sub api_scheme { DEFAULT_API_SCHEME }

sub api_host { DEFAULT_API_HOST }

sub api_port { DEFAULT_API_PORT }

sub api_base_path { DEFAULT_API_VERSION }

sub api_endpoint
{
    my $scheme = api_scheme();
    my $port   = api_port();
    my $path   = api_base_path;
    my $value  = $scheme . '://' . api_host();
    $value .= ':' . $port
        unless $port && $port eq '443' && $scheme eq 'https';
    $value .= '/';
    $value .= $path . '/'
        if $path;
    return $value;
}

sub url
{
    my ( $class, $id ) = @_;
    my $resource = $class->api_resource;
    my $url      = $class->api_endpoint;
    $url .= $resource . '/'
        if $resource;
    $url .= uri_encode( $id ) . '/'
        if @_ > 1 && $id;
    return $url;
}

sub id
{
    my ( $invocant ) = @_;
    return '' unless defined $invocant->{object_id};
    return $invocant->{object_id};
}

sub is_valid
{
    my ( $invocant ) = @_;
    return '' unless defined $invocant->{object_state};
    return $invocant->{object_state} && $invocant->{object_state} eq 'VALID';
}

BEGIN {
    no warnings 'once';
    # Forcing the dev to always use CPAN's perferred "WebService::Shippo"
    # namespace is just cruel; allow the use of "Shippo", too.
    *Shippo::Resource:: = *WebService::Shippo::Resource::;
    # Other aliases
    *class_url    = *url;
    *api_protocol = *api_scheme;
}

1;
