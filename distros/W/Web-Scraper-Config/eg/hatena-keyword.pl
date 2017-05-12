#!/usr/bin/perl
use strict;
use warnings;
use Web::Scraper::Config;
use YAML;

# same as http://d.hatena.ne.jp/secondlife/20060922/1158923779

my $s = Web::Scraper::Config->new('eg/hatena-keyword.yml');
my $res = $s->scrape(URI->new("http://d.hatena.ne.jp/keyword/%BA%B0%CC%EE%A4%A2%A4%B5%C8%FE"));

warn Dump $res;
