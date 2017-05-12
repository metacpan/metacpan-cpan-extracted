#!/usr/bin/perl -w

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict;
use Test::More tests => 3;
use WWW::Curl::Simple;

my $url = 'https://google.co.uk/robots.txt';
my $curl;
my $response;

{
    $curl     = WWW::Curl::Simple->new(
        check_ssl_certs => 1,
        ssl_cert_bundle => 't/certs',
    );
    eval { $response = $curl->get($url); };
    ok($@ && !defined($response));
}

{
    $curl     = WWW::Curl::Simple->new(check_ssl_certs => 0);
    eval { $response = $curl->get($url); };
    ok(!$@ && defined($response) && $response->code == 200);
}

{
    # default is 0 (i.e. don't check), so this should work too
    $curl     = WWW::Curl::Simple->new();
    $response = $curl->get($url);
    ok(!$@ && defined($response) && $response->code == 200);
}
