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

my $url = 'http://httpstat.us/302';
my $curl;
my $response;

{
    $curl     = WWW::Curl::Simple->new(max_redirects => 0);
    $response = $curl->get($url);
    ok($response->code == 302);
}

# be nice to httpstat.us
sleep(1);

{
    $curl     = WWW::Curl::Simple->new(max_redirects => 1);
    $response = $curl->get($url);
    ok($response->code == 200);
}

# be nice to httpstat.us
sleep(1);

{
    # default is 5 redirects, so this should work too
    $curl     = WWW::Curl::Simple->new();
    $response = $curl->get($url);
    ok($response->code == 200);
}
