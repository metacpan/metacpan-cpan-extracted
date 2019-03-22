#!perl
use strict;
use warnings;
use Test::More tests => 4;
use Test::WWW::Mechanize::PSGI;
use CGI::Cookie;

my $hello = Test::WWW::Mechanize::PSGI->new(
    app => do {
        my $cookie_store = {};
        my $sid          = 123456;
        sub {
            my $env     = shift;
            my %cookies = CGI::Cookie->parse( $env->{HTTP_COOKIE} || '' );
            if ( my $cookie = $cookies{sid} ) {
                my $content = $cookie_store->{ $cookies{sid}->value };
                return [
                    200, [ 'Set-Cookie' => "sid=$sid; path=/" ],
                    [$content]
                    ],
                    ;
            }
            else {
                $cookie_store->{$sid} = "OK";
                return [
                    200, [ 'Set-Cookie' => "sid=$sid; path=/" ],
                    ['Hello World']
                    ],
                    ;
            }
        }
    },
);
$hello->get_ok('/');
$hello->content_is('Hello World');
$hello->get_ok('/');
$hello->content_is('OK');

