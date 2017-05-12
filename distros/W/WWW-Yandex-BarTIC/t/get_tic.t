#!/usr/bin/env perl

use Test::More tests => 12;

use strict;
use warnings;

use LWP::UserAgent;
use URI::Escape;

use WWW::Yandex::BarTIC 'get_tic';

#$ENV{TEST_URL}='http://mail.ru';

DEFAULTS: {
  my $yb = WWW::Yandex::BarTIC->new();
  isa_ok $yb, 'WWW::Yandex::BarTIC';
  isa_ok $yb, 'Object::Accessor';
  isa_ok $yb->ua, 'LWP::UserAgent';

  is $yb->ua->agent,
    'Mozilla/5.0 (Ubuntu; X11; Linux i686; rv:9.0.1) Gecko/20100101 Firefox/9.0.1 YB/6.5.0-en';

  $yb->ua->agent('hoho');
  is $yb->ua->agent, 'hoho';
  is(
    sprintf($yb->url_template, uri_escape('http://cpan.org')),
    'http://bar-navig.yandex.ru/u?url=http%3A%2F%2Fcpan.org&show=1'
  );
  
  {
    local $SIG{__WARN__} = sub {};
    is $yb->get('wrong_url'), undef;
  }
  
}


SKIP: {
  my $url = $ENV{TEST_URL};

  unless ($url) {
    skip('Define "TEST_URL" ENV to test a real query (http://cpan.org). TIC for url must be greater than 0', 5);
  }
  
  UA: {
    my $yb = WWW::Yandex::BarTIC->new(ua => LWP::UserAgent->new());
    my ($tic, $resp) = $yb->get($url);
    ok $tic > 0, 'tic works!';
  }
  OBJECT: {
    my $yb = WWW::Yandex::BarTIC->new();
    my ($tic, $resp) = $yb->get($url);
    ok $tic > 0, 'tic works!';
    isa_ok $resp, 'HTTP::Response';
  }
  
  FUNC: {
    my ($tic, $resp) = get_tic($url);
    ok $tic > 0, 'get_tic works!';
    isa_ok $resp, 'HTTP::Response';
  }
  
  
}


