#!perl
use v5.24;
use strictures 2;

use Test2::V1               qw( is isnt ok like done_testing );
use Test2::Tools::Exception qw( dies lives );
use Test::LWP::UserAgent;

# Set VERSION before loading the main module so BUILD does not warn
BEGIN { $WebService::OPNsense::VERSION = '0.001' }
use WebService::OPNsense;

# --- _uri_authority ---

{
    my $auth = WebService::OPNsense->_uri_authority('https://opnsense.example.com:8443');
    is( $auth, 'opnsense.example.com:8443', 'authority with port' );
}

{
    my $auth = WebService::OPNsense->_uri_authority('https://192.0.2.1');
    is( $auth, '192.0.2.1', 'authority without port' );
}

{
    my $auth = WebService::OPNsense->_uri_authority('http://localhost/api/v1');
    is( $auth, 'localhost', 'authority with path' );
}

{
    my $auth = WebService::OPNsense->_uri_authority('http://[::1]:8080/path');
    is( $auth, '[::1]:8080', 'authority IPv6 with port' );
}

# _uri_authority croaks on unparseable URLs
{
    ok(
        dies { WebService::OPNsense->_uri_authority('not-a-url') },
        'unparseable URL dies'
    );
}

{
    ok(
        dies { WebService::OPNsense->_uri_authority('') },
        'empty URL dies'
    );
}

{
    ok(
        dies { WebService::OPNsense->_uri_authority('http://') },
        'scheme-only URL dies'
    );
}

# --- BUILD: trailing-slash strip ---

{
    my $ua  = Test::LWP::UserAgent->new;
    my $opn = WebService::OPNsense->new(
        base_url => 'https://opnsense.example.com/',
        username => 'key',
        password => 'secret',
        ua       => $ua,
    );
    is(
        $opn->base_url, 'https://opnsense.example.com',
        'trailing slash stripped'
    );
}

{
    my $ua  = Test::LWP::UserAgent->new;
    my $opn = WebService::OPNsense->new(
        base_url => 'https://opnsense.example.com',
        username => 'key',
        password => 'secret',
        ua       => $ua,
    );
    is(
        $opn->base_url, 'https://opnsense.example.com',
        'no trailing slash unchanged'
    );
}

{
    my $ua  = Test::LWP::UserAgent->new;
    my $opn = WebService::OPNsense->new(
        base_url => 'https://opnsense.example.com///',
        username => 'key',
        password => 'secret',
        ua       => $ua,
    );
    is(
        $opn->base_url, 'https://opnsense.example.com',
        'multiple trailing slashes stripped'
    );
}

# --- BUILD: credentials ---

{
    my $ua  = Test::LWP::UserAgent->new;
    my $opn = WebService::OPNsense->new(
        base_url => 'https://opnsense.example.com',
        username => 'api_key',
        password => 'api_secret',
        ua       => $ua,
    );
    my $creds = $ua->credentials('opnsense.example.com');
    is( $creds, 'api_key:api_secret', 'credentials set on UA' );
}

# --- BUILD: User-Agent header ---

{
    my $ua  = Test::LWP::UserAgent->new;
    my $opn = WebService::OPNsense->new(
        base_url => 'https://opnsense.example.com',
        username => 'key',
        password => 'secret',
        ua       => $ua,
    );
    my $ua_header = $ua->default_header('User-Agent');
    ok( defined $ua_header, 'User-Agent default header set' );
    like(
        $ua_header, qr/^WebService::OPNsense /,
        'User-Agent starts with module name'
    );
    like(
        $ua_header, qr/perl v[\d.]+/,
        'User-Agent contains perl version'
    );
}

done_testing;
