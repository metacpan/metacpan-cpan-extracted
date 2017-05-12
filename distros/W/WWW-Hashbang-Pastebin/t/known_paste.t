use strict;
use warnings;
use Test::More tests => 2;

# the order is important
use WWW::Hashbang::Pastebin;
use Dancer::Plugin::DBIC;
use Dancer::Test;

schema->deploy;
my $data = do 't/etc/schema.pl';
schema->populate(@{ $data->{fixture_sets}->{basic} });

subtest 'plain' => sub {
    plan tests => 5;

    route_exists            [GET => '/b'], 'route /b exists';
    response_status_is      [GET => '/b'], 200, 'HTTP OK';
    response_headers_include[GET => '/b'], ['X-Pastebin-ID' => 'b'];
    response_headers_include[GET => '/b'], ['Content-Type' => 'text/plain'];
    response_content_like   [GET => '/b'], qr/\Qtest1\E/, 'known paste content retrieved OK';
};

subtest 'html' => sub {
    plan tests => 8;

    route_exists            [GET => '/b+'], 'route /b. exists';
    response_status_is      [GET => '/b+'], 200, 'HTTP OK';
    response_headers_include[GET => '/b+'], ['X-Pastebin-ID' => 'b'];
    response_headers_include[GET => '/b+'], ['Content-Type' => 'text/html'];
    response_content_like   [GET => '/b+'], qr/\Qtest1\E/, 'known paste content retrieved OK';
    response_content_like   [GET => '/b+'], qr/\Qid="l1"\E/, 'line numbers present';
    response_content_like   [GET => '/b+'], qr/\Qid="l2"\E/, 'right number of lines';
    response_content_unlike [GET => '/b+'], qr/\Qid="l3"\E/, 'right number of lines';
};
