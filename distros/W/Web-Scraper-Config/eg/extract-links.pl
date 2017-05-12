#!/usr/bin/perl
use strict;
use warnings;
use Web::Scraper::Config;
use YAML;

my $uri = shift @ARGV or die "URI needed";

my $s = Web::Scraper::Config->new('eg/extract-links.yml');

my $links = $s->scrape(URI->new($uri));
warn Dump $links;

