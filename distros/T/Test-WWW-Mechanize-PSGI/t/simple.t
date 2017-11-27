#!perl
use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::PSGI;

my $hello = Test::WWW::Mechanize::PSGI->new(
    app => sub {
        my $env = shift;
        return [ 200, [ 'Content-Type' => 'text/plain' ], ['Hello World'] ],;
    },
);
isa_ok( $hello, 'Test::WWW::Mechanize::PSGI' );

$hello->get_ok('/');
is( $hello->ct, 'text/plain', 'Is text/plain' );
$hello->content_contains('Hello World');

my $html = Test::WWW::Mechanize::PSGI->new(
    app => sub {
        my $env = shift;
        return [
            200,
            [ 'Content-Type' => 'text/html' ],
            [
                '<html><head><title>Hi</title></head><body>Hello World</body></html>'
            ]
        ];
    },
);
isa_ok( $html, 'Test::WWW::Mechanize::PSGI' );

$html->get_ok('/');
is( $html->ct, 'text/html', 'Is text/html' );
$html->title_is('Hi');
$html->content_contains('Hello World');

my $die = Test::WWW::Mechanize::PSGI->new(
    app => sub {
        my $env = shift;
        die "Throwing an exception from app handler. Server shouldn't crash.";
    },
);
isa_ok( $die, 'Test::WWW::Mechanize::PSGI' );

$die->get;

my $base      = 'https://metacpan.org/foo/bar';
my $base_href = Test::WWW::Mechanize::PSGI->new(
    app => sub {
        my $env = shift;
        return [
            200, [ 'Content-Type' => 'text/html' ],
            [
                qq[<html><head><base href="$base"><title>Hi</title></head><body>Hello World</body></html>]
            ]
        ];
    }
);

my $res = $base_href->get('/');
is( $base_href->base, $base );

done_testing();
