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

my $ID = 'd';

subtest 'plain' => sub {
    plan tests => 5;

    route_exists            [GET => "/$ID"], "route /$ID exists";
    response_status_is      [GET => "/$ID"], 200, 'HTTP OK';
    response_headers_include[GET => "/$ID"], ['X-Pastebin-ID' => $ID];
    response_headers_include[GET => "/$ID"], ['Content-Type' => 'text/plain'];
    response_content_like   [GET => "/$ID"], qr/\Q<omg>\E/, 'known paste content retrieved OK';
};

subtest 'html' => sub {
    plan tests => 7;

    route_exists            [GET => "/$ID+"], "route /$ID. exists";
    response_status_is      [GET => "/$ID+"], 200, 'HTTP OK';
    response_headers_include[GET => "/$ID+"], ['X-Pastebin-ID' => $ID];
    response_headers_include[GET => "/$ID+"], ['Content-Type' => 'text/html'];
    response_content_like   [GET => "/$ID+"], qr/\Qomg\E/, 'known paste content retrieved OK';
    response_content_unlike [GET => "/$ID+"], qr/\Q<omg>\E/, 'no <> in HTML content';
    response_content_like   [GET => "/$ID+"], qr/\Qid="l1"\E/, 'line numbers present';
};
