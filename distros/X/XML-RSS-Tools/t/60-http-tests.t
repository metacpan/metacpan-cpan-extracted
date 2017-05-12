#   $Id: 60-http-tests.t 69 2008-06-29 15:00:08Z adam $

use Test::More;
use strict;
use warnings;
use IO::Socket;
use Sys::Hostname;

my $test_warn;
BEGIN {

    eval ' require Test::NoWarnings; ';
    if ( $@ ) {
        plan( tests => 21 );
        undef $test_warn;
    }
    else {
        plan( tests => 22 );
        $test_warn = 1;
    }
    use_ok( 'XML::RSS::Tools' );
}

my $hostname = hostname;
my $r_host   = "www.iredale.net";
my $socket   = IO::Socket::INET->new(
    PeerAddr => "$r_host:80",
    Timeout  => 10
);

my $rss = XML::RSS::Tools->new;
ok( $rss,                          'We got an XML::RSS::Tools object' );

my $uri;
if ( $socket ) {
    close( $socket );
    $uri = "http://" . $r_host . "/";
}
elsif ( $socket = IO::Socket::INET->new(
    PeerAddr => "$hostname:80",
    Timeout  => 10 ) )
{
    close( $socket );
    $uri = "http://" . $hostname . "/";
}

SKIP: {
    skip 'Unable to locate a HTTP Server to test HTTP clients.', 12 unless $uri;

    SKIP : {
        eval { require HTTP::GHTTP };
        skip "HTTP::GHHTP isn't installed", 2 if $@;

        ok( $rss->set_http_client( 'ghttp' ),          'GHTTP client' );
        ok( $rss->xsl_uri( $uri ),                  'connection okay' );
    }

    SKIP: {
        eval { require HTTP::Lite };
        skip "HTTP::Lite isn't installed", 2 if $@;

        ok( $rss->set_http_client( 'lite' ),      'HTPP::Lite client' );
        ok( $rss->xsl_uri( $uri ),                  'connection okay' );
    }

    SKIP: {
        eval { require WWW::Curl::Easy };
        skip "WWW::Curl::Easy isn't installed", 2, if $@;

        ok( $rss->set_http_client( 'curl' ),         'libcurl client' );
        ok( $rss->xsl_uri( $uri ),                 'connection okay' );
    }

    SKIP: {
        eval { require LWP };
        skip "LWP isn't installed", 6 if $@;

        ok( $rss->set_http_client( 'lwp' ),              'LWP Client' );
        is( $rss->get_http_client, 'lwp',            'Correctly set?' );
        ok( $rss->xsl_uri( $uri ),                 'connection okay' );
        ok( $rss->{_http_client} = 'useragent',        'Force odd UA' );
        ok( $rss->xsl_uri( $uri ),          'connection still okay?' );
        ok( $rss = XML::RSS::Tools->new( http_client => 'lwp' ),
                                              'Reset with new client' );
    }

}

#   15-21
ok( !$rss->get_http_proxy,               'Check initial proxy status' );
ok( $rss->set_http_proxy( proxy_server => 'foo:3128' ),
                                                 'Set a proxy server' );
is( $rss->get_http_proxy, 'foo:3128',                'Is it correct?' );
ok( $rss->set_http_proxy(
        'proxy_server' => 'bar:3128',
        'proxy_user'   => 'me'),               'Set proxy second way' );
is( $rss->get_http_proxy, 'bar:3128',           'Check it is correct' );
ok( $rss->set_http_proxy(
        'proxy_server' => 'bar:3128',
        'proxy_user'   => 'me',
        'proxy_pass'   => 'secret'),             'Set proxy third way' );
is( $rss->get_http_proxy, 'me:secret@bar:3128',      'Is it correct?' );

if ( $test_warn ) { Test::NoWarnings::had_no_warnings(); }

exit;
