#!/usr/bin/perl
use strict;
use warnings;
use Web::Scraper::Config;
use YAML;

my $s = Web::Scraper::Config->new( 'eg/ebay-auction.yml' );
my $auctions = $s->scrape( URI->new("http://search.ebay.com/apple-ipod-nano_W0QQssPageNameZWLRS") );

warn Dump $auctions;

