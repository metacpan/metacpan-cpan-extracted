#!/usr/bin/perl
use strict;
use warnings;
use YAML;
use Web::Scraper::Config;

my $nick = shift || "lestrrat";
my $uri  = URI->new("http://twitter.com/$nick");

my $s = Web::Scraper::Config->new('eg/twitter-friends.yml');
my $friends = $s->scrape($uri);

warn Dump $friends;

