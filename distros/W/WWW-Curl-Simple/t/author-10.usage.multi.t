#!/usr/bin/perl -w

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict;
use Test::More;
use WWW::Curl::Simple;

my @urls = (
'http://en.wikipedia.org/wiki/Main_Page',
'http://www.yahoo.com',
'http://www.startsiden.no',
'http://www.abcnyheter.no',
'http://www.cnn.com',
'http://www.bbc.co.uk',
'http://www.vg.no',
'http://www.perl.org',
'http://www.perl.com',
);

plan tests => 11 + scalar(@urls) * 4;


{
    my $curl = WWW::Curl::Simple->new();

    $curl->add_request(HTTP::Request->new(GET => $_)) foreach (@urls);

    my @res = $curl->perform;

    foreach my $req (@res) {
        isa_ok($req, "WWW::Curl::Simple::Request");
        my $res = $req->response;
        isa_ok($res, "HTTP::Response");
        ok($res->is_success or $res->is_redirect, "we have success!  " . $res->code);

        isa_ok($res->request, "HTTP::Request");
    }

}
{
    my $curl = WWW::Curl::Simple->new();

    my $req = $curl->add_request(HTTP::Request->new(GET => 'http://en.wikipedia.org/wiki/Main_Page'));

    ok($curl->has_request($req), "We can check for existance of a request");

    isa_ok(
        $req,
        "WWW::Curl::Simple::Request", "We get the right index back from add_request",
    );
    isa_ok(
        $curl->add_request(HTTP::Request->new(GET => 'http://www.yahoo.com')),
        "WWW::Curl::Simple::Request", "We get the right index back from our second add_request",
    );

    my @res = $curl->perform;

    ok($curl->delete_request($req), "We can remove a request");
    is($curl->_count_requests, 1, "We have removed one request");
    foreach my $req (@res) {
        isa_ok($req, "WWW::Curl::Simple::Request");
        my $res = $req->response;

        isa_ok($res, "HTTP::Response");
        ok($res->is_success or $res->is_redirect, "we have success for " . $res->base . "!  " . $res->status_line);
    }
}
