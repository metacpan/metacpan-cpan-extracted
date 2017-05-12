#!/usr/bin/perl
use strict;
use warnings;
use Web::Scraper::Config;
use YAML;

my $s = Web::Scraper::Config->new(
    'eg/dave-trailer-HD.yml',
    {
        callbacks => {
            process_movie => sub {
                my $elem = shift;
                return {
                    text => $elem->as_text,
                    href => $elem->attr('href'),
                };
            }
        }
    }
);

my $uri  = URI->new("http://www.drfoster.f2s.com/");
warn Dump $s->scrape($uri);
