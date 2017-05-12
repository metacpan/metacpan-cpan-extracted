#!/usr/bin/perl -T

use Test::More qw/no_plan/;
use WWW::Search::Scrape::Bing;

BEGIN
{
    ok(WWW::Search::Scrape::Bing::search('bing', 10));

    my $res = WWW::Search::Scrape::Bing::search('google', 10);
    ok($res->{num} != 0);
}
